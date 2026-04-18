import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  bool _loading = true;
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'This Week', 'This Month'];

  List<Map<String, dynamic>> _itemStats = [];
  List<Map<String, dynamic>> _locationStats = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getAdminAnalytics(_selectedPeriod);
      final data = response['data'] ?? {};
      
      setState(() {
        _itemStats = List<Map<String, dynamic>>.from(data['itemStats'] ?? []);
        _locationStats = List<Map<String, dynamic>>.from(data['locationStats'] ?? []);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Analytics load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = _itemStats.isEmpty
        ? 1
        : (_itemStats.first['qty'] as int).clamp(1, 99999);
    final maxOrders = _locationStats.isEmpty
        ? 1
        : (_locationStats.first['orders'] as int).clamp(1, 99999);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryOrange,
        elevation: 0,
        title: const Text(
          "Analytics",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Period Selector ────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _periods.map((p) {
                final sel = p == _selectedPeriod;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = p);
                    _loadAnalytics();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? primaryOrange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.grey.shade600,
                        fontWeight:
                        sel ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(color: primaryOrange))
                : RefreshIndicator(
              color: primaryOrange,
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── High Level Summary ──────────────────
                  _buildProfitSummary(),
                  const SizedBox(height: 24),

                  // ── Items Ordered Chart ──────────────────
                  _sectionTitle("🍱 Items Ordered", _selectedPeriod),
                  const SizedBox(height: 12),
                  if (_itemStats.isEmpty)
                    _emptyCard("No item data for this period")
                  else
                    Container(
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
                      child: Column(
                        children: _itemStats.asMap().entries.map((e) {
                          final idx = e.key;
                          final item = e.value;
                          final fraction = (item['qty'] as int) /
                              maxQty.toDouble();
                          final isBest = idx == 0;
                          final isWorst =
                              idx == _itemStats.length - 1 &&
                                  _itemStats.length > 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (isBest)
                                          const Text("🔥 ",
                                              style: TextStyle(
                                                  fontSize: 13)),
                                        if (isWorst)
                                          const Text("📉 ",
                                              style: TextStyle(
                                                  fontSize: 13)),
                                        Text(
                                          item['name'] as String,
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${item['qty']} orders",
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                        Text(
                                          "Revenue: ₹${(item['revenue'] as num).toDouble().toStringAsFixed(0)}",
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11),
                                        ),
                                        if (item['profit'] != null) ...[
                                          (() {
                                            final profit = (item['profit'] as num).toDouble();
                                            final isLoss = profit < 0;
                                            final revenue = (item['revenue'] as num).toDouble();
                                            final margin = revenue > 0 ? (profit / revenue * 100).toStringAsFixed(0) : "0";
                                            
                                            return Text(
                                              "${isLoss ? 'Loss' : 'Profit'}: ₹${profit.abs().toStringAsFixed(0)} ($margin%)",
                                              style: TextStyle(
                                                  color: isLoss ? Colors.redAccent : Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11),
                                            );
                                          })(),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    backgroundColor:
                                    Colors.grey.shade100,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      isBest
                                          ? primaryOrange
                                          : isWorst
                                          ? Colors.redAccent
                                          : const Color(
                                          0xFFFFAA7B),
                                    ),
                                    minHeight: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Best & Worst Summary ─────────────────
                  if (_itemStats.length >= 2) ...[
                    _sectionTitle(
                        "📊 Quick Summary", _selectedPeriod),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: "Best Seller",
                            name: _itemStats.first['name'] as String,
                            value:
                            "${_itemStats.first['qty']} orders",
                            color: Colors.green,
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: "Least Ordered",
                            name: _itemStats.last['name'] as String,
                            value:
                            "${_itemStats.last['qty']} orders",
                            color: Colors.redAccent,
                            icon: Icons.trending_down_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Traffic by Location ──────────────────
                  _sectionTitle(
                      "📍 Traffic by Location", _selectedPeriod),
                  const SizedBox(height: 12),
                  if (_locationStats.isEmpty)
                    _emptyCard("No location data for this period")
                  else
                    ...(_locationStats.map((loc) {
                      final fraction = (loc['orders'] as int) /
                          maxOrders.toDouble();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.location_on_rounded,
                                        color: primaryOrange,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 160,
                                      child: Text(
                                        loc['location'] as String,
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600,
                                            fontSize: 13),
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${loc['orders']} orders",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      "₹${(loc['revenue'] as num).toDouble().toStringAsFixed(0)}",
                                      style: TextStyle(
                                          color:
                                          Colors.grey.shade500,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: fraction,
                                backgroundColor:
                                Colors.grey.shade100,
                                valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(primaryOrange),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    })).toList(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: lightOrange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(sub,
              style: const TextStyle(
                  color: primaryOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildProfitSummary() {
    double totalRevenue = 0;
    double totalProfit = 0;
    
    for (var item in _itemStats) {
      totalRevenue += (item['revenue'] as num).toDouble();
      totalProfit += (item['profit'] as num?)?.toDouble() ?? 0;
    }

    // Add revenue from manual orders (Assuming 100% profit if cost unknown or just showing revenue)
    // Update: If it's "Other (Manual Entry)", we don't have a cost, so we'll just show profit as revenue 
    // or maybe a placeholder. For now, let's just sum what we have in itemStats.

    final margin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;
    final isTotalLoss = totalProfit < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          _buildSummaryMetric("Total Revenue", "₹${totalRevenue.toStringAsFixed(0)}", Colors.blue),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          _buildSummaryMetric(
            isTotalLoss ? "Estimated Loss" : "Estimated Profit", 
            "₹${totalProfit.abs().toStringAsFixed(0)}", 
            isTotalLoss ? Colors.redAccent : Colors.green
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          _buildSummaryMetric("Avg. Margin", "${margin.toStringAsFixed(0)}%", margin < 0 ? Colors.redAccent : Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(msg,
            style:
            TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String name;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.name,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}