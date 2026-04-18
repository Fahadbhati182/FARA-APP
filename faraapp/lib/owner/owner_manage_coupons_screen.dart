import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerManageCouponsScreen extends StatefulWidget {
  const OwnerManageCouponsScreen({super.key});

  @override
  State<OwnerManageCouponsScreen> createState() => _OwnerManageCouponsScreenState();
}

class _OwnerManageCouponsScreenState extends State<OwnerManageCouponsScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  
  bool _loading = true;
  List<dynamic> _coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getCoupons();
      if (mounted) {
        setState(() {
          _coupons = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteCoupon(String id) async {
    try {
      await ApiService.deleteCoupon(id);
      _fetchCoupons();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon deleted successfully'), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showAddCouponModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final discountValCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add New Coupon", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title (e.g. 20% OFF)")),
                  const SizedBox(height: 10),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
                  const SizedBox(height: 10),
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code (e.g. SAVE20)")),
                  const SizedBox(height: 10),
                  TextField(controller: discountValCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Discount %")),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        try {
                          await ApiService.createCoupon({
                            "title": titleCtrl.text,
                            "description": descCtrl.text,
                            "code": codeCtrl.text,
                            "badge": "NEW",
                            "discountValue": int.tryParse(discountValCtrl.text) ?? 10
                          });
                          if (!mounted) return;
                          Navigator.pop(context);
                          _fetchCoupons();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                      child: const Text("Create Coupon", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("Manage Coupons", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryOrange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryOrange,
        onPressed: _showAddCouponModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Coupon", style: TextStyle(color: Colors.white)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : _coupons.isEmpty
          ? const Center(child: Text("No coupons active", style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(coupon['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(coupon['title'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteCoupon(coupon['_id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
