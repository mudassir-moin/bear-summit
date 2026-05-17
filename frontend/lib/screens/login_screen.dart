import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loadingGoogle = false;
  bool _loadingDemo = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null && mounted) widget.onLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _tryDemo() async {
    setState(() => _loadingDemo = true);
    await AuthService.signInAsDemo();
    if (mounted) widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.psychology_outlined,
                    size: 28, color: AppColors.upcoming),
              ),
              const SizedBox(height: 32),
              Text('CogniOS',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'Your AI second brain.\nNothing important slips through.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 16, height: 1.6),
              ),
              const Spacer(flex: 2),
              _FeatureRow(
                icon: Icons.filter_alt_outlined,
                text: 'Filters noise from Gmail, Calendar & Telegram',
              ),
              const SizedBox(height: 16),
              _FeatureRow(
                icon: Icons.notification_important_outlined,
                text: 'Surfaces hidden deadlines before they slip',
              ),
              const SizedBox(height: 16),
              _FeatureRow(
                icon: Icons.psychology_outlined,
                text: 'Reinforces learning with spaced repetition',
              ),
              const Spacer(flex: 2),

              // ── Try Demo (primary CTA) ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_loadingDemo || _loadingGoogle) ? null : _tryDemo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.upcoming,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loadingDemo
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Try Demo',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Continue with Google (only shown when client ID is configured) ──
              if (googleSignInAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed:
                        (_loadingDemo || _loadingGoogle) ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loadingGoogle
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.textPrimary))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata, size: 22),
                              SizedBox(width: 8),
                              Text('Continue with Google',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Center(
                child: Text(
                  'Demo uses sample data • No account needed',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.upcoming),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
