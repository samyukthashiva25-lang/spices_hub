import 'package:flutter/material.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              // Main content area taking up the middle space
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hourglass Icon inside a circular tinted background
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3E2), // Warm, light cream/orange circle
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_bottom_rounded, 
                          size: 70, 
                          color: Color(0xFFB07D4F), // Stylized hourglass brown tint
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Main Title Header
                    const Text(
                      "We're Reviewing\nYour Shop",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34, 
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Body text descriptions
                    const Text(
                      "Thank you for registering with us.\n"
                      "Your shop details are currently being\n"
                      "verified by our team.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "This usually takes up to 24 hours.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "You'll receive a notification once your\n"
                      "account is approved.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom Help/Support Section
              Column(
                children: [
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Need help?  ",
                          style: TextStyle(
                            fontSize: 15, 
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Link action to support (e.g., mail, whatsapp)
                          },
                          child: const Text(
                            "Contact Support.",
                            style: TextStyle(
                              fontSize: 15, 
                              color: Colors.orange, // Use your application's primary accent orange
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}