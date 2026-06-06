import 'dart:convert';
import 'package:flutter/material.dart';
import '/services/backend_service.dart'; // Ensure this points to your backend service file
import '/services/cart_service.dart';    // Points to the CartService model written above

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final BackendService _backendService = BackendService();
  final CartService _cartService = CartService();
  final TextEditingController _quantityController = TextEditingController(text: "1");

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

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
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
      debugPrint("Variant extraction runtime processing exception: $e");
    }
  }

  void _updateQuantityOffset(int delta) {
    int current = int.tryParse(_quantityController.text) ?? 1;
    current += delta;
    if (current < 1) current = 1;
    _quantityController.text = current.toString();
  }

  /// EXECUTES ADD TO CART OPERATION pipeline
  void _executeAddToCartProcess() {
    if (_selectedVariantMap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a variant option first")),
      );
      return;
    }

    final int targetQty = int.tryParse(_quantityController.text) ?? 1;
    final String productId = _productData?['id']?.toString() ?? '';
    final String productName = _productData?['productname'] ?? 'Item';
    final String? imagePath = _productData?['images'];

    // Send item properties down to global atomic storage mapping
    _cartService.addToCart(
      productId: productId,
      productName: productName,
      imagePath: imagePath,
      variant: _selectedVariantMap!,
      quantity: targetQty,
    );

    // Provide visual system feedback confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        content: Text(
          "$productName (${_selectedVariantMap!['weight'] ?? ''}) added to list!",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Product Detail",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _errorMessage != null
              ? _buildErrorPlaceholder()
              : _buildMainProductCanvas(),
      bottomNavigationBar: _isLoading || _errorMessage != null 
          ? null 
          : _buildStickyBottomActionBar(),
    );
  }

  Widget _buildMainProductCanvas() {
    final String productName = _productData?['productname'] ?? 'Unnamed Product';
    final String? imagePath = _productData?['images'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 280,
            width: double.infinity,
            color: Colors.grey.shade50,
            child: imagePath != null && imagePath.trim().isNotEmpty
                ? Image.network(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => _buildFallbackImageBanner(productName),
                  )
                : _buildFallbackImageBanner(productName),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),

                // Variant Horizontal Scroll Chips
                if (_parsedVariants.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Select Variant",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _parsedVariants.length,
                      itemBuilder: (context, index) {
                        final variant = _parsedVariants[index];
                        final String type = variant['type'] ?? 'Standard';
                        final String weight = variant['weight'] ?? '';
                        final String price = variant['price'] ?? '0';
                        
                        final String customLabel = "$weight – ₹$price ($type)";
                        final bool isSelected = _selectedVariantMap == variant;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedVariantMap = variant;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                customLabel,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Text(
                      "Choose the product variant",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quantity",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStepperAdjustmentButton(Icons.remove, () => _updateQuantityOffset(-1)),
                          Container(
                            width: 90,
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          _buildStepperAdjustmentButton(Icons.add, () => _updateQuantityOffset(1)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Use + and - to adjust", 
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        "Rewards Section", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      Text(
                        "Claim your rewards", 
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStructuredRewardCard(
                            "Eligible Rewards", 
                            "Buy for ₹2000 to get ₹100 Zomato coupon",
                          ),
                          const SizedBox(width: 12),
                          _buildStructuredRewardCard(
                            "Available Points", 
                            "Buy for ₹1000 to get ₹50 Swiggy coupon",
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStickyBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), 
            blurRadius: 10, 
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Direct navigation callback to your application cart route
                  Navigator.pushNamed(context, '/cart');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Go to Cart",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _executeAddToCartProcess, // Triggers custom multi-variant validation pipeline
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(0, 48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Add to Cart",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperAdjustmentButton(IconData icon, VoidCallback action) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 18, color: Colors.black),
      ),
    );
  }

  Widget _buildStructuredRewardCard(String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 95,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                subtitle, 
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImageBanner(String genericTitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          "Image display of\n$genericTitle",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade500),
        ),
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
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchProductDetailsPipeline();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text("Retry Load", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}