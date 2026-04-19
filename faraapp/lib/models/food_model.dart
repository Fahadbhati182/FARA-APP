class Food {
  final String? id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool isVeg;
  final bool isBestSeller;

  Food({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.isVeg,
    this.isBestSeller = false,
  });
}

final List<Food> allFoods = [
  Food(
    name: "Steamed Chicken Momos",
    description: "Juicy steamed dumplings",
    price: 149,
    image: "assets/chicken_steam_momos.jpg",
    category: "Steamed",
    isVeg: false,
  ),
  Food(
    name: "Fried Veg Momos",
    description: "Crispy & spicy",
    price: 129,
    image: "assets/fried_veg_momos.jpg",
    category: "Fried",
    isVeg: true,
  ),
  Food(
    name: "Momo Combo Box",
    description: "6 momos + coke",
    price: 199,
    image: "assets/momo_combo _box.jpg",
    category: "Combos",
    isVeg: false,
  ),
];