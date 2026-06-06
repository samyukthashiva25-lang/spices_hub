import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  // final String baseUrl = "https://spiceshub-production.up.railway.app/api";
  final String baseUrl = "http://localhost:8080/api"; // For local development

  // Shared headers helper
  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  /// Modified: Authenticates phone and password and returns the full User object configuration map.
  /// Throws an informative exception containing the server's specific gatekeeper validation errors.
  Future<Map<String, dynamic>> loginUser(String phonenumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/login"), // Keeping standard user auth endpoints
        headers: _headers,
        body: jsonEncode({
          "phonenumber": phonenumber,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        // Decode and return the user payload (UID, Status, CreditLimit, etc.)
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Capture specific security/gate exceptions thrown by your Java login rules
        print("Login validation gate exception: ${response.body}");
        throw Exception(response.body.isNotEmpty ? response.body : "Invalid credentials.");
      }
    } catch (e) {
      print("Network Routing Failure: $e");
      rethrow;
    }
  }

  // Generic response handler to catch common API errors
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : true;
    } else {
      print("API Error: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to perform operation: ${response.statusCode}');
    }
  }

  // ==========================
  // USER & AUTHENTICATION
  // ==========================

  Future<bool> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/register"),
        headers: _headers,
        body: jsonEncode(userData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Registration error: $e");
      return false;
    }
  }

  Future<String> checkApprovalStatus(String uid) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/users/check-status/$uid"));
      if (response.statusCode == 200) return "APPROVED";
      if (response.statusCode == 403) return "PENDING";
      return "NOT_FOUND";
    } catch (e) {
      return "ERROR";
    }
  }

  // ==========================
  // PRODUCTS (SPICES INVENTORY)
  // Updated endpoints to match Java ProductController annotations
  // ==========================

  /// Synchronized with Java `@GetMapping("/all")` inside `ProductController`
  Future<List<dynamic>> getAllSpices() async {
    final response = await http.get(Uri.parse("$baseUrl/products/all"), headers: _headers);
    return _handleResponse(response) as List<dynamic>;
  }

  /// Synchronized with individual dynamic mapping hooks if needed
  Future<Map<String, dynamic>> getSpiceById(String spiceId) async {
    final response = await http.get(Uri.parse("$baseUrl/products/$spiceId"), headers: _headers);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// Synchronized with Java `@PostMapping("/add")` inside `ProductController`
  Future<String> addSpice(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/products/add"),
      headers: _headers,
      body: jsonEncode(productData),
    );
    final result = _handleResponse(response);
    return result['id'] ?? '';
  }

  /// Synchronized with Java `@PutMapping("/update/{id}")` inside `ProductController`
  Future<bool> updateSpice(String id, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse("$baseUrl/products/update/$id"),
      headers: _headers,
      body: jsonEncode(productData),
    );
    return response.statusCode == 200;
  }

  /// Synchronized with Java `@DeleteMapping("/delete/{id}")` inside `ProductController`
  Future<bool> deleteSpice(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/products/delete/$id"), headers: _headers);
    return response.statusCode == 200;
  }

  // ==========================
  // ORDERS (TRANSACTIONS)
  // ==========================

  Future<String?> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/orders/place"),
        headers: _headers,
        body: jsonEncode(orderData),
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Order placement error: $e");
      return null;
    }
  }

  // Added: Get order history for a user
  Future<List<dynamic>> getUserOrders(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/orders/user/$userId"), headers: _headers);
    return _handleResponse(response) as List<dynamic>;
  }
}