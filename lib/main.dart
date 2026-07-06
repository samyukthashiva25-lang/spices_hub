import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

// Authentication & Core Pages
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/auth/presentation/pages/home_page.dart'; 

// Other Feature Pages
import 'features/auth/presentation/pages/cart_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/product_list_page.dart';
import 'features/auth/presentation/pages/product_detail_page.dart';
import 'features/auth/presentation/pages/checkout_page.dart';
import 'features/auth/presentation/pages/order_confirmation_page.dart';
import 'features/auth/presentation/pages/order_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const NavigationShell(), // Updated core entry to navigation frame
        '/product_list': (context) => const ProductListPage(),
        '/product_detail_page': (context) => const ProductDetailPage(), 
        '/cart': (context) => const CartPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/order_confirmation': (context) => const OrderConfirmationPage(),
        '/order_history': (context) => const OrderHistoryPage(),
        '/profile': (context) => const ProfilePage(),
        '/pending': (context) => const PendingApprovalPage(), 
      },
    );
  }
}

/// Dynamic State Controller Frame managing runtime index layouts 
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;

  // Ordered layouts array matching the tabs mapping layout from image_ec2028.jpg
  final List<Widget> _navigationViewTabs = [
    const HomePage(),        // Index 0: Dashboard Stream (Removes internal bar configuration)
    const ProductListPage(), // Index 1: Unified Inventory Grid Catalog
    const CartPage(),        // Index 2: Current Checkout Cart Summary
    const Center(child: Text("Wishlist", style: TextStyle(fontSize: 16, color: Colors.grey))), // Index 3: Saved/Liked Items Placeholder
    const ProfilePage(),     // Index 4: User/Vendor Metrics Dashboard Screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: IndexedStack(
        index: _selectedIndex,
        children: _navigationViewTabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFF99417),
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          onTap: (int incomingIndex) {
            setState(() {
              _selectedIndex = incomingIndex;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), 
              activeIcon: Icon(Icons.home), 
              label: "Home"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted_rounded), 
              label: "Products"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined), 
              activeIcon: Icon(Icons.shopping_cart), 
              label: "Cart"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded), 
              activeIcon: Icon(Icons.favorite_rounded), 
              label: "Wishlist"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), 
              activeIcon: Icon(Icons.account_circle), 
              label: "Account"
            ),
          ],
        ),
      ),
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
      backgroundColor: const Color(0xFFFD923F), 
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