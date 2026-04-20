import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/loading_button.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _allOrders = [];
  String _selectedLocation = "All";
  List<String> _locations = ["All"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      // In a real scenario, you might have a dedicated admin endpoint for all orders.
      // For now, we'll use a placeholder or the worker history logic if applicable.
      // Since we don't have a specific "Admin Get All Orders" yet, we'll implement it or use what's available.
      // Let's assume we need a getAdminOrders in ApiService.
      
      final response = await ApiService.getAdminAllOrders();
      debugPrint('AdminAllOrders Response Status: ${response['status']}');
      final List data = response['data'] ?? [];
      debugPrint('AdminAllOrders Data Count: ${data.length}');

      _allOrders = List<Map<String, dynamic>>.from(data);
      final locs = _allOrders
          .map((o) => o['location'] as String? ?? 'Unknown')
          .toSet()
          .toList()
        ..sort();
      _locations = ['All', ...locs];
    } catch (e) {
      debugPrint('Orders load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRefund(Map<String, dynamic> order) async {
    final orderId = order['_id'];
    final isRazorpay = order['razorpay_payment_id'] != null;
    final refundAmount = (order['refund_amount'] ?? 0).toDouble();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRazorpay ? "Process Razorpay Refund" : "Mark as Refunded"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to refund ₹${refundAmount.toStringAsFixed(0)}?"),
            const SizedBox(height: 12),
            if (isRazorpay)
              const Text("This will automatically reverse the transaction through Razorpay.", style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              const Text("This will mark the order as refunded in the system. Make sure you have manually paid the customer.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            child: const Text("Confirm Refund", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.processOrderRefund(orderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refund processed successfully"), backgroundColor: Colors.green),
        );
        _loadOrders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Refund failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  List<Map<String, dynamic>> _filtered(String status) {
    return _allOrders.where((o) {
      final matchStatus = status == 'all' || o['status'] == status;
      final matchLoc = _selectedLocation == 'All' ||
          (o['location'] as String? ?? '') == _selectedLocation;
      return matchStatus && matchLoc;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return Colors.blue;
      case 'ready': return Colors.indigo;
      case 'picked_up': return Colors.purple;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted': return Icons.check_circle_rounded;
      case 'ready': return Icons.restaurant_rounded;
      case 'picked_up': return Icons.shopping_bag_rounded;
      case 'completed': return Icons.done_all_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.hourglass_top_rounded;
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryOrange,
        elevation: 0,
        title: const Text("All Orders",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          isScrollable: true,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Pending"),
            Tab(text: "Active"),
            Tab(text: "Completed"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: primaryOrange, size: 16),
                    SizedBox(width: 4),
                    Text("Filter by Location",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1A1A1A))),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _locations.length,
                    itemBuilder: (context, i) {
                      final loc = _locations[i];
                      final selected = loc == _selectedLocation;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedLocation = loc),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? primaryOrange
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? primaryOrange
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(loc,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              )),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                child:
                CircularProgressIndicator(color: primaryOrange))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_filtered('all')),
                _buildOrderList(_filtered('pending')),
                _buildOrderList(_allOrders.where((o) {
                  final loc = _selectedLocation == 'All' ||
                      (o['location'] as String? ?? '') ==
                          _selectedLocation;
                  return ['accepted', 'ready', 'picked_up']
                      .contains(o['status']) &&
                      loc;
                }).toList()),
                _buildOrderList(_filtered('completed')),
                _buildOrderList(_filtered('rejected')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSourceIcon(String source) {
    IconData icon;
    Color color;
    switch (source) {
      case 'zomato':
        icon = Icons.delivery_dining_rounded;
        color = Colors.red;
        break;
      case 'swiggy':
        icon = Icons.delivery_dining_rounded;
        color = Colors.orange;
        break;
      case 'offline':
        icon = Icons.point_of_sale_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.phone_android_rounded;
        color = primaryOrange;
    }
    return Icon(icon, color: color, size: 18);
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(child: Text("No orders found", style: TextStyle(color: Colors.grey.shade400)));
    }

    return RefreshIndicator(
      color: primaryOrange,
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final order = orders[i];
          final status = (order['status'] ?? 'pending').toString();
          final isTakeaway = (order['order_type'] ?? '') == 'takeaway';
          final items = order['items'] as List<dynamic>? ?? [];
          final itemSummary = items.map((i) => "${i['name']} ×${i['qty']}").join(", ");

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                ListTile(
                  title: Row(
                    children: [
                      _getSourceIcon(order['source'] ?? 'app'),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order['customer_name'] ?? 'Guest')),
                    ],
                  ),
                  subtitle: Text(itemSummary),
                  trailing: Text("₹${(double.tryParse(order['total']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 13)),
                          if (order['is_manually_verified'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(4)),
                              child: const Text("MANUAL", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ),
                          ],
                        ],
                      ),
                      Text(_timeAgo(order['createdAt']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (status == 'rejected' && order['rejection_reason'] != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 6),
                            Expanded(child: Text("Reason: ${order['rejection_reason']}", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Return to Customer: ₹${(double.tryParse(order['refund_amount']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}",
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (order['is_refunded'] == true) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                                SizedBox(width: 4),
                                Text("REFUNDED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (order['customer'] != null && 
                                  order['customer'] is Map && 
                                  (order['customer']['phone'] != null))
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _callCustomer(order['customer']['phone'].toString()),
                                    icon: const Icon(Icons.phone, size: 16),
                                    label: const Text("Call Customer"),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: const BorderSide(color: Colors.blue),
                                        foregroundColor: Colors.blue
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LoadingButton(
                                  text: order['razorpay_payment_id'] != null ? "Refund (Razorpay)" : "Mark Refunded",
                                  height: 40,
                                  onPressed: () => _handleRefund(order),
                                  color: Colors.redAccent,
                                  icon: Icons.refresh_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}