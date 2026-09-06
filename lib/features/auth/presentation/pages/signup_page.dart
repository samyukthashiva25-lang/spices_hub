import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/services/backend_service.dart'; 

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _backendService = BackendService(); 
  File? _shopImage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Controllers for processing backend registration elements
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); 
  final _confirmPasswordController = TextEditingController();
  final _gstController = TextEditingController(); // Logic retained for backend mapping continuity

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _shopImage = File(image.path);
      });
    }
  }

  // UNCHANGED INTEGRATION LOGIC
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_shopImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a shop board photo from your gallery metadata")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Confirm Password mismatch. Fields must match perfectly.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare data mapping exactly to User.java fields.
      Map<String, dynamic> shopData = {
        "uid": null, 
        "shopname": _shopNameController.text.trim(),
        "ownername": _ownerNameController.text.trim(),
        "phonenumber": _mobileController.text.trim(),
        "emailid": _emailController.text.trim(),
        "password": _passwordController.text.trim(), 
        "gstnumber": _gstController.text.trim().isEmpty ? "PENDING_VERIFICATION" : _gstController.text.trim(),
        "image": "pending_upload",
        "creditlimit": 0,
        "status": "PENDING",
        "role": "VENDOR"
      };

      bool success = await _backendService.registerUser(shopData);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/pending');
      } else {
        throw Exception("Backend registration service rejected data structure or returned a non-200 code");
      }
    } catch (e) {
      final String fallbackMsg = e.toString();
      debugPrint("System Runtime Trace: $fallbackMsg");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration processing failed: $fallbackMsg")),
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Back Navigation Bar
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_rounded, size: 16, color: const Color(0xFFFD923F)),
                      const SizedBox(width: 4),
                      Text(
                        "Back",
                        style: TextStyle(
                          color: const Color(0xFFFD923F),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Section Headers
                const Text(
                  "Create Your\nBusiness Account",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF262626),
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Register your shop once to access wholesale spices & dry fruits.",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Inputs Matching Design Document Layout Guidelines
                _buildLabel("Shop Name"),
                TextFormField(
                  controller: _shopNameController,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your shop name' : null,
                  decoration: _buildInputDecoration("Enter your shop name"),
                ),
                const SizedBox(height: 20),

                _buildLabel("Owner Name"),
                TextFormField(
                  controller: _ownerNameController,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your owner name' : null,
                  decoration: _buildInputDecoration("Enter your owner name"),
                ),
                const SizedBox(height: 20),

                _buildLabel("Mobile Number"),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your mobile number' : null,
                  decoration: _buildInputDecoration("Enter your mobile number"),
                ),
                const SizedBox(height: 20),

                _buildLabel("Email (Optional)"),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration("Enter your email address"),
                ),
                const SizedBox(height: 20),

                _buildLabel("Password"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  validator: (value) => value == null || value.trim().length < 8 ? 'Password must be at least 8 characters long' : null,
                  decoration: _buildInputDecoration(
                    "Create a password (min 8 chars)",
                    suffix: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400, size: 20),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel("Confirm Password"),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please re-enter your validation password' : null,
                  decoration: _buildInputDecoration(
                    "Re-enter your password",
                    suffix: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400, size: 20),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel("GST Number (Optional Verification Step)"),
                TextFormField(
                  controller: _gstController,
                  decoration: _buildInputDecoration("Enter your legal GSTIN record reference"),
                ),
                const SizedBox(height: 24),

                _buildLabel("Shop Board Photo Asset"),
                _buildImagePickerBlock(),
                const SizedBox(height: 40),

                // Submit Interactive Button Area
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFD923F), // Theme Orange Call-To-Action Element Accent Color
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit for Approval",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                        ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Redirection Banner Link
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text("Already have Account ? ", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          "Sign in", 
                          style: TextStyle(color: Color(0xFFFD923F), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text, 
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A)),
    ),
  );

  InputDecoration _buildInputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), 
        borderSide: const BorderSide(color: Color(0xFFFD923F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
      ),
    );
  }

  Widget _buildImagePickerBlock() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _shopImage != null ? Colors.green.shade200 : Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              _shopImage == null ? Icons.add_photo_alternate_outlined : Icons.check_circle_outline_rounded,
              color: _shopImage == null ? Colors.grey.shade500 : Colors.green.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _shopImage == null ? "Tap to upload gallery image..." : "Selected: ${_shopImage!.path.split('/').last}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _shopImage == null ? Colors.grey.shade500 : Colors.green.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}