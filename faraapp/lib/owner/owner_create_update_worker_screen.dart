import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerCreateUpdateWorkerScreen extends StatefulWidget {
  final Map<String, dynamic>? worker;

  const OwnerCreateUpdateWorkerScreen({super.key, this.worker});

  @override
  State<OwnerCreateUpdateWorkerScreen> createState() =>
      _OwnerCreateUpdateWorkerScreenState();
}

class _OwnerCreateUpdateWorkerScreenState
    extends State<OwnerCreateUpdateWorkerScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _fetchingOutlets = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<dynamic> _allOutlets = [];
  List<String> _selectedOutletIds = [];

  @override
  void initState() {
    super.initState();
    _loadOutlets();

    if (widget.worker != null) {
      final w = widget.worker!;
      // For updates, the data is stored in 'raw_data' from the screen mapping
      final data = w['raw_data'] ?? w;

      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';

      final assignedOutlets = data['assignedOutlets'] as List<dynamic>? ?? [];
      _selectedOutletIds = assignedOutlets.map((o) => o['_id']?.toString() ?? '').toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadOutlets() async {
    try {
      final outlets = await ApiService.getAllOutlets();
      if (mounted) {
        setState(() {
          _allOutlets = outlets;
          _fetchingOutlets = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load outlets: $e');
      if (mounted) {
        setState(() {
          _fetchingOutlets = false;
        });
      }
    }
  }

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'outlets': _selectedOutletIds,
      };

      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      if (widget.worker != null) {
        await ApiService.updateWorker(widget.worker!['id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Worker updated successfully')),
          );
        }
      } else {
        if (_passwordController.text.isEmpty) {
          throw Exception("Password is required for new workers");
        }
        data['password'] = _passwordController.text;
        
        await ApiService.addWorker(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Worker created successfully')),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.worker != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
        title: Text(
          isEdit ? "Update Worker" : "New Worker",
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
              _buildSectionTitle("Basic Details"),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: "Full Name",
                icon: Icons.person_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_rounded,
                validator: (val) => val == null || !val.contains('@')
                    ? "Valid email is required"
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: "Phone Number",
                keyboardType: TextInputType.phone,
                icon: Icons.phone_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? "Phone is required" : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _passwordController,
                label: isEdit ? "New Password (Optional)" : "Initial Password",
                obscureText: true,
                icon: Icons.lock_rounded,
                validator: (val) {
                  if (!isEdit && (val == null || val.isEmpty)) {
                    return "Password is required";
                  }
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Contact Details"),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressController,
                label: "Full Address",
                icon: Icons.home_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? "Address is required" : null,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle("Assign to Outlets"),
              const SizedBox(height: 12),
              _fetchingOutlets
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: primaryOrange),
                    ))
                  : _allOutlets.isEmpty
                      ? const Text("No outlets available. Please add outlets first.")
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
                            children: _allOutlets.map((o) {
                              final id = o['_id'].toString();
                              final isSelected = _selectedOutletIds.contains(id);
                              return CheckboxListTile(
                                activeColor: primaryOrange,
                                title: Text(o['name'] ?? 'Outlet',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(o['location']?['addressLine'] ?? ''),
                                value: isSelected,
                                onChanged: (bool? val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedOutletIds.add(id);
                                    } else {
                                      _selectedOutletIds.remove(id);
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
                  onPressed: _loading ? null : _saveWorker,
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
                          isEdit ? "Save Changes" : "Create Worker",
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
