import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/session_manager.dart';
import '/services/wishlist_service.dart'; // Imported to keep the wishlist item count live

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// Logs out the user safely, clears memory caches, and purges navigation history
  Future<void> _handleLogoutSession(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    SessionManager.instance.clearSession();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  /// Helper to generate initials from the shop name (e.g., "Sri Aravind Stores" -> "SA")
  String _getInitials(String shopName) {
    if (shopName.trim().isEmpty) return "GS";
    List<String> parts = shopName.trim().split(RegExp(r'\s+'));
    String initials = parts[0][0];
    if (parts.length > 1) {
      initials += parts[1][0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Read instantly from the runtime cache
    final profile = SessionManager.instance.currentUserProfile;

    // Fallbacks if data map properties are missing from runtime definitions
    final String shopName = profile?['shopname'] ?? "Sri Aravind Stores";
    final String ownerName = profile?['ownername'] ?? "Aravind Kumar";
    final String phoneNumber = profile?['phonenumber'] ?? "9876543210";
    final String emailId = profile?['emailid'] ?? "aravind@gmail.com";
    final String gstNumber = profile?['gstnumber'] ?? "33ABCDE1234F1Z5";
    final String location = profile?['location'] ?? "Coimbatore, TN";
    final int creditLimit = (profile?['creditlimit'] ?? 100000).toInt();

    // Format currency spacing to match UI image (e.g., ₹ 1,00,000)
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) mathFunc = (Match match) => '${match[1]},';
    String formattedCredit = creditLimit.toString().replaceAllMapped(reg, mathFunc);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF78828A), size: 26),
            onPressed: () {
              // Context-aware bottom panel sheet for settings actions (like logout)
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        title: const Text("Logout from Session", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.pop(context);
                          _handleLogoutSession(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            // 1. Profile Overview Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFF99417),
                    child: Text(
                      _getInitials(shopName),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ownerName,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF96A0A5)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check, color: Color(0xFF2ECC71), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "Verified",
                                    style: TextStyle(color: Color(0xFF2ECC71), fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Add edit profile path logic here
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_outlined, color: Color(0xFFF99417), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    "Edit Profile",
                                    style: TextStyle(color: Color(0xFFF99417), fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Business Credit Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E4), // Tinted cream accent background
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.credit_card_rounded, color: Color(0xFFF99417), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Credit Balance",
                        style: TextStyle(color: Color(0xFF6A7074), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₹ $formattedCredit",
                        style: const TextStyle(color: Color(0xFFF99417), fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Shop Information Nested Grid Table Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Shop Information",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  _buildMetaTableRow(Icons.phone_android_outlined, "Mobile", phoneNumber),
                  const Divider(color: Color(0xFFF1F1F1), height: 1),
                  _buildMetaTableRow(Icons.email_outlined, "Email", emailId),
                  const Divider(color: Color(0xFFF1F1F1), height: 1),
                  _buildMetaTableRow(Icons.account_balance_rounded, "GST", gstNumber),
                  const Divider(color: Color(0xFFF1F1F1), height: 1),
                  _buildMetaTableRow(Icons.location_on_outlined, "Location", location),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Standalone Modular Navigation Cards List Loop
            _buildActionMenuCard(
              icon: Icons.inventory_2_outlined,
              title: "Order History",
              onTap: () => Navigator.pushNamed(context, '/order_history_page'),
            ),
            
            // Connected directly with the Wishlist listener component state parameters
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: WishlistService.instance,
              builder: (context, wishlistItems, child) {
                return _buildActionMenuCard(
                  icon: Icons.favorite_border_rounded,
                  title: "Wishlist",
                  badgeText: "${wishlistItems.length} saved",
                  onTap: () => Navigator.pushNamed(context, '/wishlist_page'),
                );
              },
            ),
            
            _buildActionMenuCard(
              icon: Icons.notifications_none_rounded,
              title: "Notifications",
              onTap: () {},
            ),
            _buildActionMenuCard(
              icon: Icons.help_outline_rounded,
              title: "Help & Support",
              onTap: () {},
            ),
            _buildActionMenuCard(
              icon: Icons.description_outlined,
              title: "Terms & Privacy",
              onTap: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTableRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF78828A)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF96A0A5), fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenuCard({
    required IconData icon,
    required String title,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF2D3134), size: 22),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeText != null)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text(
                  badgeText,
                  style: const TextStyle(color: Color(0xFFF99417), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0B9BE), size: 14),
          ],
        ),
      ),
    );
  }
}