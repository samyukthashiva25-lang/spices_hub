import 'package:flutter/material.dart';
import 'dart:convert'; // Required for base64Decode and jsonDecode handling
import '/services/backend_service.dart';
import '/services/wishlist_service.dart'; // Synergistic sync layer
import '/services/cart_service.dart'; // Action pipeline processor

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final BackendService _backendService = BackendService();
  final CartService _cartService = CartService();

  // Backend state storage repositories
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];

  // Runtime context constraints
  String _searchQuery = "";
  String _selectedCategory = "";

  bool _isLoading = true;
  String? _errorMessage;

  // Unified category registry mirroring your design specifications exactly
  final List<Map<String, String>> _categories = [
    {"name": "Spices", "icon": "🌶️"},
    {"name": "Nuts", "icon": "🥜"},
    {"name": "Seeds", "icon": "🌱"},
    {"name": "Dry Fruits", "icon": "🍇"},
    {"name": "Herbs", "icon": "🌿"},
    {"name": "Blends", "icon": "🍲"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInventoryData();
  }

  /// Master compilation fetch sequence tied safely to the global state engine lifecycle
  Future<void> _fetchInventoryData() async {
    try {
      final List<dynamic> data = await _backendService.getAllSpices();

      if (!mounted) return;
      setState(() {
        // Enforces the core commercial validation rule down the dataset context
        _allProducts = data.where((product) {
          final bool isPublished = product['ispublished'] ?? false;
          return isPublished == true;
        }).toList();

        _filteredProducts = List.from(_allProducts);
        _isLoading = false;
        _errorMessage = null;
      });

      _applyFilters();
    } catch (e) {
      debugPrint("Product catalog processing error context: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "").trim();
        _isLoading = false;
      });
    }
  }

  /// Atomic application engine evaluating text configurations and category definitions sequentially
  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // 1. Evaluate Explicit Category Match Matrix
        if (_selectedCategory.isNotEmpty) {
          final String backendCat = (product['category'] ?? '').toString().toLowerCase().trim();
          final String targetCat = _selectedCategory.toLowerCase().trim();
          if (backendCat != targetCat) return false;
        }

        // 2. Evaluate Functional Search Query Target Sequences
        if (_searchQuery.isNotEmpty) {
          final String productName = (product['productname'] ?? '').toString().toLowerCase();
          final String tags = (product['tags'] ?? '').toString().toLowerCase();
          final String targetQuery = _searchQuery.toLowerCase().trim();
          if (!productName.contains(targetQuery) && !tags.contains(targetQuery)) return false;
        }

        return true;
      }).toList();
    });
  }

  void _selectCategoryFilter(String categoryName) {
    _selectedCategory = (_selectedCategory == categoryName) ? "" : categoryName;
    _applyFilters();
  }

  void _clearCategoryFilter() {
    _selectedCategory = "";
    _applyFilters();
  }

  /// Processes and parses highly nested structural catalog variant JSON components cleanly
  String _parseVariantType(String? variantRawJson) {
    if (variantRawJson == null || variantRawJson.trim().isEmpty) return 'Standard';
    try {
      final dynamic decoded = jsonDecode(variantRawJson);
      if (decoded is List && decoded.isNotEmpty) {
        List<String> types = [];
        for (var item in decoded) {
          if (item is Map && item.containsKey('weight') && item['weight'] != null) {
            final String typeStr = item['weight'].toString().trim();
            if (typeStr.isNotEmpty && !types.contains(typeStr)) types.add(typeStr);
          }
        }
        return types.isNotEmpty ? types.join(', ') : 'Standard';
      } else if (decoded is Map && decoded.containsKey('weight')) {
        return decoded['weight'] ?? 'Standard';
      }
    } catch (e) {
      debugPrint("Exception caught processing data mapping constraints: $e");
    }
    return 'Standard';
  }

  /// Resolves active underlying objects directly matching definitions targeted by consumer pipelines
  Map<String, dynamic> _extractDefaultVariantStructure(Map<dynamic, dynamic> product) {
    Map<String, dynamic> fallbackVariant = {
      'type': 'Loose',
      'weight': '1kg',
      'price': product['price']?.toString() ?? '220',
    };

    final String? variantJson = product['variant']?.toString();
    if (variantJson != null && variantJson.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(variantJson);
        if (decoded is List && decoded.isNotEmpty) {
          return Map<String, dynamic>.from(decoded.first);
        } else if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint("Error extracting fallback configurations: $e");
      }
    }
    return fallbackVariant;
  }

  /// Formats server tracking markers by stripping empty arrays safely
  String? _cleanBadgeText(String? tagText) {
    if (tagText == null || tagText.trim().isEmpty || tagText.contains('{') || tagText.contains('[')) {
      return null;
    }
    return tagText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
        title: const Text(
          "All Products",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF99417)))
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildHorizontalCategoryFilterBar(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFF99417),
                        onRefresh: () async {
                          setState(() => _isLoading = true);
                          await _fetchInventoryData();
                        },
                        child: _buildProductGrid(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: TextField(
        onChanged: (value) {
          _searchQuery = value;
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: "Search products in catalog...",
          prefixIcon: const Icon(Icons.search_outlined, color: Colors.grey, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _searchQuery = "";
                    });
                    _applyFilters();
                  },
                )
              : null,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF99417)),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCategoryFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final String label = cat["name"]!;
              final String emoji = cat["icon"]!;
              final isSelected = _selectedCategory == label;

              return GestureDetector(
                onTap: () => _selectCategoryFilter(label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF0E0) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFF99417) : const Color(0xFFEEEEEE),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? const Color(0xFFF99417) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedCategory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Row(
              children: [
                Text(
                  "Showing matches for: '$_selectedCategory'",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _clearCategoryFilter,
                  child: const Text(
                    "(Clear)",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              ],
            ),
          )
      ],
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                "No products match.",
                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final Map<String, dynamic> product = Map<String, dynamic>.from(_filteredProducts[index]);

        final String name = product['productname'] ?? 'Unnamed Spice';
        final String? imagePath = product['images'];
        final String parsedVariantDisplay = _parseVariantType(product['variant']);
        final String? badgeText = _cleanBadgeText(product['tags']);

        return _buildProductItemCard(
          product: product,
          name: name,
          imagePath: imagePath,
          variantDisplay: parsedVariantDisplay,
          badge: badgeText,
          productId: product['id']?.toString() ?? '',
        );
      },
    );
  }

  Widget _buildProductItemCard({
    required Map<String, dynamic> product,
    required String name,
    required String? imagePath,
    required String variantDisplay,
    required String? badge,
    required String productId,
  }) {
    final bool isFavorite = WishlistService.instance.items.any((item) => item['id'] == productId);

    return GestureDetector(
      onTap: () {
        if (productId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/product_detail_page',
            arguments: {'id': productId},
          );
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: imagePath != null && imagePath.trim().isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: imagePath.startsWith('data:image') && imagePath.contains(';base64,')
                                  ? Image.memory(
                                      base64Decode(imagePath.split(';base64,')[1]),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(name),
                                    )
                                  : Image.network(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(name),
                                    ),
                            )
                          : _buildImagePlaceholder(name),
                    ),
                    if (badge != null && badge.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isFavorite) {
                              WishlistService.instance.removeFromWishlist(productId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("$name removed from Wishlist"),
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } else {
                              WishlistService.instance.addToWishlist(product, variantDisplay);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("$name added to Wishlist! ❤️"),
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? const Color(0xFFE57373) : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    variantDisplay,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final Map<String, dynamic> activeVariant = _extractDefaultVariantStructure(product);

                        _cartService.addToCart(
                          productId: productId,
                          productName: name,
                          imagePath: imagePath ?? '',
                          variant: activeVariant,
                          quantity: 1,
                        );

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFF99417),
                            duration: const Duration(milliseconds: 900),
                            content: Text(
                              "Added $name to your cart successfully!",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF99417),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Add to Cart", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String fallbackName) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        "Image of\n$fallbackName",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "An unexpected exception occurred.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchInventoryData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF99417)),
              child: const Text("Retry Connection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}