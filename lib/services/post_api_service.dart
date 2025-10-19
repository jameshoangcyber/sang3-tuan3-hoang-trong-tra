import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../config/config_url.dart';

class PostApiService {
  static String get baseUrl => "${ConfigUrl.baseUrl}PostApi";

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

  // Lấy tất cả bài đăng
  static Future<List<Post>> getAllPosts() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => Post.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  // Lấy bài đăng theo ID
  static Future<Post> getPostById(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return Post.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching post: $e');
    }
  }

  // Tạo bài đăng mới
  static Future<Post> createPost(Post post) async {
    try {
      final jsonData = post.toJson();
      print('🔍 POST API Debug:');
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
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create post: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ POST API Error: $e');
      throw Exception('Error creating post: $e');
    }
  }

  // Cập nhật bài đăng
  static Future<Post> updatePost(int id, Post post) async {
    try {
      final jsonData = post.toJson();
      print('🔍 UPDATE POST API Debug:');
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
        // Return the updated post with the ID
        return post.copyWith(id: id);
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception(
          'Failed to update post: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ UPDATE POST API Error: $e');
      throw Exception('Error updating post: $e');
    }
  }

  // Xóa bài đăng
  static Future<bool> deletePost(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting post: $e');
    }
  }

  // Like/Unlike bài đăng
  static Future<bool> toggleLike(int postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$postId/like'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error toggling like: $e');
    }
  }

  // Thêm comment
  static Future<bool> addComment(int postId, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$postId/comment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': comment}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  // Share bài đăng
  static Future<bool> sharePost(int postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$postId/share'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error sharing post: $e');
    }
  }
}
