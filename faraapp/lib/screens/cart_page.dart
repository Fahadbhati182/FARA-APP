import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../constants/colors.dart';
import '../screens/checkout_screen.dart';
import 'deals_screen.dart';
import '../services/api_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _couponController = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCouponCode(CartProvider cart) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _applying = true);
    try {
      final result = await ApiService.applyCoupon(code, cart.totalPrice);
      // result example: { finalPrice: ..., discountAmount: ..., couponCode: ... }
      cart.applyCoupon(result['couponCode'], (result['discountAmount'] as num).toDouble());
      _couponController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coupon '$code' applied successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A1A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Your Cart",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Your cart is empty",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Add some delicious momos!",
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: cart.items.length,
        itemBuilder: (context, index) {
          final item = cart.items[index];

          return Dismissible(
            key: Key(item.name),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 26),
            ),
            onDismissed: (_) => cart.removeAllOfItem(item.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹ ${item.price.toStringAsFixed(0)} each",
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Qty controls
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _cartBtn(
                          Icons.remove,
                              () => cart.removeItem(item.name),
                        ),
                        AnimatedSwitcher(
                          duration:
                          const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(
                                  scale: anim, child: child),
                          child: Text(
                            "${item.quantity}",
                            key: ValueKey(item.quantity),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _cartBtn(
                          Icons.add,
                              () => cart.addItem(item.name, item.price),
                        ),
                      ],
                    ),
                  ),

                  // Line total
                  const SizedBox(width: 12),
                  Text(
                    "₹ ${(item.price * item.quantity).toStringAsFixed(0)}",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // ── Bottom Summary ──────────────────────────────────────────
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cart.appliedCouponCode == null)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: "Enter Coupon Code",
                            hintStyle: TextStyle(fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _applying
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : TextButton(
                            onPressed: () => _applyCouponCode(cart),
                            child: const Text("APPLY",
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Coupon Applied: ${cart.appliedCouponCode}",
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => cart.clearCoupon(),
                        child: const Icon(Icons.close, color: Colors.green, size: 18),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DealsScreen()),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined, color: Colors.grey.shade600, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "View available offers",
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _summaryRow("Subtotal", "₹ ${cart.totalPrice}"),
              if (cart.couponDiscount > 0) ...[
                const SizedBox(height: 8),
                _summaryRow(
                  "Discount",
                  "-₹ ${cart.couponDiscount.toStringAsFixed(0)}",
                  valueColor: Colors.green,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              _summaryRow(
                "Grand Total",
                "₹ ${cart.grandTotal}",
                bold: true,
                fontSize: 18,
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Proceed to Checkout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        bool bold = false,
        double fontSize = 14,
        Color? valueColor,
      }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: const Color(0xFF1A1A1A),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}