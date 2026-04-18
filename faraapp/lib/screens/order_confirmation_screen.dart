import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // adjust if needed

class OrderConfirmationScreen extends StatefulWidget {
  final String name;
  final String address;
  final String paymentMethod;
  final double grandTotal;
  final String? couponApplied;

  const OrderConfirmationScreen({
    super.key,
    required this.name,
    required this.address,
    required this.paymentMethod,
    required this.grandTotal,
    this.couponApplied,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _contentController;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;

  // Fake order ID
  final String _orderId =
      "FARA${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

  // Estimated delivery time
  final String _eta = "25–35 min";

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color darkOrange = Color(0xFFE85A1A);
  static const Color lightOrange = Color(0xFFFFF3EE);

  // Order tracking steps
  final List<_TrackStep> _trackSteps = [
    _TrackStep(
        icon: Icons.check_circle_rounded,
        label: "Order Placed",
        subtitle: "We've received your order",
        done: true),
    _TrackStep(
        icon: Icons.restaurant_rounded,
        label: "Being Prepared",
        subtitle: "Kitchen is working on it",
        done: false),
    _TrackStep(
        icon: Icons.delivery_dining_rounded,
        label: "Out for Delivery",
        subtitle: "On the way to you",
        done: false),
    _TrackStep(
        icon: Icons.home_rounded,
        label: "Delivered",
        subtitle: "Enjoy your meal!",
        done: false),
  ];

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
    ]).animate(_checkController);

    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _checkController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _contentController, curve: Curves.easeOutCubic),
    );

    // Sequence
    _checkController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _contentController.forward();
      });
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // prevent back
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Animated Checkmark ──────────────────────────
                AnimatedBuilder(
                  animation: _checkController,
                  builder: (_, __) => Opacity(
                    opacity: _checkOpacity.value,
                    child: Transform.scale(
                      scale: _checkScale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryOrange.withOpacity(0.1),
                            ),
                          ),
                          // Inner circle
                          Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [primaryOrange, darkOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Title ───────────────────────────────────────
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (_, child) => Opacity(
                    opacity: _contentOpacity.value,
                    child: child,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Order Placed! 🎉",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Thank you, ${widget.name.split(' ').first}! Your momos are on the way.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Animated Content ────────────────────────────
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (_, child) => FadeTransition(
                    opacity: _contentOpacity,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [

                      // ── Order Info Card ───────────────────────
                      _infoCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: _infoTile(
                                icon: Icons.tag_rounded,
                                label: "Order ID",
                                value: _orderId,
                                valueColor: primaryOrange,
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade200),
                            Expanded(
                              child: _infoTile(
                                icon: Icons.access_time_rounded,
                                label: "Est. Delivery",
                                value: _eta,
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade200),
                            Expanded(
                              child: _infoTile(
                                icon: Icons.currency_rupee_rounded,
                                label: "Total Paid",
                                value:
                                "₹ ${widget.grandTotal.toStringAsFixed(0)}",
                                valueColor: primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Live Order Tracking ───────────────────
                      _infoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.delivery_dining_rounded,
                                    color: primaryOrange, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  "Order Tracking",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "Live",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ..._buildTrackingTimeline(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Delivery Address ──────────────────────
                      _infoCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: lightOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.location_on_rounded,
                                  color: primaryOrange,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Delivering To",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.address,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Payment & Coupon summary ──────────────
                      _infoCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payment_rounded,
                                    color: primaryOrange, size: 20),
                                const SizedBox(width: 10),
                                const Text("Payment",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const Spacer(),
                                Text(
                                  widget.paymentMethod == "cod"
                                      ? "Cash on Delivery"
                                      : widget.paymentMethod
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.couponApplied != null) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                      Icons.confirmation_number_outlined,
                                      color: Colors.green,
                                      size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Coupon Applied",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.grey.shade700),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.couponApplied!,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Back to Home Button ───────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                                  (_) => false,
                            );
                          },
                          child: const Text(
                            "Back to Home",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          // TODO: navigate to order history
                        },
                        child: const Text(
                          "View My Orders",
                          style: TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTrackingTimeline() {
    return List.generate(_trackSteps.length, (i) {
      final step = _trackSteps[i];
      final isLast = i == _trackSteps.length - 1;
      final isActive = i == 1; // "Being Prepared" is active on confirmation

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done
                      ? primaryOrange
                      : isActive
                      ? lightOrange
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: step.done || isActive
                        ? primaryOrange
                        : Colors.grey.shade300,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: step.done
                      ? const Icon(Icons.check,
                      color: Colors.white, size: 14)
                      : Icon(
                    step.icon,
                    size: 14,
                    color: isActive
                        ? primaryOrange
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  color: step.done
                      ? primaryOrange
                      : Colors.grey.shade200,
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: step.done || isActive
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (step.done)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lightOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: primaryOrange, size: 20),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TrackStep {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool done;
  const _TrackStep({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.done,
  });
}