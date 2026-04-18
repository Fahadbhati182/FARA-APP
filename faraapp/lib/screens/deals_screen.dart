import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Set<String> _copiedCodes = {};

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color darkOrange = Color(0xFFE85A1A);
  static const Color lightOrange = Color(0xFFFFF3EE);

  List<_Deal> _deals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _fetchDeals();
  }

  Future<void> _fetchDeals() async {
    try {
      final data = await ApiService.getCoupons();
      if (mounted) {
        setState(() {
          _deals = data.map((json) {
            Color parseColor(String? colorStr, Color fallback) {
              if (colorStr == null || colorStr.isEmpty) return fallback;
              try {
                return Color(int.parse(colorStr));
              } catch (e) {
                return fallback;
              }
            }

            return _Deal(
              id: json['_id'],
              title: json['title'] ?? 'Deal',
              description: json['description'] ?? '',
              code: json['code'] ?? '',
              badge: json['badge'] ?? 'OFFER',
              badgeColor: parseColor(json['badgeColor'], const Color(0xFFFF6B2C)),
              expiresIn: "${json['expiresInDays'] ?? 7} days left",
              icon: Icons.local_offer_rounded,
              gradient: [
                parseColor(json['gradientStart'], const Color(0xFFFF6B2C)),
                parseColor(json['gradientEnd'], const Color(0xFFFF9A5C)),
              ],
            );
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching deals: \$e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCodes.add(code));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text("Code '$code' copied!",
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    // Reset copied state after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copiedCodes.remove(code));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Header ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: primaryOrange,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Deals & Offers",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryOrange, darkOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Subtitle
                    Positioned(
                      bottom: 50,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              "${_deals.length} active offers",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Deal Cards ──────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: primaryOrange)),
            )
          else if (_deals.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  "No active deals right now.\nCheck back later!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final deal = _deals[index];
                    final delay = index * 0.12;

                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        final t = (_controller.value - delay).clamp(0.0, 1.0);
                        final curve = Curves.easeOutCubic.transform(t);
                        return Opacity(
                          opacity: curve,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - curve)),
                            child: child,
                          ),
                        );
                      },
                      child: _DealCard(
                        deal: deal,
                        isCopied: _copiedCodes.contains(deal.code),
                        onCopy: () => _copyCode(deal.code),
                        onApply: () async {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          if (cart.items.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Add items to your cart first!")),
                            );
                            return;
                          }
                          try {
                            final result = await ApiService.applyCoupon(deal.code, cart.totalPrice);
                            cart.applyCoupon(result['couponCode'], (result['discountAmount'] as num).toDouble());
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Coupon '${deal.code}' applied to cart!")),
                              );
                              Navigator.pop(context); // Go back to cart
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                  childCount: _deals.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Deal Data Model ──────────────────────────────────────────────────────────
class _Deal {
  final String? id;
  final String title;
  final String description;
  final String code;
  final String badge;
  final Color badgeColor;
  final String expiresIn;
  final IconData icon;
  final List<Color> gradient;

  const _Deal({
    this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.badge,
    required this.badgeColor,
    required this.expiresIn,
    required this.icon,
    required this.gradient,
  });
}

// ── Deal Card Widget ─────────────────────────────────────────────────────────
class _DealCard extends StatefulWidget {
  final _Deal deal;
  final bool isCopied;
  final VoidCallback onCopy;
  final VoidCallback? onApply;

  const _DealCard({
    required this.deal,
    required this.isCopied,
    required this.onCopy,
    this.onApply,
  });

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: deal.gradient.first.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Card Header ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: deal.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(18))
                    : BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(deal.icon,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Title + badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                deal.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                deal.badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    color: Colors.white70, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  deal.expiresIn,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // ── Expanded Body ────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      deal.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Coupon code row
                    Row(
                      children: [
                        // Dashed coupon box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: deal.gradient.first.withOpacity(0.4),
                                width: 1.5,
                                // Dashed effect workaround using style
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(Icons.confirmation_number_outlined,
                                    color: deal.gradient.first,
                                    size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  deal.code,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: deal.gradient.first,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Copy button
                        GestureDetector(
                          onTap: widget.onCopy,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: widget.isCopied
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFF10B981),
                                  Color(0xFF34D399)
                                ],
                              )
                                  : LinearGradient(
                                colors: deal.gradient,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isCopied
                                      ? Icons.check_rounded
                                      : Icons.copy_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isCopied ? "Copied!" : "Copy",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Apply button (New)
                        if (widget.onApply != null)
                          GestureDetector(
                            onTap: widget.onApply,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "Apply",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}