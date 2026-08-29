import 'package:flutter/material.dart';
import '/services/backend_service.dart'; 
import '/services/session_manager.dart'; // 💡 Session manager to fetch the cached runtime user data

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final BackendService _backendService = BackendService();
  
  bool _isLoading = true;
  String _selectedFilter = "All";
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];

  final List<String> _filters = ["All", "Pending", "Confirmed", "Delivered"];

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  // 💡 Fetches orders using your SessionManager cache logic
  Future<void> _fetchOrderHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Extract the cached active profile data map matching login implementation structure
      final Map<String, dynamic>? userProfile = SessionManager.instance.currentUserProfile;
      
      if (userProfile == null || !userProfile.containsKey('uid') || userProfile['uid'] == null) {
        throw Exception("Active session configurations or user metrics missing.");
      }
      
      final String currentUserId = userProfile['uid'].toString();

      // Dispatch tracking string securely to service context
      final List<dynamic> data = await _backendService.getUserOrderHistory(currentUserId);
      
      if (mounted) {
        setState(() {
          _allOrders = data;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("BackendService Fetch Error: $e");
      final String fallbackMsg = e.toString().replaceAll("Exception:", "").trim();
      _showErrorSnackBar(fallbackMsg.contains("session") ? fallbackMsg : "Failed to load fresh orders pipeline.");
      
      if (mounted) {
        setState(() {
          _allOrders = [];
          _filteredOrders = [];
          _isLoading = false;
        });
      }
    }
  }
  // 💡 Add this helper to safely parse the backend date object
  String _formatDate(dynamic dateData) {
    if (dateData == null) return "Recent";
    
    // If it's already a string, return it
    if (dateData is String) return dateData;
    
    // If it's the complex Map object (seconds/nanos), extract the seconds
    if (dateData is Map) {
      final int seconds = (dateData['seconds'] ?? 0).toInt();
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
    
    return dateData.toString();
  }
  

  void _applyFilter() {
    if (_selectedFilter == "All") {
      _filteredOrders = _allOrders;
    } else {
      _filteredOrders = _allOrders
          .where((order) => order['status'].toString().toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent.shade700),
    );
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return const Color(0xFF137333);
      case 'delivered': return const Color(0xFF1A73E8);
      default: return const Color(0xFFB06000);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return const Color(0xFFE6F4EA);
      case 'delivered': return const Color(0xFFE8F0FE);
      default: return const Color(0xFFFEF7E0);
    }
  }

  void _openOrderDetailsPopup(Map<String, dynamic> order) {
    final double grandTotal = (order['amount'] ?? 0.0).toDouble();
    final double subtotal = (order['subtotal'] ?? (grandTotal * 0.95)).toDouble();
    final double gstAmount = (order['gst'] ?? (grandTotal * 0.05)).toDouble();
    final List<dynamic> orderItems = order['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${order['orderId'] ?? 'Order ID'}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(order['status'] ?? 'Pending'),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${order['status'] ?? 'Pending'}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _getStatusTextColor(order['status'] ?? 'Pending'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
  "Placed on ${_formatDate(order['date'])}",
  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: Color(0xFFEEEEEE)),
                  ),
                  
                  const Text("Items Ordered", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  orderItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("No product details found for this order record.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orderItems.length,
                          itemBuilder: (context, itemIndex) {
                            final item = orderItems[itemIndex];
                            final double itemPrice = (item['price'] ?? 0.0).toDouble();
                            final int itemQty = (item['quantity'] ?? 1).toInt();
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${item['productname'] ?? 'Spice Product'}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${item['selectedweight'] ?? ''}  ×  $itemQty",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "₹${_formatCurrency(item['subtotal'])}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF99417)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                  const SizedBox(height: 16),
                  const Text("Delivery Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Shipping Address", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          "${order['shippingAddress'] ?? 'No address registered.'}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Color(0xFFEEEEEE)),
                        ),
                        const Text("Payment Method", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          order['paymentMethod'] == "CREDIT_LIMIT" ? "Credit Limit Wallet" : "Cash on Delivery (COD)",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildInvoiceRow("Subtotal", "₹${_formatCurrency(subtotal)}"),
                        const SizedBox(height: 10),
                        _buildInvoiceRow("Delivery Charges", "FREE", highlightGreen: true),
                        const SizedBox(height: 10),
                        _buildInvoiceRow("Estimated GST (5%)", "₹${_formatCurrency(gstAmount)}"),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Color(0xFFE0E0E0)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Paid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              "₹${_formatCurrency(grandTotal)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFF99417)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvoiceRow(String field, String val, {bool highlightGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(field, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlightGreen ? Colors.green : Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Order History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF99417)))
          : RefreshIndicator(
              color: const Color(0xFFF99417),
              onRefresh: _fetchOrderHistory,
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return GestureDetector(
                          onTap: () => _onFilterSelected(filter),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF99417) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFF99417) : const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildOrderHistoryCard(order);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderHistoryCard(dynamic order) {
    final String status = order['status'] ?? 'Pending';
    final String orderId = order['orderId'] ?? '';
    final int itemsCount = (order['itemCount'] ?? (order['items'] as List? ?? []).length).toInt();

    return GestureDetector(
      onTap: () => _openOrderDetailsPopup(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
Text(
  _formatDate(order['date']),
  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Divider(color: Color(0xFFEEEEEE), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "$itemsCount ${itemsCount == 1 ? 'item' : 'items'}",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => _openOrderDetailsPopup(order),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          children: [
                            Text(
                              "Reorder",
                              style: TextStyle(color: Color(0xFFF99417), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFF99417)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "₹${_formatCurrency(order['amount'] ?? 0.0)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF99417)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No $_selectedFilter orders found",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    double parsedAmount = 0.0;
    if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is double) {
      parsedAmount = amount;
    }
    return parsedAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}