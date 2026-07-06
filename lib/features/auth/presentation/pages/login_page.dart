import 'package:flutter/material.dart';
import '/services/backend_service.dart'; // Adjust path based on your project structure
import '/services/session_manager.dart'; // Session manager file to cache runtime configurations

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _backendService = BackendService();
  bool _isLoading = false;

  // Controllers for processing data safely
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // WEB-SAFE LOGIN INTEGRATION LOGIC WITH SAFE CONTROLLER CAPTURE
  Future<void> _handleLogin() async {
    // 1. Capture text strings IMMEDIATELY before any async gap to eliminate JS 'undefined' errors
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 2. Fetch user profile payload map using local immutable strings
      final dynamic rawResponse = await _backendService.loginUser(username, password);

      // Defend against uninitialized/undefined map responses entirely
      if (rawResponse == null || rawResponse is! Map<String, dynamic>) {
        throw Exception("Invalid server profile configuration structure received.");
      }

      final Map<String, dynamic> userProfile = rawResponse;

      // 3. Safely parse nesting structures to prevent runtime mapping exceptions
      final dynamic targetPayload = userProfile.containsKey('data') && userProfile['data'] != null 
          ? userProfile['data'] 
          : userProfile;

      if (targetPayload is Map<String, dynamic> && targetPayload.containsKey('uid') && targetPayload['uid'] != null) {
        
        // Ensure widget is still alive/mounted before executing navigation or state updates
        if (!mounted) return;
        
        // ✅ INTEGRATED SESSION MANAGER CACHE LAYER
        SessionManager.instance.currentUserProfile = userProfile;

        // Extract and normalization of system status flags securely
        final String status = (targetPayload['status'] ?? 'PENDING').toString().toUpperCase().trim();
        
        // 4. Conditional Router Module 
        if (status == 'APPROVED') {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/pending');
        }
      } else {
        throw Exception("Invalid account matching credentials setup profile configuration.");
      }
    } catch (e) {
      // Clean runtime exception isolation strings cleanly for UI SnackBar rendering
      final String fallbackMsg = e.toString().replaceAll("Exception:", "").trim();
      debugPrint("Auth Error Trace: $fallbackMsg");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackMsg),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Desktop Left-Side Visual Side-Panel (Hidden on Mobile viewports)
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFFF99417), // Theme App Vibrant Orange Tint
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back to\nSpiceHub",
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF262626),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Manage your retail orders, view outstanding credit limitations, and track wholesale supply dispatch timelines instantly.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Main Interactive Login Form Interface Viewport Container
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center, // Centered branding layout alignment strategy
                      children: [
                        
                        // Circular Orange Chili Brand Asset Layout
                        Container(
                          width: 85,
                          height: 85,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF99417),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              "🌶️", 
                              style: TextStyle(fontSize: 42),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "SpiceHub",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Wholesale made simple",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                        
                        const SizedBox(height: 44),
                        
                        // Text Greeting Header Row
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "Welcome Back!", 
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form Field Controls Layers
                        Align(alignment: Alignment.centerLeft, child: _buildLabel("Username")),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your username' : null,
                          decoration: _buildInputDecoration("Mobile number or email"),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Align(alignment: Alignment.centerLeft, child: _buildLabel("Password")),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true, // Flat unmasked tracking input layout styling matching specification wireframe
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your account password' : null,
                          decoration: _buildInputDecoration("Enter your password"),
                        ),

                        const SizedBox(height: 12),
                        
                        // Right-aligned Interactive Forgot Trigger Option Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Color(0xFFF99417), fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Main Form Action Layer Trigger Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF99417), // Theme App Orange color code matching spec UI
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Dynamic Interactive Lower Action Prompt Footer Text Blocks
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text("New business? ", style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                                child: const Text(
                                  "Register here", 
                                  style: TextStyle(color: Color(0xFFF99417), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
  );

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF99417), width: 1.5)),
    );
  }
}