import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "price": price,
      "quantity": quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json["name"],
      price: (json["price"] as num).toDouble(),
      quantity: json["quantity"],
    );
  }
}

class CartProvider extends ChangeNotifier {
  CartProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadCart();
  }

  List<CartItem> _items = [];
  Map<String, dynamic>? _selectedOutlet;
  String? _customerLocation;
  double _couponDiscount = 0;
  String? _appliedCouponCode;

  List<CartItem> get items => _items;
  Map<String, dynamic>? get selectedOutlet => _selectedOutlet;
  String? get customerLocation => _customerLocation;
  double get couponDiscount => _couponDiscount;
  String? get appliedCouponCode => _appliedCouponCode;

  void setSelectedOutlet(Map<String, dynamic>? outlet) {
    _selectedOutlet = outlet;
    notifyListeners();
  }

  void setCustomerLocation(String location) {
    _customerLocation = location;
    notifyListeners();
  }



  int get totalItems =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);

  /// 🚚 Delivery Fee Logic (Set to 0 as requested)
  double get deliveryFee => 0;

  int getQuantity(String name) {
    try {
      return items.firstWhere((i) => i.name == name).quantity;
    } catch (_) {
      return 0;
    }
  }

  void removeAllOfItem(String name) {
    items.removeWhere((i) => i.name == name);
    notifyListeners();
  }

  /// 💰 Final Payable Amount
  double get grandTotal => (totalPrice - _couponDiscount) + deliveryFee;

  void applyCoupon(String code, double discount) {
    _appliedCouponCode = code;
    _couponDiscount = discount;
    notifyListeners();
  }

  void clearCoupon() {
    _appliedCouponCode = null;
    _couponDiscount = 0;
    notifyListeners();
  }

  /// ➕ Add Item
  void addItem(String name, double price) {
    final index =
    _items.indexWhere((item) => item.name == name);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(name: name, price: price));
    }

    notifyListeners();
    saveCart();
  }

  /// ➖ Remove Item
  void removeItem(String name) {
    final index =
    _items.indexWhere((item) => item.name == name);

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    }

    notifyListeners();
    saveCart();
  }

  /// 🗑 Clear Entire Cart
  void clearCart() {
    _items.clear();
    notifyListeners();
    saveCart();
  }

  /// 💾 Save Cart to Local Storage
  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> cartData =
    _items.map((item) => jsonEncode(item.toJson())).toList();

    await prefs.setStringList("cart", cartData);
  }

  /// 🔄 Load Cart on App Start
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getStringList("cart");

    if (cartData != null) {
      _items = cartData
          .map((itemString) =>
          CartItem.fromJson(jsonDecode(itemString)))
          .toList();

      notifyListeners();
    }
  }
}