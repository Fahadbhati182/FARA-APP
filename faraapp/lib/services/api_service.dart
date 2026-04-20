import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulators pointing to local machine,
  // or localhost for Chrome/Windows desktop.
  // static const String baseUrl = 'https://fara-foodbackend.onrender.com/api'; 
  static const String baseUrl = 'http://localhost:3001/api'; 
  
  static const String tokenKey = 'jwt_token';

  /// Add the Bearer token to requests
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Check if user is authenticated (has a token)
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(tokenKey);
  }

  /// Admin Login
  static Future<Map<String, dynamic>> adminLogin(String email, String password, {String role = 'admin'}) async {
    final url = Uri.parse('$baseUrl/admin/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;

      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, data['token']);
      }
      return data;
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['message'] ?? 'Admin login failed');
    }
  }

  // --- Admin Specific API ---

  /// getAdminDashboardStats
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final url = Uri.parse('$baseUrl/admin/dashboard-stats');
    final response = await http.get(url, headers: await _headers()).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Failed to load dashboard stats');
  }

  /// getAdminAllOrders
  static Future<Map<String, dynamic>> getAdminAllOrders() async {
    final url = Uri.parse('$baseUrl/admin/all-orders');
    final response = await http.get(url, headers: await _headers()).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load all orders');
  }

  /// getAdminAllRequests
  static Future<List<dynamic>> getAdminAllRequests() async {
    final url = Uri.parse('$baseUrl/admin/all-requests');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Failed to load all material requests');
  }

  /// getAdminAnalytics
  static Future<Map<String, dynamic>> getAdminAnalytics(String period) async {
    final url = Uri.parse('$baseUrl/admin/analytics?period=$period');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load analytics');
  }

  /// recordExternalOrder
  static Future<Map<String, dynamic>> recordExternalOrder(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/admin/external-order');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to record external order');
    }
  }

  /// Login
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );


    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'] ?? jsonResponse;
      
      // Store token
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, data['token']);
      }
      return data;
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['message'] ?? 'Login failed');
    }
  }

  /// Register
  static Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'] ?? jsonResponse;
    } else {
      final errorResponse = jsonDecode(response.body);
      // Ensure we extract the express-validator array string gracefully if needed
      final msg = errorResponse['errors'] != null && errorResponse['errors'].isNotEmpty 
          ? errorResponse['errors'][0]['msg'] 
          : errorResponse['message'] ?? 'Registration failed';
      throw Exception(msg);
    }
  }

  /// Get Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/auth/profile');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  /// Change Password
  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/change-password');
    final response = await http.patch(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to change password');
    }
  }

  /// Update Profile (supports name, phone, e.g. and profile image)
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    dynamic imageFile, // Can be File or Uint8List (for web)
    String? fileName,
  }) async {
    final url = Uri.parse('$baseUrl/profile/update');
    
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(await _headers());

    if (name != null) request.fields['name'] = name;
    if (phone != null) request.fields['phone'] = phone;

    if (imageFile != null) {
      if (imageFile is List<int>) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageFile,
          filename: fileName ?? 'profile.jpg',
        ));
      } else {
        // Assume it's a file path if not bytes (for non-web)
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.toString(),
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update profile');
    }
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    // Optional: Call logout backend endpoint if your custom auth requires it
    try {
      await http.get(Uri.parse('$baseUrl/auth/logout'), headers: await _headers());
    } catch (_) {
      // Ignore if server is down or unreachable during logout
    }
  }

  /// Get All Addresses
  static Future<List<dynamic>> getAddresses() async {
    final url = Uri.parse('$baseUrl/profile/addresses');
    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load addresses');
    }
  }

  /// Delete Address
  static Future<void> deleteAddress(String id) async {
    final url = Uri.parse('$baseUrl/profile/addresses/$id');
    final response = await http.delete(url, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception('Failed to delete address');
    }
  }

  /// Set Default Address
  static Future<void> setDefaultAddress(String id) async {
    final url = Uri.parse('$baseUrl/profile/addresses/default/$id');
    final response = await http.patch(url, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception('Failed to set default address');
    }
  }

  /// Update Address
  static Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/profile/addresses/$id');
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update address');
    }
  }

  /// Create Address
  static Future<void> createAddress(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/profile/addresses');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create address');
    }
  }

  /// placeOrder
  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/orders/place');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to place order');
    }
  }

  /// getOrder
  static Future<Map<String, dynamic>> getOrder(String id) async {
    final url = Uri.parse('$baseUrl/orders/$id');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load order');
    }
  }

  /// getUserOrders
  static Future<Map<String, dynamic>> getUserOrders() async {
    final url = Uri.parse('$baseUrl/orders/user/history');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load user orders');
    }
  }

  /// getWorkerOrders
  static Future<Map<String, dynamic>> getWorkerOrders() async {
    final url = Uri.parse('$baseUrl/orders/worker/history');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load worker orders');
    }
  }

  /// updateOrderStatus
  static Future<Map<String, dynamic>> updateOrderStatus(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/orders/status/$id');
    final response = await http.patch(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update order status');
    }
  }

  /// processOrderRefund
  static Future<Map<String, dynamic>> processOrderRefund(String id) async {
    final url = Uri.parse('$baseUrl/orders/refund/$id');
    final response = await http.patch(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to process refund');
    }
  }

  /// createMaterialRequest
  static Future<Map<String, dynamic>> createMaterialRequest(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/requests/create');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create material request');
    }
  }

  /// updateMaterialRequestStatus
  static Future<void> updateMaterialRequestStatus(String id, String status) async {
    final url = Uri.parse('$baseUrl/requests/status/$id');
    final response = await http.patch(
      url,
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update request status');
    }
  }

  /// getWorkerMaterialRequests
  static Future<Map<String, dynamic>> getWorkerMaterialRequests() async {
    final url = Uri.parse('$baseUrl/requests/history');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load material requests');
    }
  }

  /// getAllWorkers
  static Future<List<dynamic>> getAllWorkers() async {
    final url = Uri.parse('$baseUrl/admin/workers');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Failed to load workers');
  }

  /// getAllFoods
  static Future<List<dynamic>> getAllFoods() async {
    final url = Uri.parse('$baseUrl/foods/all');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Failed to load foods');
  }

  /// addFood
  static Future<dynamic> addFood(
      Map<String, dynamic> data, {
      Uint8List? imageBytes,
      String? imageName,
      }) async {
    final url = Uri.parse('$baseUrl/foods/create');
    final request = http.MultipartRequest('POST', url);
    
    final headers = await _headers();
    headers.remove('Content-Type'); // Let http client set multipart boundries
    request.headers.addAll(headers);

    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    if (imageBytes != null && imageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json['data'];
    }
    throw Exception(json['message'] ?? 'Failed to add food');
  }

  /// updateFood
  static Future<dynamic> updateFood(
      String id,
      Map<String, dynamic> data, {
      Uint8List? imageBytes,
      String? imageName,
      }) async {
    final url = Uri.parse('$baseUrl/foods/update/$id');
    final request = http.MultipartRequest('PUT', url);
    
    final headers = await _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    if (imageBytes != null && imageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return json['data'];
    }
    throw Exception(json['message'] ?? 'Failed to update food');
  }

  /// deleteFood
  static Future<void> deleteFood(String id) async {
    final url = Uri.parse('$baseUrl/foods/delete/$id');
    final response = await http.delete(url, headers: await _headers());
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete food');
    }
  }

  /// addWorker
  static Future<dynamic> addWorker(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/admin/add-worker');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to add worker');
  }

  /// updateWorker
  static Future<dynamic> updateWorker(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/admin/update-worker/$id');
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to update worker');
  }

  /// removeWorker
  static Future<void> removeWorker(String workerId) async {
    final url = Uri.parse('$baseUrl/admin/remove-worker/$workerId');
    final response = await http.delete(url, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Failed to remove worker');
    }
  }

  /// Send password reset OTP
  static Future<void> sendPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/auth/send-reset-password-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send reset link');
    }
  }

  /// Reset Password with OTP
  static Future<void> resetPassword(String email, String otp, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to reset password');
    }
  }

  /// Send Verify Email OTP
  static Future<void> sendVerifyEmailOTP() async {
    final url = Uri.parse('$baseUrl/auth/send-verify-otp');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to send verification OTP');
    }
  }

  /// Verify Email OTP
  static Future<void> verifyEmailOTP(String otp) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'otp': otp}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to verify email');
    }
  }

  /// toggleFavorite
  static Future<bool> toggleFavorite(String foodId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/toggle-favorite/$foodId"),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'].toString().toLowerCase().contains('added');
    }
    throw Exception(jsonDecode(response.body)['message'] ?? "Toggle favorite failed");
  }


  /// getFavorites
  static Future<List<dynamic>> getFavorites() async {
    final url = Uri.parse('$baseUrl/auth/favorites');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Failed to load favorites');
  }

  /// getAllOutlets
  static Future<List<dynamic>> getAllOutlets() async {
    final url = Uri.parse('$baseUrl/outlets/all');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Failed to load outlets');
  }

  /// createOutlet
  static Future<dynamic> createOutlet(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/outlets/create');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to create outlet');
  }

  /// updateOutlet
  static Future<dynamic> updateOutlet(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/outlets/update/$id');
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to update outlet');
  }

  /// deleteOutlet
  static Future<void> deleteOutlet(String id) async {
    final url = Uri.parse('$baseUrl/outlets/delete/$id');
    final response = await http.delete(url, headers: await _headers());
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete outlet');
    }
  }

  // --- Coupons API ---

  static Future<List<dynamic>> getCoupons() async {
    final url = Uri.parse('$baseUrl/coupons');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Failed to load coupons');
  }

  static Future<dynamic> createCoupon(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/coupons');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to create coupon');
  }

  static Future<void> deleteCoupon(String id) async {
    final url = Uri.parse('$baseUrl/coupons/$id');
    final response = await http.delete(url, headers: await _headers());
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete coupon');
    }
  }

  static Future<Map<String, dynamic>> applyCoupon(String code, double cartTotal) async {
    final url = Uri.parse('$baseUrl/coupons/apply');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'code': code, 'cartTotal': cartTotal}),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to apply coupon');
  }

  /// processPayment
  static Future<Map<String, dynamic>> processPayment(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/payments/process');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json;
    } else {
      throw Exception(json['message'] ?? 'Payment failed');
    }
  }

  /// getAllPayments
  static Future<Map<String, dynamic>> getAllPayments() async {
    final url = Uri.parse('$baseUrl/payments/all');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payment history');
    }
  }

  /// createRazorpayOrder

  static Future<Map<String, dynamic>> createRazorpayOrder(double amount) async {
    print("ApiService: Creating Razorpay order for amount: $amount");
    final url = Uri.parse('$baseUrl/payments/razorpay/create-order');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    ).timeout(const Duration(seconds: 10));

    print("ApiService: Razorpay order response: ${response.statusCode}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create Razorpay order');
    }
  }

  /// verifyRazorpayPayment
  static Future<Map<String, dynamic>> verifyRazorpayPayment(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/payments/razorpay/verify');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Payment verification failed');
    }
  }

  /// checkRazorpayStatus
  static Future<Map<String, dynamic>> checkRazorpayStatus(String orderId) async {
    final url = Uri.parse('$baseUrl/payments/razorpay/status/$orderId');
    final response = await http.get(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to check payment status');
    }
  }

  /// resendPickupCode
  static Future<Map<String, dynamic>> resendPickupCode(String orderId) async {
    final url = Uri.parse('$baseUrl/orders/resend-code/$orderId');
    final response = await http.post(
      url,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to resend pickup code');
    }
  }
}

