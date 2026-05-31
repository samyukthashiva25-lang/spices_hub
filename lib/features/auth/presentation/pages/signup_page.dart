import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/services/backend_service.dart'; // Adjust path based on your project structure

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

  // Controllers for input fields
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _passwordController = TextEditingController(); 

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _passwordController.dispose();
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

  // BACKEND-GENERATED UID INTEGRATION LOGIC
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_shopImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a shop board photo")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Prepare data mapping exactly to User.java fields.
      // Explicitly pass "uid" as null so the backend's auto-generation fallback triggers.
      Map<String, dynamic> shopData = {
        "uid": null, 
        "shopname": _shopNameController.text.trim(),
        "ownername": _ownerNameController.text.trim(),
        "phonenumber": _mobileController.text.trim(),
        "emailid": _emailController.text.trim(),
        "password": _passwordController.text.trim(), // Sent to backend for registration management
        "gstnumber": _gstController.text.trim(),
        "image": "pending_upload",
        "creditlimit": 0,
        "status": "PENDING",
        "role": "VENDOR"
      };

      // 2. Dispatch payload downstream to your Spring Boot /register endpoint
      bool success = await _backendService.registerUser(shopData);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/pending');
      } else {
        throw Exception("Backend registration service rejected data structure or returned a non-200 code");
      }
    } catch (e) {
      // Clean fallback string formatting to capture any HTTP payload serialization drops safely on Web
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("Signup Page", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Shop Name"),
                    _buildTextField(_shopNameController, "Enter your shop name"),

                    _buildLabel("Owner Name"),
                    _buildTextField(_ownerNameController, "Enter your name"),

                    _buildLabel("Mobile Number"),
                    _buildTextField(_mobileController, "Enter your mobile number", keyboardType: TextInputType.phone),

                    _buildLabel("Email Address"),
                    _buildTextField(_emailController, "Enter your email address", keyboardType: TextInputType.emailAddress),

                    _buildLabel("Password"),
                    _buildTextField(_passwordController, "Create a password", isPassword: true),

                    _buildLabel("GST Number"),
                    _buildTextField(_gstController, "Enter your GST number"),

                    _buildLabel("Shop Board Photo"),
                    _buildImagePicker(),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit for Approval", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      validator: (value) => value == null || value.trim().isEmpty ? 'This field is required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                _shopImage == null ? "" : "Image Selected: ${_shopImage!.path.split('/').last}",
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text("Tap to upload image", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}