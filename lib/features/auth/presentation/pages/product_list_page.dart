import 'dart:convert';
import 'package:flutter/material.dart';
import '/services/backend_service.dart';


class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final BackendService _backendService = BackendService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allActiveProducts = []; // Master copy of database products
  List<dynamic> _filteredProducts = [];  // Runtime array matching UI state
  
  bool _isLoading = true;
  String? _errorMessage;
  int _creditLimit = 10000;
  
  // Tracks selected filtering token state (null represents "All")
  String? _selectedCategory;

  // Exact 6 category map configuration synced directly with your admin selection list
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
    _loadSpicesInventory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('creditlimit')) {
      setState(() {
        _creditLimit = args['creditlimit'] ?? 10000;
      });
    }
  }

  Future<void> _loadSpicesInventory() async {
    try {
      final List<dynamic> data = await _backendService.getAllSpices();
      
      setState(() {
        // Only display active products matching your boolean model flag
        _allActiveProducts = data.where((product) {
          final bool isPublished = product['ispublished'] ?? false;
          return isPublished == true;
        }).toList();
        
        _filteredProducts = List.from(_allActiveProducts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "").trim();
        _isLoading = false;
      });
    }
  }

  /// Combined Multi-Filter Pipeline Logic (Search + Category)
  void _applyFilters() {
    setState(() {
      _filteredProducts = _allActiveProducts.where((product) {
        // 1. Evaluate Category Selection Matching 
        if (_selectedCategory != null) {
          final String backendCat = (product['category'] ?? '').toString().toLowerCase().trim();
          final String targetCat = _selectedCategory!.toLowerCase().trim();
          if (backendCat != targetCat) return false;
        }

        // 2. Evaluate Search Text Query
        final String query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          final String name = (product['productname'] ?? '').toString().toLowerCase();
          final String tags = (product['tags'] ?? '').toString().toLowerCase();
          if (!name.contains(query) && !tags.contains(query)) return false;
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged() => _applyFilters();

  void _selectCategoryFilter(String? categoryName) {
    setState(() {
      _selectedCategory = categoryName;
    });
    _applyFilters();
  }

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
      debugPrint("Exception caught during parsing execution: $e");
    }
    return 'Standard';
  }

  String? _cleanBadgeText(String? tagText) {
    if (tagText == null || tagText.trim().isEmpty || tagText.contains('{') || tagText.contains('[')) {
      return null; 
    }
    return tagText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          "Welcome to Spices Hub  🍔 💰",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _errorMessage != null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Credit Indicator Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.grey.shade200, radius: 20),
                            const SizedBox(width: 12),
                            Text(
                              "Credit: ₹$_creditLimit left",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Search Text Input Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: "Search for products...",
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.search, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Carousel Promotional Layout 
                      _buildPromotionalBanner(),
                      const SizedBox(height: 24),

                      // 4. Categories Label Heading
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Categories",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // DESIGN UPDATE: Single Line Horizontal Scroll Filter Bar
                      _buildHorizontalCategoryScroll(),
                      const SizedBox(height: 24),

                      // 5. Section Header Dynamic Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCategory == null ? "Products" : "Products in $_selectedCategory",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            Text(
                              "${_filteredProducts.length} Items",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 6. Double Column Inventory Processing Pipeline Grid
                      _filteredProducts.isEmpty 
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Text("No items match this filter category.", style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredProducts.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.64,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildProductItemCard(context, _filteredProducts[index]);
                                },
                              ),
                            ),
                      const SizedBox(height: 24),

                      // 7. Footer Promotional Card Block
                      _buildPromotionalBanner(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Promotional Banners", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 16, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// NEW METHOD: Renders single-line premium scroll chips row component cleanly
  Widget _buildHorizontalCategoryScroll() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        // Count includes the structural 'All' chip (+1)
        itemCount: _categories.length + 1, 
        itemBuilder: (context, index) {
          final bool isAllChip = index == 0;
          final String catName = isAllChip ? "All" : _categories[index - 1]["name"]!;
          final String catIcon = isAllChip ? "📦" : _categories[index - 1]["icon"]!;
          
          final bool isSelected = isAllChip 
              ? _selectedCategory == null 
              : _selectedCategory == catName;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => _selectCategoryFilter(isAllChip ? null : catName),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(catIcon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      catName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductItemCard(BuildContext context, Map<String, dynamic> product) {
    final String trackingId = product['id'] ?? '';
    final String name = product['productname'] ?? 'Unnamed Spice';
    final String? imagePath = product['images'];
    
    final String parsedTypeDisplay = _parseVariantType(product['variant']);
    final String? badge = _cleanBadgeText(product['tags']);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product_detail_page',
          arguments: {'id': trackingId},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: Center(
                      child: imagePath != null && imagePath.trim().isNotEmpty
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(name),
                            )
                          : _buildImagePlaceholder(name),
                    ),
                  ),
                  if (badge != null && badge.trim().isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parsedTypeDisplay, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        "Add to List",
                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String fallbackName) {
    return Text(
      "Image of\n$fallbackName",
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.black87, fontSize: 12),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadSpicesInventory();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text("Retry Connection", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}