import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'owner_create_update_food_screen.dart';
import '../screens/food_detail_screen.dart';

class OwnerManageMenuScreen extends StatefulWidget {
  const OwnerManageMenuScreen({super.key});

  @override
  State<OwnerManageMenuScreen> createState() => _OwnerManageMenuScreenState();
}

class _OwnerManageMenuScreenState extends State<OwnerManageMenuScreen> {
  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  bool _loading = true;
  List<Map<String, dynamic>> _foods = [];
  bool? _isVegFilter;
  String? _categoryFilter;

  List<Map<String, dynamic>> get _filteredFoods {
    return _foods.where((food) {
      if (_isVegFilter != null && food['isVeg'] != _isVegFilter) {
        return false;
      }
      if (_categoryFilter != null && food['category'] != _categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllFoods();

      if (mounted) {
        setState(() {
          _foods = List<Map<String, dynamic>>.from(data.map((f) => {
                'id': f['_id'],
                'name': f['name'],
                'description': f['description'],
                'price': f['price'],
                'category': f['category'],
                'isAvailable': f['isAvailable'],
                'isVeg': f['isVeg'],
                'raw_data': f,
              }));
        });
      }
    } catch (e) {
      debugPrint('Foods load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFood(Map<String, dynamic> food) async {
    final confirmed = await _showConfirmDialog(food);
    if (!confirmed) return;

    try {
      await ApiService.deleteFood(food['id'] as String);
      _loadFoods();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${food['name']} has been removed."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Remove food error: $e');
    }
  }

  Future<bool> _showConfirmDialog(Map<String, dynamic> food) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Remove Menu Item",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              "Are you sure you want to remove ${food['name']}?\n\nIt will be permanently deleted.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Remove", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showFoodDetails(Map<String, dynamic> food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(food: food, isAdmin: true),
      ),
    ).then((_) => _loadFoods());
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
          "Manage Menu",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadFoods,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OwnerCreateUpdateFoodScreen()),
          ).then((_) => _loadFoods());
        },
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Item",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilters(),
                Expanded(
                  child: RefreshIndicator(
                    color: primaryOrange,
                    onRefresh: _loadFoods,
                    child: _filteredFoods.isEmpty
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
                                child: const Icon(Icons.restaurant_menu_rounded,
                                    color: primaryOrange, size: 48),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No Menu Items Yet",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Add some delicious food to your\nmenu to attract customers.",
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
                      itemCount: _filteredFoods.length,
                      itemBuilder: (context, i) {
                        final food = _filteredFoods[i];
                        final isVeg = food['isVeg'] ?? true;
                        
                        return GestureDetector(
                          onTap: () => _showFoodDetails(food),
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
                                // Picture placeholder
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: lightOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.fastfood_rounded, color: primaryOrange.withOpacity(0.5), size: 28),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              food['name'] ?? 'Item',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: isVeg ? Colors.green : Colors.red),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Icon(Icons.circle, color: isVeg ? Colors.green : Colors.red, size: 8),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        food['category'] ?? '',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "₹${food['price']?.toStringAsFixed(2) ?? '0.00'}",
                                        style: const TextStyle(
                                            color: primaryOrange,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15),
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
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    // Determine available categories based on Veg/Non-Veg filter
    final availableCategories = _foods
        .where((f) => _isVegFilter == null || f['isVeg'] == _isVegFilter)
        .map((f) => (f['category'] as String?) ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Veg / Non-Veg
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _filterChip(
                label: "All",
                selected: _isVegFilter == null,
                onSelected: (_) => setState(() {
                  _isVegFilter = null;
                  _categoryFilter = null;
                }),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: "🥦 Veg",
                selected: _isVegFilter == true,
                onSelected: (_) => setState(() {
                  _isVegFilter = true;
                  _categoryFilter = null;
                }),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: "🍗 Non-Veg",
                selected: _isVegFilter == false,
                onSelected: (_) => setState(() {
                  _isVegFilter = false;
                  _categoryFilter = null;
                }),
              ),
            ],
          ),
        ),
        
        // Category Selection
        if (availableCategories.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _categoryPill(null, "All Categories"),
                  ...availableCategories.map((c) => _categoryPill(c, c)).toList(),
                ]
              ),
            ),
          ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? primaryOrange.withOpacity(0.12)
              : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primaryOrange : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? primaryOrange : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _categoryPill(String? value, String label) {
    final isSelected = _categoryFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _categoryFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
