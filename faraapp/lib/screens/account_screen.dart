import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../screens/role_selection_screen.dart';
import '../services/api_service.dart';
import 'my_orders_screen.dart';

// ─────────────────────────────────────────────
//  MAIN ACCOUNT SCREEN
// ─────────────────────────────────────────────
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _profile = response['data'] ?? response;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await ApiService.logout();
    } catch (_) {}
    
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            (route) => false,
      );
    }
  }

  Widget _tile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? 'User';
    final email = _profile?['email'] ?? '';
    final avatarUrl = _profile?['profileImage'];

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : const AssetImage("assets/profile.jpg")
                as ImageProvider,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(email.isNotEmpty ? email : 'No email set'),
              trailing: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: _profile),
                    ),
                  );
                  _loadProfile(); // refresh after edit
                },
                child: const Text(
                  "Edit",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 20),

            _tile("My Orders", Icons.shopping_bag, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
            }),
            _tile("Delivery Addresses", Icons.location_on, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DeliveryAddressesScreen()));
            }),
            _tile("Support", Icons.support_agent, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()));
            }),
            _tile("Notifications", Icons.notifications, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            }),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => _logout(context),
              child: const Text("Log Out",style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EDIT PROFILE SCREEN
// ─────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;
  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?['name'] ?? widget.profile?['full_name'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile?['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      Uint8List? imageBytes;
      if (_imageFile != null) {
        imageBytes = await _imageFile!.readAsBytes();
      }

      await ApiService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        imageFile: imageBytes,
        fileName: _imageFile?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: _imageFile != null
                    ? (kIsWeb 
                        ? NetworkImage(_imageFile!.path) 
                        : FileImage(File(_imageFile!.path)) as ImageProvider)
                    : (widget.profile?['profileImage'] != null 
                        ? NetworkImage(widget.profile!['profileImage'])
                        : const AssetImage("assets/profile.jpg") as ImageProvider),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _imageFile = image);
                  }
                },
                child: const Text('Change Photo',
                    style: TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DELIVERY ADDRESSES SCREEN
// ─────────────────────────────────────────────
class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      final data = await ApiService.getAddresses();
      // Also get profile to know which is default
      final profile = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _addresses = List<Map<String, dynamic>>.from(data);
          _profile = profile['data'] ?? profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await ApiService.deleteAddress(id);
      _fetchAddresses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
    }
  }

  Future<void> _setDefault(String id) async {
    try {
      await ApiService.setDefaultAddress(id);
      _fetchAddresses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error setting default: $e")));
    }
  }

  void _openAddressForm([Map<String, dynamic>? address]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddressFormScreen(address: address)),
    );
    _fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final defaultAddressId = _profile?['defaultAddressId'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Delivery Addresses', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _openAddressForm(),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            const Text('No addresses saved yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Add an address to speed up your checkout',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _addresses.length,
        itemBuilder: (context, i) {
          final addr = _addresses[i];
          final addrId = addr['_id'] ?? addr['id'];
          final isDefault = addrId == defaultAddressId;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDefault ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _openAddressForm(addr),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDefault ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            addr['type'] == 'work'
                                ? Icons.work_rounded
                                : addr['type'] == 'home'
                                    ? Icons.home_rounded
                                    : Icons.location_on_rounded,
                            color: isDefault ? Colors.white : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['label'] ?? 'Address',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10),
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (v) {
                            if (v == 'edit') _openAddressForm(addr);
                            if (v == 'delete') _deleteAddress(addrId);
                            if (v == 'default') _setDefault(addrId);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit')),
                            if (!isDefault)
                              const PopupMenuItem(
                                  value: 'default',
                                  child: Text('Set as Default')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Address',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      addr['addressLine'] ?? addr['address_line'] ?? '',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${addr['city'] ?? ''}, ${addr['pincode'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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

// ─────────────────────────────────────────────
//  ADDRESS FORM SCREEN
// ─────────────────────────────────────────────
class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? address;
  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _lineCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _pincodeCtrl;
  String _type = 'home';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.address?['label'] ?? '');
    _lineCtrl = TextEditingController(text: widget.address?['addressLine'] ?? widget.address?['address_line'] ?? '');
    _cityCtrl = TextEditingController(text: widget.address?['city'] ?? '');
    _pincodeCtrl = TextEditingController(text: widget.address?['pincode'] ?? '');
    _type = widget.address?['type'] ?? 'home';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _lineCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = {
        'label': _labelCtrl.text.trim(),
        'addressLine': _lineCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'type': _type,
        'state': 'Default', // Backend expects state, added a default
      };

      if (widget.address != null) {
        final id = widget.address!['_id'] ?? widget.address!['id'];
        await ApiService.updateAddress(id, data);
      } else {
        await ApiService.createAddress(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ADDRESS TYPE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: ['home', 'work', 'other'].map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ),
                      selected: _type == t,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                          color: _type == t ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold),
                      onSelected: (_) => setState(() => _type = t),
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              const Text('LOCATION DETAILS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelCtrl,
                decoration: _dec('Label (e.g. Grandma\'s Home)', Icons.bookmark_outline_rounded),
                validator: (v) => v!.isEmpty ? 'Please enter a label' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lineCtrl,
                maxLines: 3,
                decoration: _dec('Complete Address', Icons.map_outlined),
                validator: (v) => v!.isEmpty ? 'Please enter address line' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: _dec('City', Icons.location_city_rounded),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Pincode', Icons.pin_drop_rounded),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.address == null ? 'Save Address' : 'Update Address',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUPPORT SCREEN
// ─────────────────────────────────────────────
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I track my order?', 'a': 'Go to My Orders to view real-time status and tracking of your orders.'},
      {'q': 'Can I cancel my order?', 'a': 'Yes, orders can be cancelled within 5 minutes of placing. Go to My Orders → Select Order → Cancel.'},
      {'q': 'How do refunds work?', 'a': 'Refunds are processed within 5–7 business days to your original payment method.'},
      {'q': 'How do I change my delivery address?', 'a': 'Go to Delivery Addresses to add or edit your saved addresses.'},
      {'q': 'What payment methods are accepted?', 'a': 'We accept UPI, credit/debit cards, and net banking.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact options
            Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    icon: Icons.phone,
                    label: 'Call Us',
                    subtitle: '9 AM – 9 PM',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Live Chat',
                    subtitle: 'Typically instant',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    subtitle: 'Within 24 hrs',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Frequently Asked Questions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            ...faqs.map((faq) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                iconColor: AppColors.primary,
                collapsedIconColor: Colors.grey,
                title: Text(faq['q']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(faq['a']!,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                  )
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard(
      {required this.icon,
        required this.label,
        required this.subtitle,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
            Text(subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NOTIFICATIONS SCREEN
// ─────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<String, bool> _prefs = {
    'order_updates': true,
    'promotions': false,
    'delivery': true,
    'payment': true,
    'app_updates': false,
  };
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // TODO: Implement ApiService.getNotificationPrefs()
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // TODO: Implement ApiService.updateNotificationPrefs(_prefs)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferences saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _toggle(String key, String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        activeColor: AppColors.primary,
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: _prefs[key] ?? false,
        onChanged: (v) => setState(() => _prefs[key] = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _toggle('order_updates', 'Order Updates',
                'Get notified about your order status', Icons.shopping_bag_outlined),
            _toggle('delivery', 'Delivery Alerts',
                'Know when your delivery is nearby', Icons.delivery_dining),
            _toggle('payment', 'Payment Notifications',
                'Confirmations and refund updates', Icons.payment),
            _toggle('promotions', 'Promotions & Offers',
                'Deals, discounts and special offers', Icons.local_offer_outlined),
            _toggle('app_updates', 'App Updates',
                'New features and improvements', Icons.system_update_outlined),
          ],
        ),
      ),
    );
  }
}