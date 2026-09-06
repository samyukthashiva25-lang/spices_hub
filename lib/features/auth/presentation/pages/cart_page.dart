import 'package:flutter/material.dart';
import 'package:spices_hub/services/cart_service.dart'; // 💡 Make sure this points to your exact path
import 'dart:convert'; 
import '/services/backend_service.dart';
import 'package:http/http.dart' as http;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}
class _CartPageState extends State<CartPage> {
  final BackendService _backendService = BackendService();

  final CartService _cartService = CartService();
  bool _isSyncingWithBackend = true;
  bool _isProcessingCheckout = false; 
  String _selectedPaymentMethod = "cod"; 

  final String _currentUserId = "97cVwhOBuTZ0Bmtj23Zz"; 

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartStateChanged);
    _initializeCartSync();
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartStateChanged);
    super.dispose();
  }

  Future<void> _initializeCartSync() async {
    try {
      await _cartService.fetchCartFromBackend();
    } catch (e) {
      debugPrint("Error initializing backend cart: $e");
    } finally {
      if (mounted) {
        setState(() => _isSyncingWithBackend = false);
      }
    }
  }

  void _onCartStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

Future<void> _executeCheckoutProcess(String shippingAddress) async {
    // 1. Snapshot totals before wiping out service lists
    final double subtotalSnapshot = _cartService.totalCartAmount;
    final double grandTotalSnapshot = subtotalSnapshot + (subtotalSnapshot * 0.05);

    setState(() => _isProcessingCheckout = true);
    final String mappedPaymentMethod = _selectedPaymentMethod == "credit" ? "CREDIT_LIMIT" : "COD";
    final url = Uri.parse("https://spiceshub-production-2783.up.railway.app/api/orders/checkout/$_currentUserId");
//final url = Uri.parse("http://localhost:8080/api/orders/checkout/$_currentUserId");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "shippingAddress": shippingAddress,
          "paymentMethod": mappedPaymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // 2. Clear the cart locally
        _cartService.clearCart(); 

        // 3. IF CREDIT LIMIT WAS USED: Update state or notify profile controllers
        if (_selectedPaymentMethod == "credit") {
          // If your backend returns the new balance (e.g., responseData['newCreditLimit'])
          // update your global user/profile service here:
          // _profileService.updateLimit(responseData['newCreditLimit']);
          
          debugPrint("Credit limit successfully deducted on backend.");
        }

        if (!mounted) return;
        
        // 4. Display success sheet
        _showOrderPlacedBottomSheet(responseData, grandTotalSnapshot);
      } else {
        final String errorMessage = jsonDecode(response.body)['error'] ?? "Checkout rejected.";
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackBar("Network connecting transaction error: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessingCheckout = false);
      }
    }
  }

  void _showOrderPlacedBottomSheet(Map<String, dynamic> orderDetails, double capturedTotal) {
    final String paymentMethodText = _selectedPaymentMethod == "credit" ? "CREDIT LIMIT" : "COD";

showModalBottomSheet(
      context: context,
      isDismissible: false, 
      enableDrag: false,     
      backgroundColor: Colors.white,
      isScrollControlled: true, // Required for bottom sheet to handle scrolling properly
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F4EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.done_rounded,
                      color: Color(0xFF137333),
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Order Placed!",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your order has been placed successfully.\nWe'll notify you when it's confirmed.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Order ID : ",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${orderDetails['orderId'] ?? 'ORD_4FCF99E5'}",
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        Text(
                          "Amount : ",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "₹ ${_formatCurrency(capturedTotal)} ($paymentMethodText)",
                          style: const TextStyle(color: Color(0xFFF99417), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF99417),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.pushReplacementNamed(context, '/order_history');
                      },
                      child: const Text(
                        "View Order Details",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCartItems = _cartService.items;
    final double subtotal = _cartService.totalCartAmount;
    final double gstAmount = subtotal * 0.05; 
    final double grandTotal = subtotal + gstAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
  onPressed: () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  },
),
 
        titleSpacing: 0,
        title: Row(
          children: [
            const Text(
              "My Cart",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            if (activeCartItems.isNotEmpty && !_isSyncingWithBackend) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF99417),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${_cartService.totalItemCount}",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
      body: _isSyncingWithBackend
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF99417)))
          : activeCartItems.isEmpty
              ? _buildEmptyStatePlaceholder()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeCartItems.length,
                              itemBuilder: (context, index) {
                                return _buildCartItemCard(activeCartItems[index]);
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildOrderSummarySection(subtotal, gstAmount, grandTotal),
                            const SizedBox(height: 24),
                            const Text(
                              "Payment Method",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentSelectionRow(
                              id: "cod",
                              title: "Cash on Delivery",
                              icon: Icons.money_rounded,
                              iconColor: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentSelectionRow(
                              id: "credit",
                              title: "Use Credit Limit",
                              icon: Icons.credit_card_rounded,
                              iconColor: Colors.blueGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildStaticFooter(grandTotal),
                  ],
                ),
    );
  }

  Widget _buildCartItemCard(dynamic item) {
    final double computedRowTotal = item.price * item.quantity;
    final String imagePath = item.imagePath ?? '';

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
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.variantWeight,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (item.quantity > 1) {
                            _cartService.updateQuantity(item.uniqueCartKey, item.quantity - 1);
                          } else {
                            _showDeleteConfirmation(item);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.remove_rounded, size: 16, color: Colors.black87),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          "${item.quantity}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _cartService.updateQuantity(item.uniqueCartKey, item.quantity + 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add_rounded, size: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _showDeleteConfirmation(item),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Text(
                  "₹${_formatCurrency(computedRowTotal)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF99417)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(dynamic item) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Remove Item"),
          content: Text("Are you sure you want to remove ${item.productName} (${item.variantWeight}) from your cart?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _cartService.removeFromCart(item.uniqueCartKey);
                Navigator.pop(ctx);
              },
              child: const Text("Remove", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderSummarySection(double subtotal, double gst, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Summary",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 14),
          _buildSummaryDataRow("Subtotal", "₹${_formatCurrency(subtotal)}"),
          const SizedBox(height: 10),
          _buildSummaryDataRow("Delivery", "Free", isFreeColor: true),
          const SizedBox(height: 10),
          _buildSummaryDataRow("GST (5%)", "₹${_formatCurrency(gst)}"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Color(0xFFEEEEEE), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Text(
                "₹${_formatCurrency(total)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF99417)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDataRow(String label, String value, {bool isFreeColor = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            color: isFreeColor ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelectionRow({
    required String id,
    required String title,
    required IconData icon,
    required Color iconColor,
  }) {
    final bool isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF6EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF99417) : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: const Color(0xFFF99417),
              size: 22,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFF99417) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticFooter(double finalTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessingCheckout 
                ? null 
                : () => _executeCheckoutProcess("123 Main Spice Street, Coimbatore"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF99417),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.orange.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessingCheckout
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    "Place Order",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStatePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              "Your cart is empty",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              "Add products from the catalogue\nto place a bulk order",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.4),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF99417),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Browse Products", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
      child: Icon(Icons.image, color: Colors.grey.shade400, size: 28),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}