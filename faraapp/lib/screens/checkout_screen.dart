import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../constants/colors.dart';
import 'order_tracking_screen.dart';
import '../services/api_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);
  static const Color darkOrange = Color(0xFFE85A1A);

  // 0 = choose type, 1 = takeaway detail, 2 = payment
  int _step = 0;
  String? _selectedType; // 'takeaway' | 'delivery'
  String _selectedPayment = 'upi';
  final _upiController = TextEditingController();
  bool _placing = false;
  late Razorpay _razorpay;

  // New state for actual payment
  Timer? _pollTimer;
  String? _currentRazorpayOrderId;
  String? _upiLink;

  // Customer info (fetched from profile)
  String _customerName = '';

  @override
  void initState() {
    super.initState();
    _loadCustomerName();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment successful! Now finalize the order.
    // We already have the cart from the provider.
    final cart = Provider.of<CartProvider>(context, listen: false);
    _finalizeOrder(cart, response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _placing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }


  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    _upiController.dispose();
    _stopPolling();
    _razorpay.clear();
    super.dispose();
  }

  void _startPolling(CartProvider cart) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_currentRazorpayOrderId == null) return;
      try {
        final status = await ApiService.checkRazorpayStatus(_currentRazorpayOrderId!);
        if (status['isPaid'] == true) {
          _stopPolling();
          // Payment detected! Finalize order.
          final fakeResponse = PaymentSuccessResponse(
            null, // paymentId
            _currentRazorpayOrderId,
            "polling_verified",
            null // externalWallet (missing argument)
          );
          _finalizeOrder(cart, fakeResponse);
        }
      } catch (e) {
        print("Polling error: $e");
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadCustomerName() async {
    try {
      final isAuthenticated = await ApiService.isAuthenticated();
      if (!isAuthenticated) return;
      
      final profile = await ApiService.getProfile();
      if (mounted) {
        setState(() => _customerName = profile['name'] as String? ?? '');
      }
    } catch (_) {}
  }

  // ── Generate pickup code ───────────────────────────────────────────────────
  String _generatePickupCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Open Swiggy ────────────────────────────────────────────────────────────
  Future<void> _openSwiggy() async {
    // Try to open Swiggy app, fallback to website
    final appUri = Uri.parse('swiggy://');
    final webUri = Uri.parse('https://www.swiggy.com');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Open Zomato ────────────────────────────────────────────────────────────
  Future<void> _openZomato() async {
    final appUri = Uri.parse('zomato://');
    final webUri = Uri.parse('https://www.zomato.com');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Place takeaway order ───────────────────────────────────────────────────
  Future<void> _placeOrder(CartProvider cart) async {
    if (cart.selectedOutlet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a stall first on the Home screen")),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      final total = cart.totalPrice.toDouble();
      final half = total / 2;

      // 1. Create Razorpay Order on Backend
      final rzpOrder = await ApiService.createRazorpayOrder(half);
      _currentRazorpayOrderId = rzpOrder['id'];
      _upiLink = rzpOrder['upi_link'];

      if (_selectedPayment == 'upi') {
        // For UPI/QR, we show the QR and start polling
        _startPolling(cart);
        setState(() => _placing = false);
        // UI will update to show QR because _upiLink is now set
      } else if (_selectedPayment == 'cod') {
        // Pay at counter is same as bypassing for now
        _finalizeOrder(cart, null);
      } else {
        // Standard Razorpay Modal
        _openRazorpayCheckout(half, rzpOrder['id']);
      }
    } catch (e) {
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment setup failed: $e")),
      );
    }
  }

  void _openRazorpayCheckout(double amount, String orderId) {
    var options = {
      'key': 'rzp_test_SdUUaBHHJt6vAj', // Ideally fetch from backend
      'amount': (amount * 100).toInt(),
      'name': 'FARA Food',
      'description': 'Advance Payment (50%)',
      'order_id': orderId,
      'timeout': 300,
      'prefill': {
        'name': _customerName,
        'contact': '',
        'email': ''
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }



  Future<void> _finalizeOrder(CartProvider cart, PaymentSuccessResponse? rzpResponse) async {
    setState(() => _placing = true);
    try {
      final total = cart.grandTotal.toDouble();
      final half = double.parse((total / 2).toStringAsFixed(2));
      final pickupCode = _generatePickupCode();

      final items = cart.items.map((i) => {
        'name': i.name,
        'qty': i.quantity,
        'price': i.price,
      }).toList();

      final location = cart.customerLocation ?? 'Customer Location'; 

      // Verify payment on backend if it was online
      if (rzpResponse != null) {
        final isManualUPI = rzpResponse.paymentId != null && rzpResponse.paymentId!.startsWith("upi_manual_");
        
        if (!isManualUPI) {
          await ApiService.verifyRazorpayPayment({
            'razorpay_order_id': rzpResponse.orderId,
            'razorpay_payment_id': rzpResponse.paymentId,
            'razorpay_signature': rzpResponse.signature,
            'verified_by_polling': rzpResponse.signature == "polling_verified",
          });
        }
      }

      final result = await ApiService.placeOrder({
        'customer_name': _customerName.isNotEmpty ? _customerName : 'Customer',
        'location': location,
        'stall_name': cart.selectedOutlet!['name'],
        'items': items,
        'total': total,
        'order_type': _selectedType ?? 'takeaway',
        'pickup_code': pickupCode,
        'payment_1': half,
        'payment_2': half,
        'payment_1_at': DateTime.now().toIso8601String(),
        'razorpay_payment_id': rzpResponse?.paymentId,
        'applied_coupon': cart.appliedCouponCode,
        'discount_amount': cart.couponDiscount,
      });

      final orderData = result['data'] ?? result['order'] ?? result;
      final orderId = orderData['_id'] ?? orderData['id'] ?? 'unknown';

      cart.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: orderId,
              pickupCode: pickupCode,
              total: total,
              halfPaid: half,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to finalize order: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A1A), size: 18),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 0
              ? "How would you like it?"
              : _step == 1
              ? "Takeaway Summary"
              : "Confirm Payment",
          style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _step == 0
            ? _buildDeliveryChoice(cart)
            : _step == 1
            ? _buildTakeawaySummary(cart)
            : _buildPaymentStep(cart),
      ),
    );
  }

  // ── STEP 0: Choose Home Delivery or Takeaway ───────────────────────────────
  Widget _buildDeliveryChoice(CartProvider cart) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart summary pill
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: primaryOrange, size: 18),
                const SizedBox(width: 8),
                Text(
                  "${cart.totalItems} item${cart.totalItems == 1 ? '' : 's'} • ₹${cart.totalPrice.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: primaryOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            "Choose Delivery Type",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          Text(
            "How do you want to receive your order?",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),

          const SizedBox(height: 28),

          // ── TAKEAWAY Card ──────────────────────────────────────────────────
          _DeliveryTypeCard(
            icon: Icons.storefront_rounded,
            title: "Takeaway",
            subtitle: "Pick up from the stall yourself",
            badge: "Pay 50% now, rest at pickup",
            badgeColor: Colors.green,
            highlights: const [
              "No delivery charges",
              "Ready in 10–20 mins",
              "Get a pickup code",
              "Pay remaining at counter",
            ],
            onTap: () => setState(() {
              _selectedType = 'takeaway';
              _step = 1;
            }),
          ),

          const SizedBox(height: 16),

          // ── HOME DELIVERY Card ─────────────────────────────────────────────
          _DeliveryTypeCard(
            icon: Icons.delivery_dining_rounded,
            title: "Home Delivery",
            subtitle: "Order via Swiggy or Zomato",
            badge: "Redirects to delivery app",
            badgeColor: Colors.blue,
            highlights: const [
              "Delivered to your door",
              "Real-time tracking",
              "Use your delivery app",
              "Swiggy or Zomato",
            ],
            onTap: () => setState(() {
              _selectedType = 'delivery';
              _showDeliveryAppSheet();
            }),
          ),
        ],
      ),
    );
  }

  // ── Delivery App Bottom Sheet ──────────────────────────────────────────────
  void _showDeliveryAppSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Open delivery app",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "We'll redirect you to the app to complete your order",
              textAlign: TextAlign.center,
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 28),

            // Swiggy button
            _AppLaunchButton(
              color: const Color(0xFFFC8019),
              icon: Icons.fastfood_rounded,
              label: "Open Swiggy",
              onTap: () {
                Navigator.pop(context);
                _openSwiggy();
              },
            ),
            const SizedBox(height: 14),

            // Zomato button
            _AppLaunchButton(
              color: const Color(0xFFE23744),
              icon: Icons.restaurant_rounded,
              label: "Open Zomato",
              onTap: () {
                Navigator.pop(context);
                _openZomato();
              },
            ),
            const SizedBox(height: 20),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 1: Takeaway Summary ───────────────────────────────────────────────
  Widget _buildTakeawaySummary(CartProvider cart) {
    final total = cart.totalPrice.toDouble();
    final half = total / 2;

    return Column(
      key: const ValueKey(1),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.green.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Pay 50% now to confirm your order. Pay the rest when you pick it up at the stall.",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Order Items Card
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          icon: Icons.shopping_bag_outlined,
                          label: "Your Order"),
                      const SizedBox(height: 14),
                      ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: lightOrange,
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "${item.quantity}×",
                                  style: const TextStyle(
                                      color: primaryOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text(
                              "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Payment Breakdown Card
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          icon: Icons.receipt_outlined,
                          label: "Payment Breakdown"),
                      const SizedBox(height: 14),
                      _BillRow(
                          label: "Subtotal",
                          value: "₹${cart.totalPrice.toStringAsFixed(0)}"),
                      if (cart.couponDiscount > 0)
                        _BillRow(
                          label: "Discount",
                          value: "-₹${cart.couponDiscount.toStringAsFixed(0)}",
                          valueColor: Colors.green,
                        ),
                      const Divider(height: 20),
                      _BillRow(
                        label: "Pay Now (50% advance)",
                        value: "₹${half.toStringAsFixed(0)}",
                        highlight: true,
                        icon: Icons.flash_on_rounded,
                      ),
                      const SizedBox(height: 6),
                      _BillRow(
                        label: "Pay at Pickup (50%)",
                        value: "₹${half.toStringAsFixed(0)}",
                        greyOut: true,
                        icon: Icons.storefront_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Pickup info card
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          icon: Icons.qr_code_rounded,
                          label: "How Pickup Works"),
                      const SizedBox(height: 14),
                      _StepRow(
                          step: "1",
                          text: "Pay 50% now to confirm order"),
                      _StepRow(
                          step: "2",
                          text: "Worker accepts & gives ready time"),
                      _StepRow(
                          step: "3",
                          text:
                          "You receive a 4-digit pickup code"),
                      _StepRow(
                          step: "4",
                          text:
                          "Show code at stall & pay remaining"),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Bottom bar
        _BottomBar(
          label:
          "Pay ₹${half.toStringAsFixed(0)} to Confirm",
          sublabel: "Advance payment (50%)",
          onTap: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  // ── STEP 2: Payment ────────────────────────────────────────────────────────
  Widget _buildPaymentStep(CartProvider cart) {
    final total = cart.grandTotal.toDouble();
    final half = total / 2;

    return Column(
      key: const ValueKey(2),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Payment methods
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          icon: Icons.payment_rounded,
                          label: "Pay ₹${half.toStringAsFixed(0)} Now"),
                      const SizedBox(height: 4),
                      Text(
                        "Advance to confirm your takeaway order",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      _PaymentOption(
                        value: "upi",
                        selected: _selectedPayment,
                        icon: Icons.qr_code_rounded,
                        label: "UPI / QR Code",
                        subtitle: "GPay, PhonePe, Paytm",
                        onTap: (v) => setState(() => _selectedPayment = v),
                      ),
                    ],
                  ),
                ),

                if (_selectedPayment == 'upi') ...[
                  const SizedBox(height: 14),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                            icon: Icons.qr_code_2_rounded,
                            label: "UPI Details"),
                        const SizedBox(height: 14),
                        // Real UPI QR
                        Center(
                          child: _upiLink == null
                              ? Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: lightOrange,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Click 'Place Order' \nto generate QR",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: primaryOrange, fontSize: 12),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                          )
                                        ],
                                      ),
                                      child: Image.network(
                                        'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(_upiLink!)}',
                                        width: 180,
                                        height: 180,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return const SizedBox(
                                            width: 180,
                                            height: 180,
                                            child: Center(child: CircularProgressIndicator(color: primaryOrange)),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrange),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Waiting for payment...",
                                          style: TextStyle(fontSize: 12, color: primaryOrange, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Manual Confirmation Button
                                    SizedBox(
                                      width: 200,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _stopPolling();
                                          final fakeResponse = PaymentSuccessResponse(
                                            "upi_manual_${DateTime.now().millisecondsSinceEpoch}",
                                            _currentRazorpayOrderId,
                                            "polling_verified",
                                            null
                                          );
                                          _finalizeOrder(cart, fakeResponse);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0,
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 18),
                                            SizedBox(width: 8),
                                            Text("I have Paid", style: TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _upiController,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "Or enter UPI ID (name@upi)",
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13),
                            prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: Colors.grey.shade400,
                                size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8F8F8),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryOrange, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        _BottomBar(
          label: "Confirm & Place Order",
          sublabel: "Your order will be sent to the stall immediately",
          loading: _placing,
          onTap: () => _placeOrder(cart),
        ),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Reusable Widgets ─────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<String> highlights;
  final VoidCallback onTap;

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  const _DeliveryTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.highlights,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                      color: lightOrange, shape: BoxShape.circle),
                  child: Icon(icon, color: primaryOrange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: primaryOrange, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
            const SizedBox(height: 14),
            ...highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: primaryOrange, size: 15),
                  const SizedBox(width: 8),
                  Text(h,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _AppLaunchButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppLaunchButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  static const Color primaryOrange = Color(0xFFFF6B2C);

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryOrange, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool greyOut;
  final Color? valueColor;
  final IconData? icon;
  static const Color primaryOrange = Color(0xFFFF6B2C);

  const _BillRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.greyOut = false,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 14,
                color: highlight
                    ? primaryOrange
                    : Colors.grey.shade400),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: greyOut
                        ? Colors.grey.shade400
                        : const Color(0xFF1A1A1A),
                    fontWeight: highlight
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: highlight ? 15 : 13,
                  fontWeight: FontWeight.bold,
                  color: greyOut
                      ? Colors.grey.shade400
                      : highlight
                          ? primaryOrange
                          : valueColor ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String text;
  static const Color primaryOrange = Color(0xFFFF6B2C);

  const _StepRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
                color: primaryOrange, shape: BoxShape.circle),
            child: Center(
              child: Text(step,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String selected;
  final IconData icon;
  final String label;
  final String subtitle;
  final void Function(String) onTap;
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  const _PaymentOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? lightOrange : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
              isSelected ? primaryOrange : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryOrange
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color:
                  isSelected ? Colors.white : Colors.grey.shade600,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? primaryOrange
                              : const Color(0xFF1A1A1A))),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryOrange : Colors.transparent,
                border: Border.all(
                    color: isSelected
                        ? primaryOrange
                        : Colors.grey.shade400,
                    width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                  color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool loading;
  final VoidCallback onTap;
  static const Color primaryOrange = Color(0xFFFF6B2C);

  const _BottomBar({
    required this.label,
    required this.sublabel,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: loading
                    ? [Colors.grey.shade300, Colors.grey.shade300]
                    : const [primaryOrange, Color(0xFFE85A1A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: loading
                ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(sublabel,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}