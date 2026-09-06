import 'dart:convert';

import 'package:flutter/material.dart';
import '/services/wishlist_service.dart';
import '/services/cart_service.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final CartService _cartService = CartService();
  
  void _removeItem(String targetId) {
    WishlistService.instance.removeFromWishlist(targetId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Item removed from Wishlist"),
        backgroundColor: Color(0xFF1E1E1E),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Map<String, dynamic> _buildCartVariantData(Map<String, dynamic> wishlistRawItem) {
    final String rawPriceStr = (wishlistRawItem["price"] ?? '220')
        .toString()
        .replaceAll(RegExp(r'[^0-9.]'), '');
    
    return {
      'type': wishlistRawItem["type"] ?? 'Loose',
      'weight': '1kg',
      'price': rawPriceStr.isNotEmpty ? rawPriceStr : '220',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: WishlistService.instance,
      builder: (context, wishlistItems, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                const Text(
                  "Wishlist",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF99417),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "${wishlistItems.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: wishlistItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: wishlistItems.length,
                  itemBuilder: (context, index) {
                    final item = wishlistItems[index];
                    return _buildWishlistCard(item, index, wishlistItems);
                  },
                ),
        );
      },
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item, int index, List<Map<String, dynamic>> currentList) {
    final String imagePath = item["image"] ?? '';
    final String targetId = item["id"] ?? '';
    final String name = item["name"] ?? 'Unnamed Item';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Container Frame
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath.startsWith('data:image') && imagePath.contains(';base64,')
                    ? Image.memory(
                        base64Decode(imagePath.split(';base64,')[1]),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildFallbackIcon(),
                      )
                    : imagePath.startsWith('http')
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _buildFallbackIcon(),
                          )
                        : Image.asset(
                            imagePath.isNotEmpty ? imagePath : 'assets/images/placeholder.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _buildFallbackIcon(),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            
            // Product Details & Actions Block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item["type"] ?? 'Standard',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Action Buttons Row moved inside Expanded column to prevent horizontal overflow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final Map<String, dynamic> cartReadyVariant = _buildCartVariantData(item);

                          _cartService.addToCart(
                            productId: targetId,
                            productName: name,
                            imagePath: imagePath,
                            variant: cartReadyVariant,
                            quantity: 1,
                          );

                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFF99417),
                              duration: const Duration(milliseconds: 900),
                              content: Text(
                                "Added $name to your cart!",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF99417),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Add to Cart",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFE57373),
                          size: 26,
                        ),
                        onPressed: () => _removeItem(targetId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Icon(Icons.image, color: Colors.grey.shade400, size: 30),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Your wishlist is empty",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}