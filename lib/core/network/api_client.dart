import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';

class ApiClient {
  final http.Client _httpClient;
  static const String _baseUrlPrefKey = 'etikket_api_base_url';

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlPrefKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return ApiEndpoints.defaultBaseUrl;
  }

  Future<void> setBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefKey, newUrl.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  Map<String, String> _buildHeaders({String? token, Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final baseUrl = await getBaseUrl();
    Uri uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw NetworkException(
        message: 'Cannot connect to server at $baseUrl. Please verify the server is running and check your connection.',
      );
    } on TimeoutException {
      throw NetworkException(message: 'Connection timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    String? token,
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw NetworkException(
        message: 'Cannot connect to server at $baseUrl. Please verify the server is running and check your connection.',
      );
    } on TimeoutException {
      throw NetworkException(message: 'Connection timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = {'message': response.body};
      }
    } else {
      decoded = {};
    }

    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    final errorMessage = decoded is Map<String, dynamic>
        ? (decoded['message'] ?? decoded['error'] ?? 'Request failed with status $statusCode')
        : 'Request failed with status $statusCode';

    if (statusCode == 401 || statusCode == 403) {
      throw AuthException(message: errorMessage.toString());
    }

    throw ServerException(
      message: errorMessage.toString(),
      statusCode: statusCode,
    );
  }
}
