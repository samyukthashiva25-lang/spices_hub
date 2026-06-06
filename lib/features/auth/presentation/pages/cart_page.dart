import 'package:flutter/material.dart';
import '/services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartStateChanged);
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartStateChanged);
    super.dispose();
  }

  void _onCartStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  double _calculateGrandTotalSum() {
    return _cartService.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// Central management method handling quantity updates with safety bounds
  void _modifyItemVolume(CartItem targetItem, int adjustmentDelta) {
    final String compositeKey = targetItem.uniqueCartKey;
    
    final cartInstance = _cartService.items.firstWhere(
      (e) => e.uniqueCartKey == compositeKey,
      orElse: () => targetItem,
    );

    setState(() {
      // Hard block: If quantity is 1, do not allow further decrementing
      if (adjustmentDelta == -1 && cartInstance.quantity <= 1) {
        return; 
      }
      
      cartInstance.quantity += adjustmentDelta;
      _cartService.notifyListeners();
    });
  }

  /// Triggers atomic cart map item wipeouts from the true database state provider
  void _removeItemFromCartInstance(String key, String name, String weight) {
    _cartService.removeItem(key);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade900,
        content: Text(
          "Removed $name ($weight) from your cart.",
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<CartItem> activeCartItems = _cartService.items;
    final double grandTotalPrice = _calculateGrandTotalSum();

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
          "My Cart",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: activeCartItems.isEmpty
          ? _buildEmptyStatePlaceholder()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeCartItems.length + 2,
                    itemBuilder: (context, index) {
                      if (index < activeCartItems.length) {
                        return _buildDynamicCartItemRow(activeCartItems[index]);
                      }

                      if (index == activeCartItems.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "You are saving extra on this order!", 
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return const Padding(
                        padding: EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          "Payment will be deducted from your Business Credit account balances.",
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), 
                        blurRadius: 10, 
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Amount", style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
                            Text(
                              "₹${grandTotalPrice.toStringAsFixed(0)}", 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/checkout');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Proceed to Checkout", 
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItemRowImage(String? imagePath) {
    return Container(
      height: 70, 
      width: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(8),
      ),
      child: imagePath != null && imagePath.trim().isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
              ),
            )
          : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 26),
    );
  }

  Widget _buildDynamicCartItemRow(CartItem item) {
    final String variantDescription = "${item.variantWeight} (${item.variantType})";
    final double rowTotalCalculatedPrice = item.price * item.quantity;
    final bool isMinusDisabled = item.quantity <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCartItemRowImage(item.imagePath),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                      ),
                    ),
                    // Single dedicated top-right delete action button
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
                      onPressed: () => _removeItemFromCartInstance(item.uniqueCartKey, item.productName, item.variantWeight),
                    ),
                  ],
                ),
                Text(
                  variantDescription, 
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${rowTotalCalculatedPrice.toStringAsFixed(0)}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                    ),
                    
                    // Stepper Box Layout
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStepperQuantityButton(
                            Icons.remove, 
                            isMinusDisabled ? () {} : () => _modifyItemVolume(item, -1),
                            iconColor: isMinusDisabled ? Colors.grey.shade300 : Colors.black,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "${item.quantity}", 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                            ),
                          ),
                          _buildStepperQuantityButton(Icons.add, () => _modifyItemVolume(item, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperQuantityButton(IconData icon, VoidCallback action, {Color iconColor = Colors.black}) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Icon(icon, size: 14, color: iconColor),
      ),
    );
  }

  Widget _buildEmptyStatePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 54, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Your inventory list cart is empty",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              "Add items from product catalog selection grids.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Browse Spices", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}