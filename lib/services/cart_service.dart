import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/services/session_manager.dart'; // Bridging active profile uid keys

class CartItem {
  final String productId;
  final String productName;
  final String? imagePath;
  final String variantWeight;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    this.imagePath,
    required this.variantWeight,
    required this.price,
    required this.quantity,
  });

  // Unique key targeting product and weight combo matching backend logic
  String get uniqueCartKey => "${productId}_$variantWeight";

  // Factory constructor parsing Java CartItem JSON structure safely
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productid'] ?? '',
      productName: json['productname'] ?? '',
      imagePath: json['imagepath'], 
      variantWeight: json['selectedweight'] ?? '1kg',
      price: (json['priceperunit'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1).toInt(),
    );
  }

  // Convert Dart models to matching backend lowercase payload keys
 // inside cart_service.dart -> CartItem Class

  // Convert Dart models to matching backend lowercase payload keys safely
Map<String, dynamic> toJson() {
    final bool isBase64 = imagePath?.startsWith("data:image") ?? false;

    return {
      "productId": productId,       // 💡 Changed to camelCase
      "productName": productName,   // 💡 Changed to camelCase
      "imagePath": isBase64 ? null : imagePath, // 💡 Changed to camelCase
      "selectedWeight": variantWeight, // 💡 Changed to camelCase
      "pricePerUnit": price.toInt(),  // 💡 Changed to camelCase
      "quantity": quantity,
    };
}
}

class CartService extends ChangeNotifier {
  // Singleton pattern architecture
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // Updated to 10.0.2.2 to allow Android Emulators to interface with your local Spring Boot host safely
  final String _baseUrl = "http://localhost:8080/api/cart";
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  double get totalCartAmount {
    double total = 0.0;
    _items.forEach((key, item) => total += item.price * item.quantity);
    return total;
  }

  int get totalItemCount {
    int count = 0;
    _items.forEach((key, item) => count += item.quantity);
    return count;
  }

  /// Helper to grab active vendor ID safely
  String _getLoggedUserUid() {
    final uid = SessionManager.instance.currentUserProfile?['uid'];
    if (uid == null) {
      throw Exception("Authentication session missing. Please re-authenticate.");
    }
    return uid.toString();
  }

  /// Shared synchronous pipeline helper to dispatch state updates directly to database documents
  Future<void> _syncQuantityWithBackend(CartItem item, int targetQuantity) async {
    try {
      final String uid = _getLoggedUserUid();
      await http.put(
        Uri.parse("$_baseUrl/$uid/update"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "uid": uid, // Explicit user context mapping validation check
          "productid": item.productId,
          "selectedweight": item.variantWeight,
          "quantity": targetQuantity
        }),
      );
    } catch (e) {
      debugPrint("Failed to sync item update state modification: $e");
    }
  }

  /// Initial entry point to sync local memory state directly from DB on initialization
  Future<void> fetchCartFromBackend() async {
    try {
      final String uid = _getLoggedUserUid();
      final response = await http.get(Uri.parse("$_baseUrl/$uid"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _items.clear();

        if (data['items'] != null) {
          for (var itemJson in data['items']) {
            final item = CartItem.fromJson(itemJson);
            _items[item.uniqueCartKey] = item;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching cart pipeline metadata snapshot: $e");
    }
  }

  /// Adds items and dispatches an append command downstream to Spring Boot
  Future<void> addToCart({
    required String productId,
    required String productName,
    required String? imagePath,
    required Map<String, dynamic> variant,
    required int quantity,
  }) async {
    final String weight = variant['weight'] ?? '1kg';
    final double price = double.tryParse(variant['price']?.toString() ?? '0') ?? 0.0;
    final String compositeKey = "${productId}_$weight";

    // 1. Optimistic UI update
    if (_items.containsKey(compositeKey)) {
      _items[compositeKey]!.quantity += quantity;
    } else {
      _items[compositeKey] = CartItem(
        productId: productId,
        productName: productName,
        imagePath: imagePath,
        variantWeight: weight,
        price: price,
        quantity: quantity,
      );
    }
    notifyListeners();

    // 2. Synchronize asynchronously with user document
    try {
      final String uid = _getLoggedUserUid();
      final CartItem targetedItem = _items[compositeKey]!;
      
      await http.post(
        Uri.parse("$_baseUrl/$uid/add"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(targetedItem.toJson()),
      );
    } catch (e) {
      debugPrint("Backend registration sync failed: $e");
    }
  }

  /// Alters specific item index quantity properties directly inside backend storage
  Future<void> updateQuantity(String uniqueKey, int newQuantity) async {
    if (!_items.containsKey(uniqueKey)) return;

    if (newQuantity <= 0) {
      await removeItem(uniqueKey);
      return;
    }

    // Local update execution
    final item = _items[uniqueKey]!;
    item.quantity = newQuantity;
    notifyListeners();

    // Transmit state update downstream with user verification tags
    await _syncQuantityWithBackend(item, newQuantity);
  }

  /// Wrapper link for programmatic dismissals
  Future<void> removeFromCart(String uniqueKey) async {
    await removeItem(uniqueKey);
  }

  /// Dispatches a target removal command sequence to alter array properties inside storage
  Future<void> removeItem(String uniqueKey) async {
    if (!_items.containsKey(uniqueKey)) return;

    final item = _items.remove(uniqueKey);
    notifyListeners();

    if (item != null) {
      // 0 quantity signals explicit row elimination in our Java backend architecture
      await _syncQuantityWithBackend(item, 0);
    }
  }

  /// Completely empties out the storage tracker layout schema values
  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();

    try {
      final String uid = _getLoggedUserUid();
      await http.delete(Uri.parse("$_baseUrl/$uid/clear"));
    } catch (e) {
      debugPrint("Failed to flush server data arrays pipeline: $e");
    }
  }
}