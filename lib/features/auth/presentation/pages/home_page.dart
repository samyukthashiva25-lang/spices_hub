import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Welcome to Spices Hub", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(children: [Text("🍔"), SizedBox(width: 8), Text("💰")]),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCreditBar(),
            _buildSearchBar(),
            _buildBanner("Promotional Banners"),
            _buildCategorySection(),
            _buildProductGridHeader(context), // Context passed here
            _buildProductGrid(),
            _buildBanner("Promotional Banners"),
          ],
        ),
      ),
    );
  }

  // ... (Keeping your existing _buildCreditBar, _buildSearchBar, _buildBanner, _buildCategorySection, _catChip)

  Widget _buildCreditBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.grey.shade300, radius: 20),
          const SizedBox(width: 12),
          const Text("Credit: ₹10,000 left", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for products...",
                prefixIcon: const Icon(Icons.search_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.tune, color: Colors.white), // Changed to filter icon for logic
          )
        ],
      ),
    );
  }

  Widget _buildBanner(String text) {
    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 18))),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          padding: const EdgeInsets.all(16),
          children: [
            _catChip("🌶️", "Spices"),
            _catChip("🌱", "Seeds"),
            _catChip("🥘", "Masala Mixes"),
            _catChip("🫒", "Oils"),
          ],
        )
      ],
    );
  }

  Widget _catChip(String emoji, String label) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text("$emoji $label", style: const TextStyle(fontWeight: FontWeight.w500))),
    );
  }

  // --- UPDATED SECTION ---
  Widget _buildProductGridHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
              // Navigates to the Product List page defined in main.dart routes
              Navigator.pushNamed(context, '/product_list');
            }, 
            child: const Text("See All", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.7,
      padding: const EdgeInsets.all(16),
      children: [
        _productCard("Turmeric Powder", "1kg, 2kg, 5kg", "Best Seller"),
        _productCard("Cumin Seeds", "1kg, 2kg, 5kg", "Organic"),
      ],
    );
  }

  Widget _productCard(String name, String qty, String? badge) {
    return Card(
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Stack(
                children: [
                  Center(child: Text("Image of\n$name", textAlign: TextAlign.center)),
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                        color: Colors.black87, 
                        child: Text(badge, style: const TextStyle(fontSize: 10, color: Colors.white))
                      )
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(qty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Logic to add to cart would go here
                    }, 
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Add to List")
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}