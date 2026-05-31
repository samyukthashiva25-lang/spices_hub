import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Checkout", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cart Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Cart Item List
            _buildCartItem("Turmeric Powder", "1kg", "₹400"),
            _buildCartItem("Cumin Seeds", "2kg", "₹750"),
            
            const SizedBox(height: 24),
            const Text("Rewards Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Claim your rewards", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            
            // Rewards Row
            Row(
              children: [
                _buildRewardCard("Eligible Rewards", "Buy for ₹2000 to get ₹100 Zomato coupon"),
                const SizedBox(width: 12),
                _buildRewardCard("Available Points", "Buy for ₹1000 to get ₹50 Swiggy coupon"),
              ],
            ),
            
            const SizedBox(height: 24),
            // Points Redemption
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Redeem Points", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Max redeem 1000 points", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Text("1000 points", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
            
            const SizedBox(height: 24),
            const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Payment Options
            Row(
              children: [
                _buildPaymentChip("UPI", isSelected: true),
                const SizedBox(width: 8),
                _buildPaymentChip("Payment Gateway", isSelected: false),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentChip("Credit Pay    Credit: ₹10,000 left", isSelected: false, isWide: true),
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text("2% discount for online payment", style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),

            const SizedBox(height: 32),
            const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Financial Breakdown
            _buildSummaryRow("Subtotal", "₹1150"),
            _buildSummaryRow("Online Payment Discount (2%)", "-₹50", isGrey: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildSummaryRow("Total Amount", "₹1100", isBold: true, fontSize: 18),
            ),
            
            const SizedBox(height: 24),
            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to confirmation and clear the stack to prevent back-navigation to checkout
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/order_confirmation', 
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  "Place Order", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildCartItem(String name, String weight, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100, 
            child: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.black)
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(weight, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRewardCard(String title, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 85,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200), 
          borderRadius: BorderRadius.circular(12)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              desc, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String label, {required bool isSelected, bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: isWide ? double.infinity : null,
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black, 
          fontWeight: FontWeight.bold,
          fontSize: 13
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGrey = false, bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: isGrey ? Colors.grey : Colors.black, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
              fontSize: fontSize
            )
          ),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
              fontSize: fontSize
            )
          ),
        ],
      ),
    );
  }
}