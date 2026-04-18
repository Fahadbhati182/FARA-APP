import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'owner_create_update_worker_screen.dart';

class OwnerManageWorkersScreen extends StatefulWidget {
  const OwnerManageWorkersScreen({super.key});

  @override
  State<OwnerManageWorkersScreen> createState() =>
      _OwnerManageWorkersScreenState();
}

class _OwnerManageWorkersScreenState extends State<OwnerManageWorkersScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  bool _loading = true;
  List<Map<String, dynamic>> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllWorkers();

      if (mounted) {
        setState(() {
          // ensure data mapping matches the backend user model structure
          _workers = List<Map<String, dynamic>>.from(data.map((w) => {
            'id': w['_id'],
            'name': w['name'],
            'email': w['email'],
            'role': w['role'],
            'phone': w['phone'],
            'address': w['address'],
            'stall_name': w['assignedOutlets'] != null && (w['assignedOutlets'] as List).isNotEmpty
                ? (w['assignedOutlets'] as List).map((o) => o['name']).join(', ')
                : '',
            'assignedOutlets': w['assignedOutlets'],
            'raw_data': w,
          }));
        });
      }
    } catch (e) {
      debugPrint('Workers load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeWorker(Map<String, dynamic> worker) async {
    final confirmed = await _showConfirmDialog(worker);
    if (!confirmed) return;

    try {
      // Update role to 'removed' or delete — here we just change role
      await ApiService.removeWorker(worker['id'] as String);

      _loadWorkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${worker['name'] ?? 'Worker'} has been removed."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Remove worker error: $e');
    }
  }

  Future<bool> _showConfirmDialog(Map<String, dynamic> worker) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Worker",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to remove ${worker['name'] ?? 'this worker'}?\n\nThey will no longer be able to log in.",
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
            child: const Text("Remove",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showWorkerDetails(Map<String, dynamic> worker) {
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

            // Avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: lightOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: primaryOrange, size: 40),
            ),
            const SizedBox(height: 16),

            Text(
              worker['name'] ?? 'Worker',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            if (worker['stall_name'] != null &&
                (worker['stall_name'] as String).isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: primaryOrange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    worker['stall_name'] as String,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Text(
                  worker['email'] ?? '—',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Worker's order stats
            FutureBuilder(
              future: _fetchWorkerStats(worker['id'] as String),
              builder: (context, snapshot) {
                final stats =
                    snapshot.data as Map<String, dynamic>? ?? {};
                return Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: "Orders Handled",
                        value: "${stats['total'] ?? '—'}",
                        icon: Icons.receipt_long_rounded,
                        color: primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: "Accepted",
                        value: "${stats['accepted'] ?? '—'}",
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: "Rejected",
                        value: "${stats['rejected'] ?? '—'}",
                        icon: Icons.cancel_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerCreateUpdateWorkerScreen(
                            worker: worker,
                          ),
                        ),
                      ).then((_) => _loadWorkers());
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
                      _removeWorker(worker);
                    },
                    icon: const Icon(Icons.person_remove_rounded,
                        color: Colors.redAccent, size: 20),
                    label: const Text(
                      "Remove",
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

  Future<Map<String, dynamic>> _fetchWorkerStats(String workerId) async {
    try {
      // Mocked for now until backend worker stats API is added
      return {
        'total': 0,
        'accepted': 0,
        'rejected': 0,
      };
    } catch (_) {
      return {};
    }
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
          "Manage Workers",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadWorkers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerCreateUpdateWorkerScreen()),
          ).then((_) => _loadWorkers());
        },
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Worker",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: primaryOrange))
          : RefreshIndicator(
        color: primaryOrange,
        onRefresh: _loadWorkers,
        child: _workers.isEmpty
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
                    child: const Icon(Icons.people_outline_rounded,
                        color: primaryOrange, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No Workers Yet",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Workers will appear here after\nthey sign up with the Worker role.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _workers.length,
          itemBuilder: (context, i) {
            final worker = _workers[i];
            return GestureDetector(
              onTap: () => _showWorkerDetails(worker),
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
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: lightOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (worker['name'] as String? ??
                              'W')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                              color: primaryOrange,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
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
                            worker['name'] ?? 'Worker',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 3),
                          if (worker['stall_name'] != null &&
                              (worker['stall_name'] as String)
                                  .isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                    Icons.storefront_rounded,
                                    color: primaryOrange,
                                    size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  worker['stall_name'] as String,
                                  style: TextStyle(
                                      color:
                                      Colors.grey.shade500,
                                      fontSize: 12),
                                ),
                              ],
                            )
                          else
                            Text(
                              "No stall assigned",
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            worker['email'] ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis,
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
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
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

// ── Stat Box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}