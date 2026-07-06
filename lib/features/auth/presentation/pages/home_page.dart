import 'package:flutter/material.dart';
import 'dart:convert'; // Required for jsonDecode processing
import '/services/backend_service.dart';
import '/services/session_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BackendService _backendService = BackendService();

  // Backend inventory arrays
  List<dynamic> _allProducts = [];       // Master data repository from backend
  List<dynamic> _filteredProducts = [];  // Runtime state bound to UI display

  // Component Pipelines 
  String _searchQuery = "";
  String _selectedCategory = ""; 
  
  bool _isLoading = true;
  String? _errorMessage;

  // Exact category configuration synced directly with your design requirements
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
    _loadDashboardProducts();
  }

  /// Unified data acquisition abstraction utilizing BackendService abstraction layer
  Future<void> _loadDashboardProducts() async {
    try {
      final List<dynamic> data = await _backendService.getAllSpices();
      
      setState(() {
        // Enforce the system business flag logic rule across the collection context
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
      debugPrint("Backend Service fetching exception occurred: $e");
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "").trim();
        _isLoading = false;
      });
    }
  }

  /// Single Atomic Engine running criteria matching sequences across text queries & categories
  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // 1. Evaluate Category Selection Matching 
        if (_selectedCategory.isNotEmpty) {
          final String backendCat = (product['category'] ?? '').toString().toLowerCase().trim();
          final String targetCat = _selectedCategory.toLowerCase().trim();
          if (backendCat != targetCat) return false;
        }

        // 2. Evaluate Search Text Query
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

  /// Decodes and normalizes nested JSON variants metadata string strings
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

  /// Clears raw brackets formatting from server badge text outputs
  String? _cleanBadgeText(String? tagText) {
    if (tagText == null || tagText.trim().isEmpty || tagText.contains('{') || tagText.contains('[')) {
      return null; 
    }
    return tagText;
  }

  @override
  Widget build(BuildContext context) {
    final String businessTitle = SessionManager.instance.currentUserProfile?['business_name'] ?? 
                                 SessionManager.instance.currentUserProfile?['name'] ?? 
                                 "Dashboard Hub";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          businessTitle, 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF99417), size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF99417)))
          : _errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  color: const Color(0xFFF99417),
                  onRefresh: () async {
                    setState(() => _isLoading = true);
                    await _loadDashboardProducts();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCreditBar(),
                        const SizedBox(height: 8),
                        _buildSearchBar(),
                        _buildBanner("Promotional Banners"),
                        _buildCategorySection(),
                        const SizedBox(height: 16),
                        _buildProductGridHeader(context),
                        _buildProductGrid(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
     // bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCreditBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      color: const Color(0xFFFFF0E0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.credit_card_rounded, color: Colors.black87, size: 20),
              SizedBox(width: 8),
              Text(
                "Credit Balance :", 
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87)
              ),
            ],
          ),
          const Text(
            "₹1,000 left", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF99417))
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          _searchQuery = value;
          _applyFilters(); 
        },
        decoration: InputDecoration(
          hintText: "Search for products...",
          prefixIcon: const Icon(Icons.search_outlined, color: Colors.grey, size: 22),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _searchQuery = "";
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

  Widget _buildBanner(String text) {
    return Container(
      height: 160,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF221F1F), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text, 
          style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Categories", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)
              ),
              if (_selectedCategory.isNotEmpty)
                TextButton(
                  onPressed: _clearCategoryFilter,
                  child: const Text("Clear Filter", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _buildSquareCategoryCard(
                cat["icon"]!, 
                cat["name"]!
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildSquareCategoryCard(String emoji, String label) {
    final isSelected = _selectedCategory == label;

    return GestureDetector(
      onTap: () => _selectCategoryFilter(label),
      child: Container(
        width: 95,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0E0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF99417) : const Color(0xFFEEEEEE), 
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                color: isSelected ? const Color(0xFFF99417) : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Products", 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/product_list'), 
            child: const Text(
              "See all", 
              style: TextStyle(color: Color(0xFFF99417), fontWeight: FontWeight.bold, fontSize: 15)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Column(
          children: const [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No products match your description.",
              style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70, // Slightly expanded to fit typography changes safely
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final Map<dynamic, dynamic> product = _filteredProducts[index];
        
        final String name = product['productname'] ?? 'Unnamed Spice';
        final String? imagePath = product['images'];
        final String parsedVariantDisplay = _parseVariantType(product['variant']);
        final String? badgeText = _cleanBadgeText(product['tags']);

        return _productCard(
          name: name,
          imagePath: imagePath,
          variantDisplay: parsedVariantDisplay,
          badge: badgeText,
          productId: product['id']?.toString() ?? '',
        );
      },
    );
  }

  Widget _productCard({
    required String name,
    required String? imagePath,
    required String variantDisplay,
    required String? badge,
    required String productId,
  }) {
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
          borderRadius: BorderRadius.circular(16)
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
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(name),
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
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
                          )
                        )
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border_rounded, color: Colors.grey, size: 20),
                        onPressed: () {},
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
                      onPressed: () {},
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
              style: const TextStyle(color: Colors.grey, fontSize: 14)
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadDashboardProducts();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF99417)),
              child: const Text("Retry Connection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // Widget _buildBottomNavigationBar() {
  //   return BottomNavigationBar(
  //     type: BottomNavigationBarType.fixed,
  //     backgroundColor: Colors.white,
  //     selectedItemColor: const Color(0xFFF99417),
  //     unselectedItemColor: Colors.grey,
  //     currentIndex: 0,
  //     selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  //     unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
  //     items: const [
  //       BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
  //       BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted_rounded), label: "Products"),
  //       BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: "Cart"),
  //       BottomNavigationBarItem(icon: Icon(Icons.favorite_outline_rounded), label: "Wishlist"),
  //       BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: "Account"),
  //     ],
  //   );
  }
