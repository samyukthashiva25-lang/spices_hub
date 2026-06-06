import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/session_manager.dart'; // Verified session pipeline link

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// Logs out the user safely, clears memory caches, and purges navigation history
  Future<void> _handleLogoutSession(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    SessionManager.instance.clearSession(); // Purge cache profile maps
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green.shade600;
      case 'PENDING':
        return const Color(0xFFFF9933); // Spices Hub Accent Orange
      case 'REJECTED':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ READ INSTANTLY FROM RUNTIME CACHE: No FutureBuilder or loading delays
    final profile = SessionManager.instance.currentUserProfile;

    // Fallbacks if data map properties are missing from runtime definitions
    final String shopName = profile?['shopname'] ?? "Guest Merchant";
    final String ownerName = profile?['ownername'] ?? "Anonymous Member";
    final String phoneNumber = profile?['phonenumber'] ?? "N/A";
    final String emailId = profile?['emailid'] ?? "N/A";
    final String gstNumber = profile?['gstnumber'] ?? "Unprovided";
    final String status = (profile?['status'] ?? "PENDING").toString().toUpperCase();
    final int creditLimit = (profile?['creditlimit'] ?? 0).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false, // Keeps layout stable inside navigation wrapper tabs
        title: const Text(
          "My Profile", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _handleLogoutSession(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Identification Header banner
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32, 
                  backgroundColor: Colors.grey.shade100,
                  child: const Icon(Icons.storefront_rounded, color: Colors.black, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "Operator: $ownerName", 
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dynamic Account Status Badge Identifier
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            
            const Text(
              "Enterprise Registration Details", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),

            // Information row modules pulling directly from login user variables
            _buildCleanDetailsRow(Icons.verified_user_outlined, "GST Classification ID", gstNumber),
            _buildCleanDetailsRow(Icons.account_balance_wallet_outlined, "Available Business Credit", "₹$creditLimit"),
            _buildCleanDetailsRow(Icons.phone_android_outlined, "Registered Contact Number", phoneNumber),
            _buildCleanDetailsRow(Icons.email_outlined, "Corporate Correspondence Email", emailId),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanDetailsRow(IconData displayIcon, String descriptorLabel, String actualValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(displayIcon, color: Colors.grey.shade700, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptorLabel, 
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  actualValue, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}