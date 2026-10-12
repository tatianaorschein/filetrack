import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/transmission.dart';

class ApiService {
  static final ApiService instance = ApiService._init();

  ApiService._init();

  static const String defaultBaseUrl = "https://filetrack.hydro-mekin.cm/api/v1";

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url') ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url.trim());
  }

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_key') ?? '';
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key.trim());
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Génère les en-têtes HTTP incluant la clé API Supabase (apikey) et le Bearer Token
  Future<Map<String, String>> _getHeaders() async {
    final apiKey = await getApiKey();
    final token = await getToken();

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (apiKey.isNotEmpty) {
      headers['apikey'] = apiKey;
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    return headers;
  }

  /// Connexion REST et récupération du token JWT
  Future<bool> login(String userId, String pin) async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({'user_id': userId, 'pin': pin}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await setToken(data['token']);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// PUSH : Envoi au serveur central des dossiers et transmissions locaux non synchronisés
  Future<List<String>?> pushLocalData({
    required List<Dossier> dossiers,
    required List<Transmission> transmissions,
  }) async {
    if (dossiers.isEmpty && transmissions.isEmpty) return [];

    try {
      final baseUrl = await getBaseUrl();
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/sync/push'),
        headers: headers,
        body: jsonEncode({
          'dossiers': dossiers.map((d) => d.toMap()).toList(),
          'transmissions': transmissions.map((t) => t.toMap()).toList(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['synced_ids'] != null) {
          return List<String>.from(data['synced_ids']);
        }
      }
    } catch (_) {}
    return null;
  }

  /// PULL : Récupération depuis le serveur central des modifications distantes depuis [since]
  Future<Map<String, dynamic>?> pullRemoteData(String sinceTimestamp) async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await _getHeaders();

      final Uri uri = Uri.parse('$baseUrl/sync/pull').replace(
        queryParameters: {'since': sinceTimestamp},
      );

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Upload Multipart de pièce jointe PDF
  Future<bool> uploadAttachment({
    required String dossierId,
    required String transmissionId,
    required File file,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final apiKey = await getApiKey();
      final token = await getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/attachments/upload'),
      );

      if (apiKey.isNotEmpty) {
        request.headers['apikey'] = apiKey;
      }

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      } else if (apiKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $apiKey';
      }

      request.fields['dossier_id'] = dossierId;
      request.fields['transmission_id'] = transmissionId;

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
