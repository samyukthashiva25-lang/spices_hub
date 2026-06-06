import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String productName;
  final String? imagePath;
  final String variantType;
  final String variantWeight;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    this.imagePath,
    required this.variantType,
    required this.variantWeight,
    required this.price,
    required this.quantity,
  });

  // Generates a composite key so different variants of the same product sit as separate rows!
  String get uniqueCartKey => "${productId}_${variantType}_$variantWeight";
}

class CartService extends ChangeNotifier {
  // Singleton pattern for simple state management across screens
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  void addToCart({
    required String productId,
    required String productName,
    required String? imagePath,
    required Map<String, dynamic> variant,
    required int quantity,
  }) {
    final String type = variant['type'] ?? 'Standard';
    final String weight = variant['weight'] ?? '';
    // Safely parse price values from dynamic types
    final double price = double.tryParse(variant['price']?.toString() ?? '0') ?? 0.0;

    final String compositeKey = "${productId}_${type}_$weight";

    if (_items.containsKey(compositeKey)) {
      _items[compositeKey]!.quantity += quantity;
    } else {
      _items[compositeKey] = CartItem(
        productId: productId,
        productName: productName,
        imagePath: imagePath,
        variantType: type,
        variantWeight: weight,
        price: price,
        quantity: quantity,
      );
    }
    notifyListeners();
  }
  void removeItem(String uniqueKey) {
    if (_items.containsKey(uniqueKey)) {
      _items.remove(uniqueKey);
      notifyListeners(); // Tells the CartPage to instantly rebuild itself
    }
  }
}