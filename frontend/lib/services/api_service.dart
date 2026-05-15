import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

class ApiService {
  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<Map<String, dynamic>> googleAuth(String code, String redirectUri) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'redirect_uri': redirectUri}),
    );
    if (resp.statusCode != 200) throw Exception('Auth failed: ${resp.body}');
    return jsonDecode(resp.body);
  }

  static Future<Map<String, dynamic>> getBriefing({bool force = false}) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/briefing').replace(
      queryParameters: {'user_id': userId, if (force) 'force': 'true'},
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('Failed to load briefing');
    return jsonDecode(resp.body);
  }

  static Future<Map<String, dynamic>> refreshBriefing() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/briefing/refresh').replace(
      queryParameters: {'user_id': userId},
    );
    final resp = await http.post(uri);
    if (resp.statusCode != 200) throw Exception('Failed to refresh briefing');
    return jsonDecode(resp.body);
  }

  static Future<Map<String, bool>> getSourcesStatus() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/sources/status').replace(
      queryParameters: {'user_id': userId},
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('Failed to load sources status');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as bool));
  }

  static Future<Map<String, dynamic>> getTelegramBotInfo() async {
    final resp = await http.get(Uri.parse('$_baseUrl/sources/telegram/bot-info'));
    if (resp.statusCode != 200) throw Exception('Failed to get bot info');
    return jsonDecode(resp.body);
  }

  static Future<void> linkTelegram({
    required String userId,
    required String chatId,
  }) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/sources/telegram/link'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'chat_id': chatId}),
    );
    if (resp.statusCode != 200) {
      final body = jsonDecode(resp.body);
      throw Exception(body['detail'] ?? 'Failed to link Telegram');
    }
  }

  static Future<void> unlinkTelegram({required String userId}) async {
    final uri = Uri.parse('$_baseUrl/sources/telegram/unlink').replace(
      queryParameters: {'user_id': userId},
    );
    final resp = await http.delete(uri);
    if (resp.statusCode != 200) throw Exception('Failed to unlink Telegram');
  }
}
