import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Make sure to generate this file using the FlutterFire CLI (`flutterfire configure`)
// If you don't use the CLI, import your own Firebase Options configuration class.
import 'features/auth/presentation/pages/login_page.dart';
import 'firebase_options.dart'; 

import 'features/auth/presentation/pages/cart_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/product_list_page.dart';
import 'features/auth/presentation/pages/product_detail_page.dart';
import 'features/auth/presentation/pages/checkout_page.dart';
import 'features/auth/presentation/pages/order_confirmation_page.dart';
import 'features/auth/presentation/pages/order_history_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';

void main() async {
  // ✅ FIX: Ensures component binding is ready before calling asynchronous native tasks
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ FIX: Initializes Firebase correctly using web-safe cross-platform parameters
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const SpicesHubApp());
}

class SpicesHubApp extends StatelessWidget {
  const SpicesHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spices Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF9933),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(), 
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainWrapper(),
        '/product_list': (context) => const ProductListPage(),
        '/product_detail_page': (context) => const ProductDetailPage(), 
        '/cart': (context) => const CartPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/order_confirmation': (context) => const OrderConfirmationPage(),
        '/order_history': (context) => const OrderHistoryPage(),
        '/signup': (context) => const SignupPage(),
        
        // ✅ FIX: Added placeholder route to safely intercept redirection logic from signup page
        '/pending': (context) => const PendingApprovalPage(), 
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFD923F), // Vibrant orange background
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(painter: WavePainter()),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 30.0, top: 40.0),
                  child: Text(
                    "Order in\nBulk,\nWithout\nHassle",
                    style: TextStyle(
                      fontSize: 62,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF262626),
                      letterSpacing: -2,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                Center(
                  child: Image.asset(
                    'assets/images/SplashScreen.png',
                    height: MediaQuery.of(context).size.height * 0.45,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.white54,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  child: GestureDetector(
                    onTap: () {
                      // ✅ UPDATED: Directs to the core Tab shell so the bottom footer bar mounts safely right away
                      Navigator.pushReplacementNamed(context, '/login'); 
                    },
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEEFE3), 
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Get Started",
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    var path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.4, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.5);
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path.shift(const Offset(0, 40)), paint);
    canvas.drawPath(path.shift(const Offset(0, 80)), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Modern navigation stack mapped to your UI mockup definitions
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ProductListPage(), // ✅ UPDATED: Merged your real Product layout into Tab index 0
      const CartPage(),        // Tab Index 1
      const Center(
        child: Text(
          "Support Live Chat Desk Gateway", 
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ),                       // Tab Index 2
      const ProfilePage(),     // Tab Index 3
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey.shade400,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, height: 1.6),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.6),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), 
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined), 
                  activeIcon: Icon(Icons.shopping_cart_rounded),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded), 
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Support',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded), 
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Account Pending Approval",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your registration request was sent successfully. An administrator will review your shop and credentials shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text("Back to Login", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}