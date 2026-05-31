import 'package:flutter/material.dart';
import '/services/backend_service.dart'; // Adjust path based on your project structure

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _backendService = BackendService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Controllers for processing data
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // WEB-SAFE LOGIN INTEGRATION LOGIC
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String phonenumber = _phoneController.text.trim();
      final String password = _passwordController.text.trim();

      // Send credentials downstream to your Spring Boot Backend for validation
      // Adjust BackendService down the road to handle token validation returns
      bool loginSuccess = await _backendService.loginUser(phonenumber, password);

      if (loginSuccess && mounted) {
        // Route your authenticated user into your Main BottomNavigationBar Wrapper
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception("Invalid phonenumber or matching password profile configuration.");
      }
    } catch (e) {
      // Isolate platform proxy objects cleanly from rendering directly into Web standard threads
      final String fallbackMsg = e.toString().replaceAll("Exception:", "").trim();
      debugPrint("Auth Error Trace: $fallbackMsg");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fallbackMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Desktop Left-Side Visual Panel (Hidden on Small Screens/Mobile Layouts)
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFFFD923F), // Matching application theme accent tint
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back to\nSpices Hub",
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

          // Main Interactive Login Form Interface Container
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
               // maxHeight: MediaQuery.of(context).size.height,
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Brand Header Layout Elements
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9933).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9933), size: 32),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Spices Hub",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const Text("Sign In", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text("Enter your vendor credentials to access your account dashboard", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        const SizedBox(height: 32),

                        // Form Fields Configuration Elements
                        _buildLabel("Phone Number"),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your phone number' : null,
                          decoration: _buildInputDecoration("Enter your registered phonenumber", Icons.phone_android_outlined),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildLabel("Password"),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your account password' : null,
                          decoration: _buildInputDecoration(
                            "Enter account password", 
                            Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Interactive Action Elements Submission Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                        ),

                        const SizedBox(height: 24),

                        // Navigation Link Routing Elements
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text("Don't have a registered vendor account? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                                child: const Text(
                                  "Apply for Approval", 
                                  style: TextStyle(color: Color(0xFFFF9933), fontWeight: FontWeight.bold, fontSize: 14),
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

  InputDecoration _buildInputDecoration(String hint, IconData prefixIcon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
      suffixIcon: suffix,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF9933), width: 1.5)),
    );
  }
}