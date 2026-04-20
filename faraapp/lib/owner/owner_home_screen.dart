import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../constants/colors.dart';
import 'owner_manage_workers_screen.dart';
import 'owner_manage_outlets_screen.dart';
import 'owner_manage_menu_screen.dart';
import 'owner_manage_coupons_screen.dart';
import 'owner_payments_audit_screen.dart';
import 'owner_record_external_order_screen.dart';
import '../screens/role_selection_screen.dart';
import '../widgets/loading_button.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  bool _loading = true;
  bool _syncing = false;
  int _totalOrdersToday = 0;
  double _totalRevenueToday = 0;
  int _pendingOrders = 0;
  int _totalWorkers = 0;
  int _totalOutlets = 0;
  int _totalMenuCount = 0;
  List<Map<String, dynamic>> _stallStats = [];
  List<Map<String, dynamic>> _recentOrders = [];
  Map<String, dynamic> _sourceStats = {
    'app': 0,
    'zomato': 0,
    'swiggy': 0,
    'offline': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getAdminDashboardStats();
      final data = res['data'] ?? res;
      
      debugPrint("DEBUG: Received Dashboard Data: $data");

      setState(() {
        _totalOrdersToday = (data['totalOrdersToday'] ?? 0);
        _totalRevenueToday = double.tryParse((data['totalRevenueToday'] ?? 0).toString()) ?? 0.0;
        _pendingOrders = (data['pendingOrders'] ?? 0);
        
        final rawStallStats = data['stallStats'] as List?;
        _stallStats = rawStallStats?.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        }).toList() ?? [];

        final rawRecentOrders = data['recentOrders'] as List?;
        _recentOrders = rawRecentOrders?.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        }).toList() ?? [];
        
        final rawSourceStats = data['sourceStats'] as Map?;
        if (rawSourceStats != null) {
          _sourceStats = Map<String, dynamic>.from(rawSourceStats);
        }
      });

      // Also get counts for workers, outlets, and menu items
      final workers = await ApiService.getAllWorkers();
      _totalWorkers = workers.length;

      final outlets = await ApiService.getAllOutlets();
      _totalOutlets = outlets.length;
      
      final foods = await ApiService.getAllFoods();
      _totalMenuCount = foods.length;

    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncData() async {
    setState(() => _syncing = true);
    // Simulate a complex sync operation
    await Future.delayed(const Duration(seconds: 2));
    await _loadDashboard();
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Dashboard data synced successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.grey),
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
              backgroundColor: primaryOrange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Logout",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const RoleSelectionScreen()),
              (_) => false,
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: RefreshIndicator(
        color: primaryOrange,
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            // ── App Bar with Logout ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              backgroundColor: primaryOrange,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                // Logout Button
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.logout_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text("Logout",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B2C), Color(0xFFE85A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 16, 120, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Business Dashboard",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _todayFormatted(),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child:
                    CircularProgressIndicator(color: primaryOrange)),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),

                  // ── Stats Row ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long_rounded,
                            label: "Orders Today",
                            value: "$_totalOrdersToday",
                            color: primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.currency_rupee_rounded,
                            label: "Revenue Today",
                            value:
                            "₹${_totalRevenueToday.toStringAsFixed(0)}",
                            color: const Color(0xFF2ECC71),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.hourglass_top_rounded,
                            label: "Pending",
                            value: "$_pendingOrders",
                            color: const Color(0xFFF39C12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Dashboard Actions ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Dashboard Actions",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Icon(Icons.bolt_rounded, color: primaryOrange.withOpacity(0.5), size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LoadingButton(
                            text: "Sync Performance Data",
                            icon: Icons.sync_rounded,
                            onPressed: _syncData,
                            isLoading: _syncing,
                            color: primaryOrange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Record External Order Button ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OwnerRecordExternalOrderScreen()),
                      ).then((refresh) {
                        if (refresh == true) _loadDashboard();
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: primaryOrange.withOpacity(0.5), width: 2, style: BorderStyle.solid),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: lightOrange,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.add_to_photos_rounded,
                                  color: primaryOrange, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Record External Order",
                                    style: TextStyle(
                                        color: primaryOrange,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Log Zomato, Swiggy, or Offline orders",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: primaryOrange, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // ── Source Breakdown ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Platform Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _BreakdownItem(label: "App", value: _sourceStats['app']?.toDouble() ?? 0, color: primaryOrange, icon: Icons.phone_android_rounded),
                              _BreakdownItem(label: "Zomato", value: _sourceStats['zomato']?.toDouble() ?? 0, color: Colors.red, icon: Icons.delivery_dining_rounded),
                              _BreakdownItem(label: "Swiggy", value: _sourceStats['swiggy']?.toDouble() ?? 0, color: Colors.orange, icon: Icons.delivery_dining_rounded),
                              _BreakdownItem(label: "Offline", value: _sourceStats['offline']?.toDouble() ?? 0, color: Colors.blue, icon: Icons.point_of_sale_rounded),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Manage Workers Card ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const OwnerManageWorkersScreen()),
                      ).then((_) => _loadDashboard()),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B2C),
                              Color(0xFFFF9A5C)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: primaryOrange.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.people_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Manage Workers",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "$_totalWorkers worker${_totalWorkers == 1 ? '' : 's'} registered",
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.8),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Manage Outlets Card ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const OwnerManageOutletsScreen()),
                      ).then((_) => _loadDashboard()),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE85A1A),
                              Color(0xFFFF7A45)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: primaryOrange.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Manage Outlets",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "$_totalOutlets outlet${_totalOutlets == 1 ? '' : 's'} registered",
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.8),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Manage Menu Card ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const OwnerManageMenuScreen()),
                      ).then((_) => _loadDashboard()),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF8C42),
                              Color(0xFFFF521B)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: primaryOrange.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.restaurant_menu_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Manage Menu",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "$_totalMenuCount item${_totalMenuCount == 1 ? '' : 's'} available",
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.8),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Manage Coupons Card ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const OwnerManageCouponsScreen()),
                      ).then((_) => _loadDashboard()),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE53E3E), // A distinct red/orange color
                              Color(0xFFFC8181)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: primaryOrange.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.local_offer_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Manage Coupons",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Create and manage active deals",
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.8),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Payments Audit Card ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OwnerPaymentsAuditScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2B6CB0), Color(0xFF4299E1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.history_edu_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Payments Audit",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Trace and audit all transactions",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Revenue by Stall ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Revenue by Stall",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        Text("Today",
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_stallStats.isEmpty)
                    _emptyCard("No stall data for today")
                  else
                    ...(_stallStats.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: _StallRevenueCard(
                        stallName: s['stall'] as String,
                        orders: s['orders'] as int,
                        revenue: s['revenue'] as double,
                        maxRevenue: (_stallStats.first['revenue']
                        as double)
                            .clamp(1, double.infinity),
                      ),
                    ))),

                  const SizedBox(height: 24),

                  // ── Recent Orders ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text("Recent Orders",
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  if (_recentOrders.isEmpty)
                    _emptyCard("No orders yet")
                  else
                    ...(_recentOrders.map((order) {
                      final items =
                          order['items'] as List<dynamic>? ?? [];
                      final itemSummary = items
                          .map((i) => "${i['name']} x${i['qty']}")
                          .join(", ");
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                    color: lightOrange,
                                    shape: BoxShape.circle),
                                child: const Icon(
                                    Icons.fastfood_rounded,
                                    color: primaryOrange,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['customer_name'] ??
                                          'Customer',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      itemSummary.isNotEmpty
                                          ? itemSummary
                                          : 'Items not listed',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "📍 ${order['location'] ?? 'Unknown'} • ${order['stall_name'] ?? ''}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${order['total']?.toStringAsFixed(0) ?? '0'}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                          order['status'] ??
                                              'pending')
                                          .withOpacity(0.12),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      (order['status'] ?? 'pending')
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: _statusColor(
                                            order['status'] ?? 'pending'),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _timeAgo(
                                        order['created_at'] as String?),
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    })),

                  const SizedBox(height: 24),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(msg,
              style:
              TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good Morning 🌅";
    if (h < 17) return "Good Afternoon ☀️";
    return "Good Evening 🌙";
  }

  String _todayFormatted() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return "${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}";
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}


IconData _getSourceIcon(String source) {
  switch (source) {
    case 'zomato': return Icons.delivery_dining_rounded;
    case 'swiggy': return Icons.delivery_dining_rounded;
    case 'offline': return Icons.point_of_sale_rounded;
    default: return Icons.phone_android_rounded;
  }
}

Color _getSourceColor(String source) {
  switch (source) {
    case 'zomato': return Colors.red;
    case 'swiggy': return Colors.orange;
    case 'offline': return Colors.blue;
    default: return const Color(0xFFFF6B2C);
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Stall Revenue Card ────────────────────────────────────────────────────────
class _StallRevenueCard extends StatelessWidget {
  final String stallName;
  final int orders;
  final double revenue;
  final double maxRevenue;

  const _StallRevenueCard({
    required this.stallName,
    required this.orders,
    required this.revenue,
    required this.maxRevenue,
  });

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF6B2C);
    final fraction = (revenue / maxRevenue).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: primaryOrange, size: 16),
                  const SizedBox(width: 6),
                  Text(stallName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              Text("₹${revenue.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primaryOrange)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade100,
              valueColor:
              const AlwaysStoppedAnimation<Color>(primaryOrange),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text("$orders orders",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}