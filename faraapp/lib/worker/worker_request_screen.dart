import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WorkerRequestScreen extends StatefulWidget {
  const WorkerRequestScreen({super.key});

  @override
  State<WorkerRequestScreen> createState() => _WorkerRequestScreenState();
}

class _WorkerRequestScreenState extends State<WorkerRequestScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);

  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();

  bool _submitting = false;
  bool _loadingHistory = true;
  List<Map<String, dynamic>> _myRequests = [];

  String _workerName = '';
  String _stallName = '';

  final List<String> _quickItems = [
    "Flour", "Chicken", "Vegetables", "Oil", "Spices", "Sauce", "Packaging", "Water",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHistory();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      final data = profile['data'] ?? profile;
      if (mounted) {
        setState(() {
          _workerName = data['name'] ?? 'Worker';
          _stallName = data['stall_name'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Profile error: $e');
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final response = await ApiService.getWorkerMaterialRequests();
      final data = response['data'] ?? [];
      if (mounted) {
        setState(() {
          _myRequests = List<Map<String, dynamic>>.from(data as List);
        });
      }
    } catch (e) {
      debugPrint('History error: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _submitRequest() async {
    final item = _itemController.text.trim();
    final qty = _qtyController.text.trim();

    if (item.isEmpty || qty.isEmpty) {
      _showSnack("Please fill item and quantity", Colors.redAccent);
      return;
    }

    setState(() => _submitting = true);

    try {
      await ApiService.createMaterialRequest({
        'worker_name': _workerName,
        'stall_name': _stallName,
        'item_name': item,
        'quantity': qty,
        'notes': _notesController.text.trim(),
      });

      _itemController.clear();
      _qtyController.clear();
      _notesController.clear();
      _loadHistory();

      if (mounted) _showSnack("Request sent to owner! ✅", Colors.green);
    } catch (e) {
      if (mounted) _showSnack("Error: ${e.toString()}", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primaryOrange, Color(0xFFE85A1A)]),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Request Materials", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Tell the owner what you need", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickItems.map((item) {
                          final selected = _itemController.text == item;
                          return GestureDetector(
                            onTap: () => setState(() => _itemController.text = item),
                            child: Chip(
                              label: Text(item),
                              backgroundColor: selected ? primaryOrange : Colors.grey.shade100,
                              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: _itemController, decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: _qtyController, decoration: const InputDecoration(labelText: "Quantity (e.g. 5kg)", border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: "Notes (Optional)", border: OutlineInputBorder())),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white),
                          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text("SEND TO OWNER", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("My Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              if (_loadingHistory) const Center(child: CircularProgressIndicator())
              else if (_myRequests.isEmpty) const Center(child: Text("No requests yet"))
              else ..._myRequests.map((req) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      title: Text(req['item_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Qty: ${req['quantity']} • ${_timeAgo(req['createdAt'])}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: req['status'] == 'fulfilled' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(req['status'].toString().toUpperCase(), style: TextStyle(color: req['status'] == 'fulfilled' ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}