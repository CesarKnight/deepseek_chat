import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class ApiClient {
  final String baseUrl;
  final String model;
  final String apiKey;
  final http.Client _httpClient;

  ApiClient({
    required this.baseUrl,
    this.model = ApiConstants.OPENROUTER_MODEL,
    this.apiKey = ApiConstants.OPENROUTER_API_KEY,
  }) : _httpClient = http.Client();

  /// Makes a GET request to the specified endpoint
  Future<http.Response> get({required String endpoint}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    return await _httpClient.get(
      url,
      headers: _getHeaders(),
    );
  }

  /// Makes a POST request to the specified endpoint with the given body
  Future<http.Response> post({
    required String endpoint,
    required String body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    return await _httpClient.post(
      url,
      headers: _getHeaders(),
      body: body,
    );
  }

  /// Makes a PUT request to the specified endpoint with the given body
  Future<http.Response> put({
    required String endpoint,
    required String body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    return await _httpClient.put(
      url,
      headers: _getHeaders(),
      body: body,
    );
  }

  /// Makes a DELETE request to the specified endpoint
  Future<http.Response> delete({required String endpoint}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    return await _httpClient.delete(
      url,
      headers: _getHeaders(),
    );
  }

  /// Returns the headers for the API request
  Map<String, String> _getHeaders() {
    return {
      // 'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
  }

  /// Closes the HTTP client when it's no longer needed
  void dispose() {
    _httpClient.close();
  }
}