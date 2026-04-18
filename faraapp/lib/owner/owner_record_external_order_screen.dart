import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../constants/colors.dart';
import '../screens/food_detail_screen.dart';

class OwnerRecordExternalOrderScreen extends StatefulWidget {
  const OwnerRecordExternalOrderScreen({super.key});

  @override
  State<OwnerRecordExternalOrderScreen> createState() => _OwnerRecordExternalOrderScreenState();
}

class _OwnerRecordExternalOrderScreenState extends State<OwnerRecordExternalOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _source = 'zomato';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String? _selectedStall;
  List<String> _stalls = [];
  List<dynamic> _menuItems = [];
  Map<String, Map<String, dynamic>> _cart = {}; // foodId -> {name, qty, price}
  
  bool _loading = false;
  bool _fetchingMenu = false;
  bool _isInit = false;

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _fetchInitialData();
      _isInit = true;
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() => _fetchingMenu = true);
    try {
      final results = await Future.wait([
        ApiService.getAllOutlets(),
        ApiService.getAllFoods(),
      ]);
      
      setState(() {
        _stalls = (results[0] as List).map((o) => o['name'] as String).toList();
        if (_stalls.isNotEmpty) _selectedStall = _stalls.first;
        _menuItems = results[1] as List;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      setState(() => _fetchingMenu = false);
    }
  }

  void _updateTotal() {
    double total = 0;
    _cart.forEach((id, item) {
      total += (item['price'] as num) * (item['qty'] as int);
    });
    _amountController.text = total.toStringAsFixed(0);
  }

  void _addItem(dynamic food) {
    setState(() {
      final id = food['_id'] as String;
      if (_cart.containsKey(id)) {
        _cart[id]!['qty'] += 1;
      } else {
        _cart[id] = {
          'name': food['name'],
          'qty': 1,
          'price': food['price'],
        };
      }
      _updateTotal();
    });
  }

  void _removeItem(String id) {
    setState(() {
      if (_cart.containsKey(id)) {
        if (_cart[id]!['qty'] > 1) {
          _cart[id]!['qty'] -= 1;
        } else {
          _cart.remove(id);
        }
      }
      _updateTotal();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStall == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a stall")));
      return;
    }

    setState(() => _loading = true);
    try {
      final items = _cart.values.toList();
      
      await ApiService.recordExternalOrder({
        'source': _source,
        'total': double.parse(_amountController.text),
        'stall_name': _selectedStall,
        'location': 'External Platform',
        'items': items,
        'notes': _notesController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("External order recorded successfully")),
        );
        
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context, true);
        } else {
          // If we can't pop (it's a tab), just reset the screen state
          setState(() {
            _cart.clear();
            _amountController.clear();
            _notesController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text("Record External Order", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      ),
      body: _fetchingMenu 
        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Platform Source", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _sourceOption('zomato', 'Zomato', Colors.red),
                  const SizedBox(width: 12),
                  _sourceOption('swiggy', 'Swiggy', Colors.orange),
                  const SizedBox(width: 12),
                  _sourceOption('offline', 'Offline', Colors.blue),
                ],
              ),
              const SizedBox(height: 24),

              const Text("Select Items from Menu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _menuItems.isEmpty 
                  ? const Center(child: Text("No menu items available"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _menuItems.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _menuItems[index];
                        final id = item['_id'] as String;
                        final count = _cart[id]?['qty'] ?? 0;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                              IconButton(
                                icon: const Icon(Icons.info_outline, size: 18, color: primaryOrange),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => FoodDetailScreen(food: item, isAdmin: true)),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: Text("₹${item['price']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (count > 0) IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeItem(id),
                              ),
                              if (count > 0) Text("$count", style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () => _addItem(item),
                              ),
                            ],
                          ),
                        );
                      },
                  ),
              ),
              const SizedBox(height: 24),

              const Text("Order Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              
              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Total Amount (₹)", Icons.currency_rupee),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Stall Selection
              DropdownButtonFormField<String>(
                value: _selectedStall,
                decoration: _inputDecoration("Assign to Stall", Icons.storefront),
                items: _stalls.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedStall = v),
              ),
              const SizedBox(height: 16),

              // Notes / Items Info
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: _inputDecoration("Internal Notes (Optional)", Icons.note_alt_outlined),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save External Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption(String val, String label, Color color) {
    bool selected = _source == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _source = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : Colors.grey.shade200, width: 2),
          ),
          child: Column(
            children: [
              Icon(
                val == 'offline' ? Icons.point_of_sale_rounded : Icons.delivery_dining_rounded, 
                color: selected ? color : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(
                color: selected ? color : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              )),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryOrange, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryOrange)),
    );
  }
}
