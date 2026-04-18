import 'package:flutter/material.dart';
import '../owner/owner_create_update_food_screen.dart';

class FoodDetailScreen extends StatelessWidget {
  final Map<String, dynamic> food;
  final bool isAdmin;

  const FoodDetailScreen({
    super.key,
    required this.food,
    this.isAdmin = false,
  });

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color lightOrange = Color(0xFFFFF3EE);

  @override
  Widget build(BuildContext context) {
    // Determine the raw data - handling both Map and Model if necessary
    final Map<String, dynamic> raw = _extractRawData(food);
    
    final String name = raw['name'] ?? 'Item';
    final String description = raw['description'] ?? 'No description provided.';
    final double price = (raw['price'] as num?)?.toDouble() ?? 0.0;
    final double costPrice = (raw['costPrice'] as num?)?.toDouble() ?? 0.0;
    final String category = raw['category'] ?? 'General';
    final String? imageUrl = raw['image'];
    final bool isVeg = raw['isVeg'] ?? true;
    final bool isBestSeller = raw['isBestSeller'] ?? false;
    final bool isAvailable = raw['isAvailable'] ?? true;
    final int prepTime = raw['prepTime'] ?? 15;
    final int cookTime = raw['cookTime'] ?? 15;
    
    final double profit = price - costPrice;
    final double margin = price > 0 ? (profit / price * 100) : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, imageUrl, name, isVeg),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTitleSection(name, category)),
                        _buildPriceTag(price),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Badges Row
                    _buildBadges(isBestSeller, isVeg, isAvailable),
                    const SizedBox(height: 32),

                    // Stats Row
                    _buildStatsRow(prepTime, cookTime),
                    const SizedBox(height: 32),

                    // Description Section
                    const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 12),
                    Text(description, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6, letterSpacing: 0.3)),
                    const SizedBox(height: 32),

                    // Business Secrets Section (Admin Only)
                    if (isAdmin) _buildAdminSection(context, costPrice, profit, margin),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _extractRawData(dynamic foodData) {
    if (foodData is Map<String, dynamic>) {
      return foodData['raw_data'] ?? foodData;
    }
    // Handle other types if needed, but for now we expect a Map
    return {};
  }

  Widget _buildTitleSection(String name, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.toUpperCase(), style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
      ],
    );
  }

  Widget _buildPriceTag(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primaryOrange,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primaryOrange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text("₹${price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
    );
  }

  Widget _buildBadges(bool isBestSeller, bool isVeg, bool isAvailable) {
    return Row(
      children: [
        if (isBestSeller) _buildBadge("Best Seller", Colors.amber, Icons.star_rounded),
        if (isBestSeller) const SizedBox(width: 8),
        _buildBadge(isVeg ? "Veg" : "Non-Veg", isVeg ? Colors.green : Colors.red, Icons.circle),
        const SizedBox(width: 8),
        if (isAvailable) _buildBadge("Available", Colors.blue, Icons.check_circle_rounded)
        else _buildBadge("Sold Out", Colors.grey, Icons.cancel_rounded),
      ],
    );
  }

  Widget _buildStatsRow(int prepTime, int cookTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard("Prep Time", "$prepTime min", Icons.timer_outlined),
        _buildStatCard("Cook Time", "$cookTime min", Icons.microwave_outlined),
        _buildStatCard("Total", "${prepTime + cookTime} min", Icons.access_time_rounded),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context, double costPrice, double profit, double margin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 24),
        const Text("Business Insights (Owner Only)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              _buildAdminStat("Cost Price", "₹${costPrice.toStringAsFixed(0)}", Colors.grey.shade700),
              _buildAdminStat("Profit", "₹${profit.toStringAsFixed(0)}", profit < 0 ? Colors.red : Colors.green),
              _buildAdminStat("Margin", "${margin.toStringAsFixed(0)}%", margin < 0 ? Colors.red : Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OwnerCreateUpdateFoodScreen(food: food)),
              );
            },
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            label: const Text("Edit Item Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String? imageUrl, String name, bool isVeg) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryOrange,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              imageUrl.startsWith('http') 
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Image.asset(imageUrl, fit: BoxFit.cover)
            else
              Container(
                color: lightOrange,
                child: Center(child: Icon(Icons.restaurant_menu_rounded, color: primaryOrange.withOpacity(0.5), size: 120)),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black26, Colors.black54],
                  stops: [0.6, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: primaryOrange, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildAdminStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
