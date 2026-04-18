import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../main.dart'; // CustomerMainNavigation
import '../services/api_service.dart';
import '../services/socket_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String pickupCode;
  final double total;
  final double halfPaid;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.pickupCode,
    required this.total,
    required this.halfPaid,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  Map<String, dynamic>? _order;
  bool _loading = true;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);

    _loadOrder();
    _subscribeToOrder();
  }

  void _subscribeToOrder() {
    SocketService().connect();
    SocketService().joinRoom('order_${widget.orderId}');
    SocketService().on('order_status_update', (data) {
      debugPrint('Order status updated via socket');
      _loadOrder();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SocketService().leaveRoom('order_${widget.orderId}');
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final data = await ApiService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          // Access data from ApiResponse wrapper
          _order = Map<String, dynamic>.from(data['data'] ?? data['order'] ?? data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Order tracking load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _status => _order?['status'] as String? ?? 'pending';
  String? get _readyTime => _order?['ready_time'] as String?;

  // Status helpers
  bool get _isPending => _status == 'pending';
  bool get _isAccepted => _status == 'accepted' || _status == 'ready';
  bool get _isRejected => _status == 'rejected';
  bool get _isPickedUp => _status == 'picked_up';
  bool get _isCompleted => _status == 'completed';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: _loading
            ? const Center(
            child: CircularProgressIndicator(color: primaryOrange))
            : _isRejected
            ? _buildRejectedView()
            : _buildTrackingView(),
      ),
    );
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const CustomerMainNavigation()),
          (_) => false,
    );
  }

  // ── REJECTED VIEW ──────────────────────────────────────────────────────────
  Widget _buildRejectedView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: Colors.redAccent, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              "Order Rejected",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            Text(
              "Sorry, the stall worker was unable to accept your order at this time. Your advance payment will be refunded.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "₹${widget.halfPaid.toStringAsFixed(0)} refund will be processed in 3–5 business days.",
                      style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _goHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Back to Home",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TRACKING VIEW ──────────────────────────────────────────────────────────
  Widget _buildTrackingView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: _isRejected
              ? Colors.redAccent
              : _isCompleted
              ? Colors.green
              : primaryOrange,
          elevation: 0,
          pinned: true,
          automaticallyImplyLeading: false,
          title: const Text("Order Tracking",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          actions: [
            TextButton.icon(
              onPressed: _goHome,
              icon: const Icon(Icons.home_rounded,
                  color: Colors.white, size: 18),
              label: const Text("Home",
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Banner ─────────────────────────────────────────
                _buildStatusBanner(),

                const SizedBox(height: 20),

                // ── Pickup Code (shown when accepted) ─────────────────────
                if (_isAccepted || _isPickedUp || _isCompleted)
                  _buildPickupCodeCard(),

                // ── Status Timeline ────────────────────────────────────────
                const SizedBox(height: 20),
                _buildTimeline(),

                // ── Order Summary ──────────────────────────────────────────
                const SizedBox(height: 20),
                _buildPaymentSummary(),

                const SizedBox(height: 20),

                if (_isCompleted) ...[
                  _buildCompletedCard(),
                  const SizedBox(height: 20),
                ],

                // ── Refresh hint ───────────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: _loadOrder,
                    icon: const Icon(Icons.refresh_rounded,
                        color: primaryOrange, size: 18),
                    label: const Text("Refresh Status",
                        style: TextStyle(color: primaryOrange)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    if (_isPending) {
      title = "Waiting for Worker";
      subtitle = "Your order is being reviewed by the stall";
      color = Colors.orange;
      icon = Icons.hourglass_top_rounded;
    } else if (_isAccepted) {
      title = _status == 'ready' ? "Order is Ready! 🎉" : "Order Accepted!";
      subtitle = _status == 'ready'
          ? "Come to the stall and show your pickup code"
          : "Ready in ${_readyTime ?? 'a few minutes'}";
      color = Colors.green;
      icon = _status == 'ready'
          ? Icons.check_circle_rounded
          : Icons.restaurant_rounded;
    } else if (_isPickedUp) {
      title = "Order Picked Up";
      subtitle = "Please complete your remaining payment";
      color = Colors.blue;
      icon = Icons.shopping_bag_rounded;
    } else if (_isCompleted) {
      title = "Order Completed! 🎊";
      subtitle = "Thank you for your order!";
      color = Colors.green;
      icon = Icons.done_all_rounded;
    } else {
      title = "Processing";
      subtitle = "Please wait...";
      color = Colors.grey;
      icon = Icons.sync_rounded;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPending ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: color)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B2C), Color(0xFFE85A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Your Pickup Code",
            style: TextStyle(
                color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.pickupCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: widget.pickupCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Code copied!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Show this code to the worker when you arrive",
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final stages = [
      _TimelineStage(
        icon: Icons.receipt_long_rounded,
        label: "Order Placed",
        sublabel: "Advance paid",
        done: true,
      ),
      _TimelineStage(
        icon: Icons.check_circle_rounded,
        label: "Worker Accepted",
        sublabel: _readyTime != null ? "Ready in $_readyTime" : "Waiting...",
        done: _isAccepted || _isPickedUp || _isCompleted,
        active: _isPending,
      ),
      _TimelineStage(
        icon: Icons.restaurant_rounded,
        label: "Order Ready",
        sublabel: "Come pick it up",
        done: _status == 'ready' || _isPickedUp || _isCompleted,
        active: _isAccepted && _status != 'ready',
      ),
      _TimelineStage(
        icon: Icons.shopping_bag_rounded,
        label: "Picked Up",
        sublabel: "Remaining payment due",
        done: _isPickedUp || _isCompleted,
        active: _status == 'ready',
      ),
      _TimelineStage(
        icon: Icons.done_all_rounded,
        label: "Completed",
        sublabel: "Full payment done",
        done: _isCompleted,
        active: _isPickedUp,
      ),
    ];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  color: primaryOrange, size: 20),
              const SizedBox(width: 8),
              const Text("Order Timeline",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 16),
          ...stages.asMap().entries.map((e) {
            final isLast = e.key == stages.length - 1;
            return _buildTimelineItem(e.value, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineStage stage, bool isLast) {
    final color = stage.done
        ? Colors.green
        : stage.active
        ? primaryOrange
        : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: stage.done
                    ? Colors.green
                    : stage.active
                    ? lightOrange
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                    color: color,
                    width: stage.active ? 2 : 1),
              ),
              child: Icon(stage.icon, size: 16, color: color),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 2,
                height: 32,
                color: stage.done ? Colors.green : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: stage.done
                      ? const Color(0xFF1A1A1A)
                      : stage.active
                      ? primaryOrange
                      : Colors.grey.shade400,
                ),
              ),
              Text(
                stage.sublabel,
                style: TextStyle(
                    fontSize: 12,
                    color: stage.done
                        ? Colors.grey.shade500
                        : stage.active
                        ? Colors.grey.shade600
                        : Colors.grey.shade300),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  color: primaryOrange, size: 20),
              const SizedBox(width: 8),
              const Text("Payment Summary",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 14),
          // Paid now
          _PayRow(
            label: "Paid Now (advance 50%)",
            value: "₹${widget.halfPaid.toStringAsFixed(0)}",
            statusLabel: "PAID",
            statusColor: Colors.green,
          ),
          const Divider(height: 20),
          // Remaining
          _PayRow(
            label: "Pay at Pickup (50%)",
            value: "₹${widget.halfPaid.toStringAsFixed(0)}",
            statusLabel: _isCompleted ? "PAID" : "DUE",
            statusColor: _isCompleted ? Colors.green : Colors.orange,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text("₹${widget.total.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryOrange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 40),
          const SizedBox(height: 10),
          const Text("Thank you for your order! 🎉",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green)),
          const SizedBox(height: 8),
          Text("Hope you enjoyed your meal. See you again!",
              textAlign: TextAlign.center,
              style:
              TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Back to Home",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _TimelineStage {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool done;
  final bool active;

  const _TimelineStage({
    required this.icon,
    required this.label,
    required this.sublabel,
    this.done = false,
    this.active = false,
  });
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final String statusLabel;
  final Color statusColor;

  const _PayRow({
    required this.label,
    required this.value,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
        ),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 10),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ),
      ],
    );
  }
}