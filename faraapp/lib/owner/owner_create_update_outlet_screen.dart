import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerCreateUpdateOutletScreen extends StatefulWidget {
  final Map<String, dynamic>? outlet;

  const OwnerCreateUpdateOutletScreen({super.key, this.outlet});

  @override
  State<OwnerCreateUpdateOutletScreen> createState() =>
      _OwnerCreateUpdateOutletScreenState();
}

class _OwnerCreateUpdateOutletScreenState
    extends State<OwnerCreateUpdateOutletScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _fetchingWorkers = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressLineController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();

  List<dynamic> _allWorkers = [];
  List<String> _selectedWorkerIds = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();

    if (widget.outlet != null) {
      final o = widget.outlet!;
      _nameController.text = o['name'] ?? '';
      _openingHoursController.text = o['openingHours'] ?? '';

      final loc = o['location'];
      if (loc != null) {
        _addressLineController.text = loc['addressLine'] ?? '';
        _cityController.text = loc['city'] ?? '';
        _stateController.text = loc['state'] ?? '';
        _pincodeController.text = loc['pincode'] ?? '';
      }

      final workers = o['workers'] as List<dynamic>? ?? [];
      _selectedWorkerIds = workers.map((w) => w['_id']?.toString() ?? '').toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    try {
      final workers = await ApiService.getAllWorkers();
      if (mounted) {
        setState(() {
          _allWorkers = workers;
          _fetchingWorkers = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load workers: $e');
      if (mounted) {
        setState(() {
          _fetchingWorkers = false;
        });
      }
    }
  }

  Future<void> _saveOutlet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'openingHours': _openingHoursController.text.trim(),
        'location': {
          'addressLine': _addressLineController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'workers': _selectedWorkerIds,
      };

      if (widget.outlet != null) {
        await ApiService.updateOutlet(widget.outlet!['_id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outlet updated successfully')),
          );
        }
      } else {
        await ApiService.createOutlet(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outlet created successfully')),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.outlet != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
        title: Text(
          isEdit ? "Update Outlet" : "Create Outlet",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Basic Information"),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: "Outlet Name",
                icon: Icons.storefront_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _openingHoursController,
                label: "Opening Hours (e.g. 9 AM - 10 PM)",
                icon: Icons.schedule_rounded,
                validator: (val) => val == null || val.isEmpty
                    ? "Opening hours are required"
                    : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Location Details"),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressLineController,
                label: "Address Line",
                icon: Icons.location_on_rounded,
                validator: (val) => val == null || val.isEmpty
                    ? "Address is required"
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: "City",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: "State",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _pincodeController,
                label: "Pincode",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Assign Workers"),
              const SizedBox(height: 12),
              _fetchingWorkers
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: primaryOrange),
                    ))
                  : _allWorkers.isEmpty
                      ? const Text("No workers available. Please add workers first.")
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            children: _allWorkers.map((w) {
                              final id = w['_id'].toString();
                              final isSelected = _selectedWorkerIds.contains(id);
                              return CheckboxListTile(
                                activeColor: primaryOrange,
                                title: Text(w['name'] ?? 'Worker',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(w['email'] ?? ''),
                                value: isSelected,
                                onChanged: (bool? val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedWorkerIds.add(id);
                                    } else {
                                      _selectedWorkerIds.remove(id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveOutlet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEdit ? "Save Changes" : "Create Outlet",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: icon != null ? Icon(icon, color: primaryOrange) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
