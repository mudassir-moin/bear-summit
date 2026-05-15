import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  bool _googleConnected = false;
  bool _telegramConnected = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final signedIn = await AuthService.isSignedIn();
      final status = signedIn ? await ApiService.getSourcesStatus() : <String, bool>{};
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _googleConnected = status['gmail'] ?? signedIn;
        _telegramConnected = status['telegram'] ?? (prefs.getString('telegram_chat_id') != null);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildSectionLabel('CONNECTED'),
                const SizedBox(height: 8),
                _sourceTile(
                  icon: Icons.email_outlined,
                  color: const Color(0xFFEA4335),
                  title: 'Gmail',
                  subtitle: _googleConnected ? 'Reading recent emails' : 'Tap to connect',
                  connected: _googleConnected,
                  onTap: _googleConnected ? null : _connectGoogle,
                ),
                _sourceTile(
                  icon: Icons.calendar_today_outlined,
                  color: const Color(0xFF4285F4),
                  title: 'Google Calendar',
                  subtitle: _googleConnected ? 'Reading next 7 days' : 'Requires Gmail connection',
                  connected: _googleConnected,
                ),
                _sourceTile(
                  icon: Icons.send_outlined,
                  color: const Color(0xFF2AABEE),
                  title: 'Telegram',
                  subtitle: _telegramConnected
                      ? 'Reading your messages'
                      : 'Tap to link your account',
                  connected: _telegramConnected,
                  onTap: _telegramConnected ? _unlinkTelegram : _showTelegramLinkSheet,
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('COMING SOON'),
                const SizedBox(height: 8),
                _sourceTile(
                  icon: Icons.description_outlined,
                  color: AppColors.opportunity,
                  title: 'PDF / Notes',
                  subtitle: 'Upload lecture notes and documents',
                  connected: false,
                  comingSoon: true,
                ),
              ],
            ),
    );
  }

  Widget _buildSectionLabel(String label) =>
      Text(label, style: Theme.of(context).textTheme.labelSmall);

  Widget _sourceTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool connected,
    bool comingSoon = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: comingSoon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Soon',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              )
            : connected
                ? const Icon(Icons.check_circle, color: AppColors.upcoming, size: 20)
                : const Icon(Icons.add_circle_outline,
                    color: AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<void> _connectGoogle() async {
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null) setState(() => _googleConnected = true);
    } catch (e) {
      _showSnack('Failed to connect: $e', error: true);
    }
  }

  // ── Telegram ──────────────────────────────────────────────────────────────

  Future<void> _showTelegramLinkSheet() async {
    final chatIdController = TextEditingController();

    // Fetch bot username so we can show the correct deep-link
    String botLink = 'https://t.me/CogniOSBot';
    try {
      final info = await ApiService.getTelegramBotInfo();
      botLink = info['link'] ?? botLink;
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Link Telegram', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _step('1', 'Open Telegram and message', botLink),
            const SizedBox(height: 12),
            _step('2', 'Send the bot your Telegram user ID', 'Message @userinfobot to get it'),
            const SizedBox(height: 12),
            _step('3', 'Enter your chat ID below', ''),
            const SizedBox(height: 16),
            TextField(
              controller: chatIdController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 123456789',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final chatId = chatIdController.text.trim();
                  if (chatId.isEmpty) return;
                  Navigator.pop(ctx);
                  await _linkTelegram(chatId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2AABEE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Link account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2AABEE).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Text(num,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2AABEE))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: sub.startsWith('http') ? () => _copyToClipboard(sub) : null,
                  child: Text(
                    sub,
                    style: TextStyle(
                      fontSize: 13,
                      color: sub.startsWith('http')
                          ? const Color(0xFF2AABEE)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _linkTelegram(String chatId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return;

      await ApiService.linkTelegram(userId: userId, chatId: chatId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('telegram_chat_id', chatId);

      setState(() => _telegramConnected = true);
      _showSnack('Telegram linked — check your bot for a confirmation message');
    } catch (e) {
      _showSnack('Could not link: $e', error: true);
    }
  }

  Future<void> _unlinkTelegram() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unlink Telegram?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Telegram messages will no longer be included in your briefing.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink', style: TextStyle(color: AppColors.urgent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = await _getUserId();
      if (userId == null) return;
      await ApiService.unlinkTelegram(userId: userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('telegram_chat_id');
      setState(() => _telegramConnected = false);
      _showSnack('Telegram unlinked');
    } catch (e) {
      _showSnack('Failed: $e', error: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.urgent : AppColors.upcoming,
    ));
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copied to clipboard');
  }
}
