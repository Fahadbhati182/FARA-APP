import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerRequestsScreen extends StatefulWidget {
  const OwnerRequestsScreen({super.key});

  @override
  State<OwnerRequestsScreen> createState() => _OwnerRequestsScreenState();
}

class _OwnerRequestsScreenState extends State<OwnerRequestsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _allRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAdminAllRequests(); 
      _allRequests = response;
    } catch (e) {
      debugPrint('Requests load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiService.updateMaterialRequestStatus(id, status);
      _loadRequests();

      if (mounted) {
        final msg = status == 'fulfilled'
            ? "✅ Marked as fulfilled"
            : "❌ Request rejected";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status == 'fulfilled' ? Colors.green : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('Update status error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<dynamic> _filtered(String status) {
    if (status == 'all') return _allRequests;
    return _allRequests.where((r) => r['status'] == status).toList();
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

  int get _pendingCount =>
      _allRequests.where((r) => r['status'] == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryOrange,
        elevation: 0,
        title: const Text("Material Requests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _loadRequests, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Fulfilled"),
            Tab(text: "All"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(_filtered('pending'), showActions: true),
                _buildRequestList(_filtered('fulfilled'), showActions: false),
                _buildRequestList(_filtered('all'), showActions: false),
              ],
            ),
    );
  }

  Widget _buildRequestList(List<dynamic> requests, {required bool showActions}) {
    if (requests.isEmpty) return const Center(child: Text("No requests found"));

    return RefreshIndicator(
      color: primaryOrange,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, i) {
          final req = requests[i];
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
                      Text(req['item_name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(req['status']?.toUpperCase() ?? 'PENDING', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Quantity: ${req['quantity'] ?? '0'}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text("Requested by: ${req['worker']?['name'] ?? 'Worker'}", style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_timeAgo(req['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (showActions && req['status'] == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(req['_id'], 'fulfilled'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("Fulfill", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}