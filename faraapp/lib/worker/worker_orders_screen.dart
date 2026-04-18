import 'package:flutter/material.dart';
import '../screens/role_selection_screen.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class WorkerOrdersScreen extends StatefulWidget {
  const WorkerOrdersScreen({super.key});

  @override
  State<WorkerOrdersScreen> createState() => _WorkerOrdersScreenState();
}

class _WorkerOrdersScreenState extends State<WorkerOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _acceptedOrders = [];
  List<Map<String, dynamic>> _readyOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];

  String _workerName = 'Worker';
  String _stallName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
    _loadOrders();
    _initSocket();
  }

  void _initSocket() {
    SocketService().connect();
    SocketService().on('new_order', (data) {
      debugPrint('New order received via socket');
      _loadOrders();
      _showSnack("🔔 New Order Received!", Colors.green);
    });
    SocketService().on('order_accepted_by_other', (data) {
      debugPrint('Order accepted by another worker');
      _loadOrders();
    });
  }

  @override
  void dispose() {
    if (_stallName.isNotEmpty) {
      SocketService().leaveRoom('stall_$_stallName');
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      // Use profile from our custom backend
      final data = profile['data'] ?? profile;
      if (mounted) {
        setState(() {
          _workerName = data['name'] ?? 'Worker';
          _stallName = data['stall_name'] ?? '';
          if (_stallName.isNotEmpty) {
            SocketService().joinRoom('stall_$_stallName');
          }
        });
      }
    } catch (e) {
      debugPrint('Profile error: $e');
    }
  }

  Future<void> _loadOrders() async {
    try {
      final response = await ApiService.getWorkerOrders();
      final List allOrders = response['data'] ?? [];

      if (mounted) {
        setState(() {
          _pendingOrders = allOrders
              .where((o) => o['status'] == 'pending' && o['order_type'] == 'takeaway')
              .map((o) => Map<String, dynamic>.from(o))
              .toList();

          _acceptedOrders = allOrders
              .where((o) => o['status'] == 'accepted')
              .map((o) => Map<String, dynamic>.from(o))
              .toList();

          _readyOrders = allOrders
              .where((o) => o['status'] == 'ready')
              .map((o) => Map<String, dynamic>.from(o))
              .toList();

          _historyOrders = allOrders
              .where((o) => ['picked_up', 'completed', 'rejected'].contains(o['status']))
              .map((o) => Map<String, dynamic>.from(o))
              .toList();

          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Orders load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAcceptSheet(Map<String, dynamic> order) {
    String selectedTime = '15 mins';
    final timeOptions = [
      '5 mins', '10 mins', '15 mins', '20 mins', '25 mins', '30 mins'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 44),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text("Accept Order?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  "₹${order['total']?.toStringAsFixed(0) ?? '0'} • ${_itemSummary(order)}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              const Text("How long will it take?",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 6),
              Text("Customer will be notified of this time",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timeOptions.map((t) {
                  final sel = selectedTime == t;
                  return GestureDetector(
                    onTap: () => setSheet(() => selectedTime = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? primaryOrange : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(order['_id'], {
                      'status': 'accepted',
                      'ready_time': selectedTime,
                    }, "✅ Order accepted! Customer notified.", Colors.green);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "ACCEPT — Ready in $selectedTime",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRejectConfirm(order);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Reject Order",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, Map<String, dynamic> data, String successMsg, Color successColor) async {
    try {
      await ApiService.updateOrderStatus(id, data);
      _loadOrders();
      _showSnack(successMsg, successColor);
    } catch (e) {
      _showSnack("Error: ${e.toString()}", Colors.redAccent);
    }
  }

  void _showRejectConfirm(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reject Order?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          "Reject order of ₹${order['total']?.toStringAsFixed(0) ?? '0'}?\n\nCustomer will be notified and their advance will be refunded.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(order['_id'], {'status': 'rejected'}, "❌ Order rejected. Customer notified.", Colors.redAccent);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPickupVerification(Map<String, dynamic> order) {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Icon(Icons.qr_code_rounded, color: primaryOrange, size: 36),
              const SizedBox(height: 16),
              const Text("Verify Pickup Code", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Ask customer for their 4-digit code", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 12, color: primaryOrange),
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: "CODE",
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    final entered = codeController.text.trim().toUpperCase();
                    final correct = order['pickup_code'] as String? ?? '';
                    if (entered == correct) {
                      Navigator.pop(context);
                      _markPickedUp(order);
                    } else {
                      _showSnack("❌ Wrong code. Ask customer to check again.", Colors.redAccent);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("VERIFY CODE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markPickedUp(Map<String, dynamic> order) async {
    try {
      await ApiService.updateOrderStatus(order['_id'], {'status': 'picked_up'});
      _loadOrders();
      _showSnack("✅ Code verified! Collect remaining payment.", Colors.green);
      if (mounted) _showCollectPaymentDialog(order);
    } catch (e) {
      _showSnack("Error updating order.", Colors.redAccent);
    }
  }

  void _showCollectPaymentDialog(Map<String, dynamic> order) {
    final remaining = (order['payment_2'] as num?)?.toDouble() ?? 0.0;
    String paymentMethod = 'cash'; // default
    bool processing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.currency_rupee_rounded, color: Colors.green, size: 40),
              const SizedBox(height: 16),
              const Text("Collect Remaining Payment",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text("₹${remaining.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: primaryOrange,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 20),
              const Text("Select Payment Mode",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => paymentMethod = 'cash'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: paymentMethod == 'cash'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: paymentMethod == 'cash' ? Colors.green : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.money_rounded,
                                color: paymentMethod == 'cash' ? Colors.green : Colors.grey),
                            const Text("Cash", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => paymentMethod = 'online'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: paymentMethod == 'online'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: paymentMethod == 'online' ? Colors.blue : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.payment_rounded,
                                color: paymentMethod == 'online' ? Colors.blue : Colors.grey),
                            const Text("Online", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: processing
                      ? null
                      : () async {
                    setDialogState(() => processing = true);
                    try {
                      await ApiService.processPayment({
                        'orderId': order['_id'],
                        'amount': remaining,
                        'method': paymentMethod,
                      });
                      
                      if (mounted) {
                        Navigator.pop(context);
                        _loadOrders();
                        _showSnack(
                            paymentMethod == 'cash'
                                ? "✅ Payment collected (Cash). Order completed!"
                                : "✅ Online payment successful. Order completed!",
                            Colors.green);
                      }
                    } catch (e) {
                      if (mounted) {
                        setDialogState(() => processing = false);
                        _showSnack("❌ ${e.toString()}", Colors.redAccent);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paymentMethod == 'cash' ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: processing
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                      paymentMethod == 'cash'
                          ? "CONFIRM CASH"
                          : "PROCESS ONLINE",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              if (!processing)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // _completeOrder is now handled by processPaymentFlow in backend

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (_) => false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _itemSummary(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    return items.map((i) => "${i['name']} ×${i['qty']}").join(", ");
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [primaryOrange, Color(0xFFE85A1A)]),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello, $_workerName 👋", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      if (_stallName.isNotEmpty) Text(_stallName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadOrders),
                      IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
                    ],
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'New'), Tab(text: 'Preparing'), Tab(text: 'Ready'), Tab(text: 'History')],
              labelColor: primaryOrange,
              indicatorColor: primaryOrange,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(_pendingOrders, "new"),
                  _buildOrderList(_acceptedOrders, "preparing"),
                  _buildOrderList(_readyOrders, "ready"),
                  _buildOrderList(_historyOrders, "history"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String type) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (orders.isEmpty) return Center(child: Text("No $type orders"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, i) {
        final order = orders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Order #${order['_id'].toString().substring(order['_id'].length - 6).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_timeAgo(order['createdAt']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Divider(),
                Text(_itemSummary(order)),
                const SizedBox(height: 12),
                if (type == "new")
                  ElevatedButton(
                    onPressed: () => _showAcceptSheet(order),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("ACCEPT ORDER"),
                  ),
                if (type == "preparing")
                  ElevatedButton(
                    onPressed: () => _updateStatus(order['_id'], {'status': 'ready'}, "🎉 Order marked as ready!", Colors.green),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white),
                    child: const Text("MARK AS READY"),
                  ),
                if (type == "ready")
                  ElevatedButton(
                    onPressed: () => _showPickupVerification(order),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text("VERIFY PICKUP"),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}