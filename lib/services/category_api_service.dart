import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../config/config_url.dart';

class CategoryApiService {
  static String get baseUrl => "${ConfigUrl.baseUrl}CategoryApi";

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

  // Lấy tất cả danh mục
  static Future<List<Category>> getAllCategories() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => Category.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Lấy danh mục theo ID
  static Future<Category> getCategoryById(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception('Failed to load category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category: $e');
    }
  }

  // Tạo danh mục mới
  static Future<Category> createCategory(Category category) async {
    try {
      final headers = await _getAuthHeaders();
      final jsonData = category.toJson();

      print('🔍 CATEGORY API Debug:');
      print('URL: $baseUrl');
      print('JSON being sent: ${json.encode(jsonData)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(jsonData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create category: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ CATEGORY API Error: $e');
      throw Exception('Error creating category: $e');
    }
  }

  // Cập nhật danh mục
  static Future<Category> updateCategory(int id, Category category) async {
    try {
      final headers = await _getAuthHeaders();
      final jsonData = category.toJson();

      print('🔍 UPDATE CATEGORY API Debug:');
      print('URL: $baseUrl/$id');
      print('JSON being sent: ${json.encode(jsonData)}');

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode(jsonData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception(
          'Failed to update category: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ UPDATE CATEGORY API Error: $e');
      throw Exception('Error updating category: $e');
    }
  }

  // Xóa danh mục
  static Future<bool> deleteCategory(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      print('Delete category response status: ${response.statusCode}');
      print('Delete category response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ DELETE CATEGORY API Error: $e');
      throw Exception('Error deleting category: $e');
    }
  }
}
