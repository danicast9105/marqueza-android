import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
   

  static Future<http.Response> get(String url) {
    return http.get(Uri.parse(url));
  }

  static Future<http.Response> post(String url, Map body) {
    return http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String url) {
    return http.delete(Uri.parse(url));
  }

   static Future<http.Response> put(String url, Map body) {
    return http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}


