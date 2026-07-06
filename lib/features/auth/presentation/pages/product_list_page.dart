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

  List<dynamic> _allActiveProducts = []; 
  List<dynamic> _filteredProducts = [];  
  
  bool _isLoading = true;
  String? _errorMessage;
  int _creditLimit = 10000;
  
  String? _selectedCategory;

  // Exact category configuration matching the pill filters in image_ebafa9.jpg
  final List<String> _categories = ["Spices", "Nuts", "Dry Fruits", "Seeds", "Herbs", "Blends"];

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
    _selectedCategory = categoryName;
    _applyFilters();
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF99417)))
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildCategoryHorizontalScroll(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _filteredProducts.isEmpty 
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Text("No items match this filter category.", style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredProducts.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemBuilder: (context, index) {
                                return _buildProductItemCard(context, _filteredProducts[index]);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search spices, nuts...",
          prefixIcon: const Icon(Icons.search_outlined, color: Colors.grey, size: 22),
          suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _searchController.clear();
                  },
                )
              : null,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF99417), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHorizontalScroll() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final bool isAllChip = index == 0;
          final String catName = isAllChip ? "All" : _categories[index - 1];
          final bool isSelected = isAllChip ? _selectedCategory == null : _selectedCategory == catName;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _selectCategoryFilter(isAllChip ? null : catName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Text(
                  catName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductItemCard(BuildContext context, Map<dynamic, dynamic> product) {
    final String trackingId = product['id']?.toString() ?? '';
    final String name = product['productname'] ?? 'Unnamed Spice';
    final String? imagePath = product['images'];
    final String priceDisplay = product['price']?.toString() ?? '₹0';
    final String? badge = _cleanBadgeText(product['tags']);

    return GestureDetector(
      onTap: () {
        if (trackingId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/product_detail_page',
            arguments: {'id': trackingId},
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
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
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                  if (badge != null && badge.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.favorite_border_rounded, color: Colors.grey.shade400, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          priceDisplay.contains('/kg') ? priceDisplay : "$priceDisplay/kg",
                          style: const TextStyle(color: Color(0xFFF99417), fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF99417),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Add to Cart", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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