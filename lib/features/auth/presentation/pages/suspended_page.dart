import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/session_manager.dart';

class SuspendedPage extends StatefulWidget {
  const SuspendedPage({super.key});

  @override
  State<SuspendedPage> createState() => _SuspendedPageState();
}

class _SuspendedPageState extends State<SuspendedPage> {
  bool _isReactivating = false;

  /// Pure clear-out helper to switch back accounts
  Future<void> _handleSignOutChange() async {
    await FirebaseAuth.instance.signOut();
    SessionManager.instance.clearSession();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _handleReactivationRequest() async {
    setState(() => _isReactivating = true);
    
    // TODO: Connect this placeholder action cleanly with your specific backend database service payload update
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() => _isReactivating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reactivation request submitted successfully."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Locked Icon Badge Element
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAEA).withOpacity(0.6), // Soft light reddish pink ring backdrop
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded, 
                      size: 64, 
                      color: Color(0xFFB0A264), // Muted gold/bronze lock core style matching mockup
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Account Suspended Title text
              const Text(
                "Account Suspended",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              // Inactivity explanation details 
              Text(
                "Your account has been suspended\ndue to 40+ days of inactivity.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),

              // Warning Container Banner Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEA).withOpacity(0.7), // Clean pastel error box
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.warning_amber_rounded, 
                        color: Color(0xFFD32F2F), 
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "To reactivate, your details need to be re-verified. This usually takes 24 hours.",
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),

              // Action buttons group container assembly
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isReactivating ? null : _handleReactivationRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFD923F), // Spices Hub core Theme Orange color tint
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isReactivating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Reactivate My Account",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Contact Support secondary flat outline link card module
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate cleanly into the existing Support Tab module or system dispatch line
                    Navigator.pushNamed(context, '/support');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7F7F7),
                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Contact Support",
                    style: TextStyle(color: Color(0xFF111111), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Bottom Redirection structural footer action
              GestureDetector(
                onTap: _handleSignOutChange,
                child: const Text(
                  "Login with a different account",
                  style: TextStyle(
                    color: Color(0xFFFD923F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}