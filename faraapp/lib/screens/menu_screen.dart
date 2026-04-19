import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../widgets/menu_card.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'food_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  /// Pass "steamed", "fried", "combo", or null for all
  final String? categoryFilter;

  /// Optional: auto-scroll to a specific food item by name
  final String? scrollToItem;

  const MenuScreen({super.key, this.categoryFilter, this.scrollToItem});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String searchQuery = "";
  bool? isVegFilter;
  bool isBestSellerFilter = false;
  bool sortLowToHigh = false;
  late String? activeCategory;

  bool _loading = true;
  List<Food> _fetchedFoods = [];
  List<String> _favoriteIds = [];

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    activeCategory = widget.categoryFilter;

    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllFoods();
      if (mounted) {
        setState(() {
          _fetchedFoods = data
              // Usually customers only see available food
              .where((item) => item['isAvailable'] == true) 
              .map((item) => Food(
                    id: item['_id'] ?? item['id'],
                    name: item['name'] ?? '',
                    description: item['description'] ?? '',
                    price: (item['price'] ?? 0).toDouble(),
                    image: (item['image'] != null && item['image'].toString().isNotEmpty)
                        ? item['image']
                        : 'assets/app_logo.jpg',
                    category: item['category'] ?? '',
                    isVeg: item['isVeg'] ?? true,
                    isBestSeller: item['isBestSeller'] == true,
                  ))
              .toList();
        });

        if (widget.scrollToItem != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToItem(widget.scrollToItem!);
          });
        }
      }
      
      // Fetch favorites
      try {
        final favorites = await ApiService.getFavorites();
        if (mounted) {
          setState(() {
            _favoriteIds = favorites.map((f) => f['_id'].toString()).toList();
          });
        }
      } catch (e) {
        debugPrint('Error fetching favorites: $e');
      }
    } catch (e) {
      debugPrint('Error fetching menu: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToItem(String itemName) {
    final key = _itemKeys[itemName];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  String _categoryLabel(String? cat) {
    switch (cat) {
      case 'steamed':
        return '🥟 Steamed Momos';
      case 'fried':
        return '🍟 Fried Momos';
      case 'kurkure':
        return '🌶️ Kurkure Momos';
      case 'pizza':
        return '🍕 Pizza';
      case 'kulhad':
        return '☕ Kulhad Specials';
      default:
        return 'Our Menu';
    }
  }

  List<Food> _getFilteredFoods() {
    List<Food> foods = _fetchedFoods.where((food) {
      final matchesSearch =
      food.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesVeg =
      isVegFilter == null ? true : food.isVeg == isVegFilter;

      final matchesCategory = activeCategory == null
          ? true
          : food.name.toLowerCase().contains(activeCategory!.toLowerCase()) ||
            food.category?.toLowerCase() == activeCategory!.toLowerCase();

      final matchesBestSeller = !isBestSellerFilter ? true : food.isBestSeller;

      return matchesSearch && matchesVeg && matchesCategory && matchesBestSeller;
    }).toList();

    if (sortLowToHigh) {
      foods.sort((a, b) => a.price.compareTo(b.price));
    }

    return foods;
  }

  Widget build(BuildContext context) {
    final foods = _getFilteredFoods();

    for (final food in _fetchedFoods) {
      _itemKeys.putIfAbsent(food.name, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A1A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _categoryLabel(activeCategory),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1A1A1A)),
            onPressed: _openSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category Pills ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryPill(null, "All"),
                  _categoryPill('steamed', "🥟 Steamed"),
                  _categoryPill('fried', "🍟 Fried"),
                  _categoryPill('kurkure', "🌶️ Kurkure"),
                  _categoryPill('pizza', "🍕 Pizza"),
                  _categoryPill('kulhad', "☕ Kulhad"),
                ],
              ),
            ),
          ),

          // ── Filter Chips ────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    label: "All",
                    selected: isVegFilter == null && !isBestSellerFilter,
                    onSelected: (v) => setState(() {
                      isVegFilter = null;
                      isBestSellerFilter = false;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: "🥦 Veg",
                    selected: isVegFilter == true,
                    onSelected: (v) =>
                        setState(() => isVegFilter = v ? true : null),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: "🍗 Non-Veg",
                    selected: isVegFilter == false,
                    onSelected: (v) =>
                        setState(() => isVegFilter = v ? false : null),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: "🔥 Best Seller",
                    selected: isBestSellerFilter,
                    onSelected: (v) => setState(() => isBestSellerFilter = v),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: "↑ Price",
                    selected: sortLowToHigh,
                    onSelected: (v) => setState(() => sortLowToHigh = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ── Food List ───────────────────────────────────────────
          Expanded(
            child: _loading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : foods.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No items found",
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return GestureDetector(
                  onTap: () {
                    // We need to find the raw food map for this item or construct it
                    // because MenuScreen converts to a Food model.
                    // Let's pass the food model if possible, or adjust FoodDetailScreen.
                    // Actually, better to pass what the API returned.
                    final originalItem = _fetchedFoods.firstWhere((f) => f.name == food.name);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(
                          food: {
                            'id': originalItem.id,
                            '_id': originalItem.id,
                            'name': originalItem.name,
                            'description': originalItem.description,
                            'price': originalItem.price,
                            'image': originalItem.image,
                            'category': originalItem.category,
                            'isVeg': originalItem.isVeg,
                            'isBestSeller': originalItem.isBestSeller,
                            'isAvailable': true,
                          },
                          isAdmin: false,
                        ),
                      ),
                    );
                  },
                  child: MenuCard(
                    key: _itemKeys[food.name],
                    image: food.image,
                    title: food.name,
                    subtitle: food.description,
                    price: food.price,
                    highlight: food.name == widget.scrollToItem,
                    foodId: food.id,
                    initialIsFavorite: _favoriteIds.contains(food.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryPill(String? value, String label) {
    final isSelected = activeCategory == value;
    return GestureDetector(
      onTap: () => setState(() => activeCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF2F2F2),
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
              ? AppColors.primary.withOpacity(0.12)
              : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Search Food"),
        content: TextField(
          autofocus: true,
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: InputDecoration(
            hintText: "e.g. chicken, fried...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            Text("Close", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}