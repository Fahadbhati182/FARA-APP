import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'owner_create_update_outlet_screen.dart';

class OwnerManageOutletsScreen extends StatefulWidget {
  const OwnerManageOutletsScreen({super.key});

  @override
  State<OwnerManageOutletsScreen> createState() =>
      _OwnerManageOutletsScreenState();
}

class _OwnerManageOutletsScreenState extends State<OwnerManageOutletsScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  bool _loading = true;
  List<dynamic> _outlets = [];

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  Future<void> _loadOutlets() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllOutlets();
      if (mounted) {
        setState(() {
          _outlets = data;
        });
      }
    } catch (e) {
      debugPrint('Outlets load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteOutlet(Map<String, dynamic> outlet) async {
    final confirmed = await _showConfirmDialog(outlet);
    if (!confirmed) return;

    try {
      await ApiService.deleteOutlet(outlet['_id'] as String);
      _loadOutlets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${outlet['name'] ?? 'Outlet'} has been deleted."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Delete outlet error: $e');
    }
  }

  Future<bool> _showConfirmDialog(Map<String, dynamic> outlet) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("Delete Outlet",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              "Are you sure you want to delete ${outlet['name'] ?? 'this outlet'}?\n\nThis action cannot be undone.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Delete",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showOutletDetails(Map<String, dynamic> outlet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: lightOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: primaryOrange, size: 40),
            ),
            const SizedBox(height: 16),

            Text(
              outlet['name'] ?? 'Outlet',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Text(
                  outlet['openingHours'] ?? '—',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pin_drop_rounded,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Text(
                  outlet['location']?['addressLine'] ?? '—',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerCreateUpdateOutletScreen(
                            outlet: outlet,
                          ),
                        ),
                      ).then((_) => _loadOutlets());
                    },
                    icon: const Icon(Icons.edit_rounded,
                        color: primaryOrange, size: 20),
                    label: const Text(
                      "Edit",
                      style: TextStyle(
                          color: primaryOrange,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryOrange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteOutlet(outlet);
                    },
                    icon: const Icon(Icons.delete_rounded,
                        color: Colors.redAccent, size: 20),
                    label: const Text(
                      "Delete",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
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
        title: const Text(
          "Manage Outlets",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadOutlets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerCreateUpdateOutletScreen()),
          ).then((_) => _loadOutlets());
        },
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Outlet",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : RefreshIndicator(
              color: primaryOrange,
              onRefresh: _loadOutlets,
              child: _outlets.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: lightOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.store_outlined,
                                    color: primaryOrange, size: 48),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No Outlets Yet",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Create a new outlet to\nstart receiving orders.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _outlets.length,
                      itemBuilder: (context, i) {
                        final outlet = _outlets[i];
                        final workers = outlet['workers'] as List<dynamic>? ?? [];
                        
                        return GestureDetector(
                          onTap: () => _showOutletDetails(outlet),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: lightOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.storefront_rounded,
                                        color: primaryOrange, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        outlet['name'] ?? 'Outlet',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        outlet['location']?['addressLine'] ?? '',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(Icons.people_alt_rounded, 
                                            size: 13, 
                                            color: Colors.grey.shade400
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${workers.length} workers",
                                            style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Arrow
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 18,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
