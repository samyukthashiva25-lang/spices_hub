import 'dart:convert';
import 'package:flutter/material.dart';
import '/services/backend_service.dart'; 
import '/services/cart_service.dart';    
import '/services/wishlist_service.dart'; 

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final BackendService _backendService = BackendService();
  final CartService _cartService = CartService();
  
  // Base quantity matches reference mockup configurations
  int _quantityAmount = 10;

  Map<String, dynamic>? _productData;
  List<dynamic> _parsedVariants = [];
  Map<String, dynamic>? _selectedVariantMap;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProductDetailsPipeline();
    });
  }

  Future<void> _fetchProductDetailsPipeline() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic> || !args.containsKey('id')) {
      setState(() {
        _errorMessage = "Invalid or missing tracking payload arguments.";
        _isLoading = false;
      });
      return;
    }

    final String targetId = args['id'].toString();

    try {
      final List<dynamic> catalog = await _backendService.getAllSpices();
      final match = catalog.firstWhere(
        (element) => element['id'].toString() == targetId,
        orElse: () => null,
      );

      if (match != null) {
        _productData = Map<String, dynamic>.from(match);
        _extractVariantsData(_productData?['variant']);
      } else {
        _errorMessage = "Requested product item details could not be found.";
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception:", "").trim();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _extractVariantsData(String? rawVariantJson) {
    if (rawVariantJson == null || rawVariantJson.trim().isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(rawVariantJson);
      if (decoded is List) {
        _parsedVariants = decoded;
      } else if (decoded is Map) {
        _parsedVariants = [decoded];
      }
      if (_parsedVariants.isNotEmpty) {
        _selectedVariantMap = _parsedVariants.first;
      }
    } catch (e) {
      debugPrint("Variant parsing exception: $e");
    }
  }

  void _toggleWishlistStatus() {
    if (_productData == null) return;
    final String productId = _productData!['id']?.toString() ?? '';
    final bool isFav = WishlistService.instance.items.any((el) => el['id'] == productId);

    if (isFav) {
      WishlistService.instance.removeFromWishlist(productId);
    } else {
      final String variantLabel = _selectedVariantMap != null
          ? "${_selectedVariantMap!['type'] ?? 'Loose'}"
          : "Loose";

      final mapPayload = {
        'id': productId,
        'productname': _productData!['productname'] ?? 'Pumpkin Seeds',
        'price': _selectedVariantMap != null ? _selectedVariantMap!['price'] : '220',
        'images': _productData!['images'] ?? ''
      };
      WishlistService.instance.addToWishlist(mapPayload, variantLabel);
    }
  }

  double _calculateCurrentPrice() {
    if (_selectedVariantMap == null) return 0.0;
    final rawPrice = _selectedVariantMap!['price']?.toString() ?? '0';
    final parsed = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF99417)))
          : _errorMessage != null
              ? _buildErrorPlaceholder()
              : Stack(
                  children: [
                    _buildProductContentCanvas(),
                    _buildFloatingTopBarOverlay(),
                  ],
                ),
      bottomNavigationBar: _isLoading || _errorMessage != null ? null : _buildStickyActionFooter(),
    );
  }

  Widget _buildFloatingTopBarOverlay() {
    final String productId = _productData?['id']?.toString() ?? '';

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: WishlistService.instance,
            builder: (context, wishlist, child) {
              final bool isFav = wishlist.any((element) => element['id'] == productId);
              return CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                radius: 20,
                child: IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? const Color(0xFFF99417) : Colors.black54,
                    size: 20,
                  ),
                  onPressed: _toggleWishlistStatus,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductContentCanvas() {
    final String productName = _productData?['productname'] ?? 'Pumpkin Seeds';
    final String? imagePath = _productData?['images'];
    final double variantUnitPrice = _calculateCurrentPrice();
    final double computedTotal = variantUnitPrice * _quantityAmount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Product Image Container Frame
          Container(
            height: MediaQuery.of(context).size.height * 0.44,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFBFBFB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: imagePath != null && imagePath.isNotEmpty
                  ? Image.network(imagePath, fit: BoxFit.cover)
                  : Center(child: Icon(Icons.image, size: 80, color: Colors.grey.shade300)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Premium quality",
                  style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 10),
                
                // Static Star Ratings Row mapping reference
                const Row(
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFFF99417), size: 18),
                    SizedBox(width: 4),
                    Text(
                      "4.8  (248 orders)",
                      style: TextStyle(color: Color(0xFFF99417), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dynamic Variant Card Grid Layout Selector
                const Text(
                  "Select Variant",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _parsedVariants.map((variant) {
                    final bool isSelected = _selectedVariantMap == variant;
                    final String variantName = variant['type'] ?? 'Loose';
                    final String variantWeight = variant['weight'] ?? '1kg';
                    final String variantPrice = variant['price'] ?? '0';

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedVariantMap = variant),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF6EB) : const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFF99417) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$variantName (${variantWeight})",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFFF99417) : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹$variantPrice",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFFF99417) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Quantity Incremental Controls
                const Text(
                  "Quantity",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() { if (_quantityAmount > 1) _quantityAmount--; }),
                      child: Container(
                        width: 48,
                        height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.remove, size: 18, color: Colors.black),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "$_quantityAmount ",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _quantityAmount++),
                      child: Container(
                        width: 48,
                        height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFF99417), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.add, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Dynamic Pricing Ribbon Block Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      Text(
                        "₹ ${computedTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF99417)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStickyActionFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      // SafeArea removed here to prevent a dual-padding gap above your persistent bottom navigation bar
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7F7F7),
                foregroundColor: Colors.black,
                elevation: 0,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Buy Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_selectedVariantMap != null) {
                  _cartService.addToCart(
                    productId: _productData?['id']?.toString() ?? '',
                    productName: _productData?['productname'] ?? 'Pumpkin Seeds',
                    imagePath: _productData?['images'],
                    variant: _selectedVariantMap!,
                    quantity: _quantityAmount,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Successfully updated cart list!"), duration: Duration(seconds: 1)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF99417),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Add to Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _fetchProductDetailsPipeline(),
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }
}