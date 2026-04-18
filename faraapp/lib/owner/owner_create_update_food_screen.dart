import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class OwnerCreateUpdateFoodScreen extends StatefulWidget {
  final Map<String, dynamic>? food;

  const OwnerCreateUpdateFoodScreen({super.key, this.food});

  @override
  State<OwnerCreateUpdateFoodScreen> createState() =>
      _OwnerCreateUpdateFoodScreenState();
}

class _OwnerCreateUpdateFoodScreenState
    extends State<OwnerCreateUpdateFoodScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController(text: '15');
  final TextEditingController _cookTimeController = TextEditingController(text: '15');
  final TextEditingController _totalTimeController = TextEditingController(text: '30');
  
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();

  bool _isAvailable = true;
  bool _isVeg = true;
  bool _isBestSeller = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();

    if (widget.food != null) {
      final data = widget.food!['raw_data'] ?? widget.food!;
      
      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      
      _categoryController.text = data['category'] ?? '';
      
      _isAvailable = data['isAvailable'] ?? true;
      _isVeg = data['isVeg'] ?? true;
      _isBestSeller = data['isBestSeller'] ?? false;
      _existingImageUrl = data['image'];
      _prepTimeController.text = (data['prepTime'] ?? 15).toString();
      _cookTimeController.text = (data['cookTime'] ?? 15).toString();
      _totalTimeController.text = (data['totalTime'] ?? 30).toString();
      _costPriceController.text = (data['costPrice'] ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _totalTimeController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
      });
    }
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final int prepTime = int.tryParse(_prepTimeController.text) ?? 15;
      final int cookTime = int.tryParse(_cookTimeController.text) ?? 15;
      final int totalTime = int.tryParse(_totalTimeController.text) ?? 30;
      final double costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
      
      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': price,
        'category': _categoryController.text.trim(),
        'isAvailable': _isAvailable,
        'isVeg': _isVeg,
        'isBestSeller': _isBestSeller,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'totalTime': totalTime,
        'costPrice': costPrice,
      };

      if (widget.food != null) {
        await ApiService.updateFood(
          widget.food!['id'], 
          data, 
          imageBytes: _selectedImageBytes, 
          imageName: _selectedImageName
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item updated successfully')),
          );
        }
      } else {
        await ApiService.addFood(
          data, 
          imageBytes: _selectedImageBytes, 
          imageName: _selectedImageName
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item created successfully')),
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
    final isEdit = widget.food != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
        title: Text(
          isEdit ? "Update Menu Item" : "New Menu Item",
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
              // Image Picker Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryOrange.withOpacity(0.3), width: 2),
                      image: _selectedImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_selectedImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(_existingImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: (_selectedImageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: primaryOrange.withOpacity(0.8), size: 32),
                              const SizedBox(height: 8),
                              Text("Add Image", style: TextStyle(color: primaryOrange.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Item Details"),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: "Item Name",
                icon: Icons.fastfood_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descController,
                label: "Description",
                icon: Icons.description_rounded,
                maxLines: 3,
                validator: (val) =>
                    val == null || val.isEmpty ? "Description is required" : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: "Price (₹)",
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Price required";
                        if (double.tryParse(val) == null) return "Invalid format";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _categoryController,
                      label: "Category",
                      icon: Icons.category_rounded,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _costPriceController,
                label: "Cost Price (₹) - For Margin Tracking",
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Cost required";
                  if (double.tryParse(val) == null) return "Invalid format";
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _prepTimeController,
                      label: "Prep Time (min)",
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (int.tryParse(val) == null) return "Invalid";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _cookTimeController,
                      label: "Cook Time (min)",
                      icon: Icons.microwave_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (int.tryParse(val) == null) return "Invalid";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _totalTimeController,
                label: "Total Time (min)",
                icon: Icons.access_time_rounded,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  if (int.tryParse(val) == null) return "Invalid";
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle("Toggles"),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: primaryOrange,
                      title: const Text("Currently Available", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Show item on the active menu"),
                      value: _isAvailable,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeColor: Colors.green,
                      title: const Text("Vegetarian", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Labels item with a veg indicator"),
                      value: _isVeg,
                      onChanged: (val) => setState(() => _isVeg = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeColor: Colors.amber.shade600,
                      title: const Text("Best Seller", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Highlight item as a top choice"),
                      value: _isBestSeller,
                      onChanged: (val) => setState(() => _isBestSeller = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveFood,
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
                          isEdit ? "Save Changes" : "Create Menu Item",
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
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
