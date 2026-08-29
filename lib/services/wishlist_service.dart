import 'package:flutter/material.dart';

/// Central state notifier engine broadcasting realtime mutations to your active layouts
class WishlistService extends ValueNotifier<List<Map<String, dynamic>>> {
  WishlistService._privateConstructor() : super([]);
  
  static final WishlistService instance = WishlistService._privateConstructor();

  /// Exposes the current read-only snapshot list matching standard collection abstractions
  List<Map<String, dynamic>> get items => value;

  void addToWishlist(Map<dynamic, dynamic> product, String variantDisplay) {
    final String targetId = product['id']?.toString() ?? '';
    
    // Check if item already exists to prevent duplicate entries
    final bool alreadyExists = value.any((element) => element['id'] == targetId);
    
    if (!alreadyExists) {
      // Create a shallow copy collection array to trigger ValueNotifier lifecycle hooks
      value = [
        ...value,
        {
          "id": targetId,
          "name": product['productname'] ?? 'Unnamed Spice',
          "type": variantDisplay,
          "price": product['price']?.toString().contains('₹') == true 
              ? (product['price']?.toString() ?? '₹0')
              : "₹${product['price'] ?? '0'}", 
          "image": product['images'] ?? '',
        }
      ];
    }
  }

  void removeFromWishlist(String id) {
    // Re-assign value array without the specified item to fire notifications safely
    value = value.where((element) => element['id'] != id).toList();
  }
}