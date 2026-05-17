import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

const _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

final _googleSignIn = GoogleSignIn(
  clientId: _clientId,
  scopes: [
    'email',
    'profile',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/calendar.readonly',
  ],
);

class AuthService {
  static Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') != null;
  }

  /// Skip Google auth entirely — shows demo data locally, no backend needed.
  static Future<void> signInAsDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', 'demo');
    await prefs.setString('user_name', 'Demo User');
    await prefs.setString('user_email', 'demo@cognios.app');
    await prefs.setBool('demo_mode', true);
  }

  static Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('demo_mode') ?? false;
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    if (_clientId.isEmpty) {
      throw Exception(
        'Google Sign-In is not configured for this build. '
        'Use "Try Demo" instead, or add GOOGLE_CLIENT_ID to GitHub Secrets.',
      );
    }
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final code = auth.serverAuthCode;
    if (code == null) throw Exception('No server auth code received');

    const redirectUri = 'http://localhost';
    final result = await ApiService.googleAuth(code, redirectUri);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', result['user_id']);
    await prefs.setString('user_name', result['name'] ?? '');
    await prefs.setString('user_email', result['email'] ?? '');

    return result;
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getBool('demo_mode') ?? false;
    if (!isDemo) await _googleSignIn.signOut();
    await prefs.clear();
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }
}
