import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  bool _googleConnected = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final signedIn = await AuthService.isSignedIn();
    setState(() { _googleConnected = signedIn; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildSectionLabel('CONNECTED'),
          const SizedBox(height: 8),
          _sourceTile(
            icon: Icons.email_outlined,
            color: const Color(0xFFEA4335),
            title: 'Gmail',
            subtitle: _googleConnected ? 'Reading recent emails' : 'Not connected',
            connected: _googleConnected,
            onTap: _googleConnected ? null : _connectGoogle,
          ),
          _sourceTile(
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF4285F4),
            title: 'Google Calendar',
            subtitle: _googleConnected ? 'Reading next 7 days' : 'Requires Gmail connection',
            connected: _googleConnected,
            onTap: null,
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('COMING SOON'),
          const SizedBox(height: 8),
          _sourceTile(
            icon: Icons.send_outlined,
            color: const Color(0xFF2AABEE),
            title: 'Telegram',
            subtitle: 'Connect your Telegram account',
            connected: false,
            comingSoon: true,
          ),
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

  Widget _buildSectionLabel(String label) {
    return Text(label, style: Theme.of(context).textTheme.labelSmall);
  }

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
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: comingSoon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6)),
                child: const Text('Soon', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              )
            : connected
                ? const Icon(Icons.check_circle, color: AppColors.upcoming, size: 20)
                : const Icon(Icons.add_circle_outline, color: AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }

  Future<void> _connectGoogle() async {
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null) {
        setState(() { _googleConnected = true; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google account connected'), backgroundColor: AppColors.upcoming),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e'), backgroundColor: AppColors.urgent),
        );
      }
    }
  }
}
