import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class OwnerPaymentsAuditScreen extends StatefulWidget {
  const OwnerPaymentsAuditScreen({super.key});

  @override
  State<OwnerPaymentsAuditScreen> createState() => _OwnerPaymentsAuditScreenState();
}

class _OwnerPaymentsAuditScreenState extends State<OwnerPaymentsAuditScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  
  bool _loading = true;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAllPayments();
      if (mounted) {
        setState(() {
          _payments = response['data'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showLogs(dynamic payment) {
    final logs = payment['logs'] as List<dynamic>? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transaction Trace",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "TXN ID: ${payment['transactionId'] ?? 'N/A'}",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const Divider(height: 32),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text("No logs found for this transaction"))
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, i) {
                        final log = logs[i];
                        final time = DateTime.tryParse(log['timestamp'] ?? '');
                        final isError = log['type'] == 'error';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isError ? Colors.red.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isError ? Colors.red.shade100 : Colors.blue.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isError ? Icons.error_outline : Icons.info_outline,
                                    size: 16,
                                    color: isError ? Colors.red : Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    time != null ? DateFormat('HH:mm:ss').format(time) : '??:??',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isError ? Colors.red : Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['message'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text("Payment Audit", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _fetchPayments, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : _payments.isEmpty
              ? const Center(child: Text("No transactions recorded yet"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, i) {
                    final p = _payments[i];
                    final isSuccess = p['status'] == 'success';
                    final method = p['method']?.toString().toUpperCase() ?? 'N/A';
                    final date = DateTime.tryParse(p['createdAt'] ?? '');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => _showLogs(p),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p['status']?.toString().toUpperCase() ?? 'PENDING',
                                      style: TextStyle(
                                        color: isSuccess ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    date != null ? DateFormat('dd MMM, HH:mm').format(date) : '',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['order']?['customer_name'] ?? 'Guest Customer',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Mode: $method • ID: ${p['transactionId'] ?? '...'}",
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "₹${p['amount']?.toStringAsFixed(0) ?? '0'}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Worker: ${p['worker']?['name'] ?? 'N/A'}",
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    "View Audit Trail →",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
