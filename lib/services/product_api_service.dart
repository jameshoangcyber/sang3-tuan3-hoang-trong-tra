import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/products.dart';
import '../config/config_url.dart';

class ProductApiService {
  static String get baseUrl => "${ConfigUrl.baseUrl}ProductApi";

  // Helper method để lấy JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }

    return {'Content-Type': 'application/json'};
  }

  // Lấy tất cả sản phẩm
  static Future<List<ProductPost>> getAllProducts() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => ProductPost.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Lấy sản phẩm theo ID
  static Future<ProductPost> getProductById(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return ProductPost.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Tìm kiếm sản phẩm
  static Future<List<ProductPost>> searchProducts(String query) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => ProductPost.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  // Thêm sản phẩm mới
  static Future<ProductPost> createProduct(ProductPost product) async {
    try {
      final jsonData = product.toJson();
      print('🔍 PRODUCT API Debug:');
      print('URL: $baseUrl');
      print('JSON being sent: ${json.encode(jsonData)}');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(jsonData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ProductPost.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create product: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ PRODUCT API Error: $e');
      throw Exception('Error creating product: $e');
    }
  }

  // Cập nhật sản phẩm
  static Future<ProductPost> updateProduct(int id, ProductPost product) async {
    try {
      final jsonData = product.toJson();
      print('🔍 UPDATE PRODUCT API Debug:');
      print('URL: $baseUrl/$id');
      print('JSON being sent: ${json.encode(jsonData)}');

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode(jsonData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 204) {
        // Return the updated product with the ID
        return product.copyWith(id: id);
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception(
          'Failed to update product: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ UPDATE PRODUCT API Error: $e');
      throw Exception('Error updating product: $e');
    }
  }

  // Xóa sản phẩm
  static Future<bool> deleteProduct(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }
}
