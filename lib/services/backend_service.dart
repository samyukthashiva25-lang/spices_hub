import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  final String baseUrl = "https://spiceshub-production.up.railway.app/api";

  // Shared headers helper
  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<bool> loginUser(String phonenumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "phonenumber": phonenumber,
          "password": password,
        }),
      );

      // Returns true if your backend database lookup confirms credentials match correctly
      return response.statusCode == 200;
    } catch (e) {
      print("Network Routing Failure: $e");
      return false;
    }
  }

  // Generic response handler to catch common API errors
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : true;
    } else {
      // You can add specific logging or custom Exception throwing here
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
  // SPICES (INVENTORY)
  // ==========================

  Future<List<dynamic>> getAllSpices() async {
    final response = await http.get(Uri.parse("$baseUrl/spices/all"), headers: _headers);
    return _handleResponse(response) as List<dynamic>;
  }

  // Added: Get specific spice details
  Future<Map<String, dynamic>> getSpiceById(String spiceId) async {
    final response = await http.get(Uri.parse("$baseUrl/spices/$spiceId"), headers: _headers);
    return _handleResponse(response) as Map<String, dynamic>;
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

