import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/briefing_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/sources_screen.dart';
import 'services/auth_service.dart';
import 'widgets/notification_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CogniOSApp());
}

class CogniOSApp extends StatelessWidget {
  const CogniOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniOS',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _signedIn;

  @override
  void initState() {
    super.initState();
    AuthService.isSignedIn().then((v) => setState(() => _signedIn = v));
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_signedIn!) {
      return LoginScreen(onLogin: () => setState(() => _signedIn = true));
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  NotificationBannerData? _banner;

  static const _screens = [
    DashboardScreen(),
    BriefingScreen(),
    LearningScreen(),
    SourcesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Show a simulated urgent alert after 3 seconds to demo in-app notifications
    Future.delayed(const Duration(seconds: 3), _checkForUrgentItems);
  }

  void _checkForUrgentItems() {
    if (!mounted) return;
    setState(() {
      _banner = NotificationBannerData(
        title: 'Assignment deadline in 2 hours',
        body: 'CS301 submission closes at 11:59 PM tonight.',
        type: NotificationBannerType.urgent,
      );
    });
  }

  void _dismissBanner() => setState(() => _banner = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          if (_banner != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: NotificationBanner(
                data: _banner!,
                onDismiss: _dismissBanner,
                onTap: () {
                  _dismissBanner();
                  setState(() => _index = 0); // go to dashboard
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              label: 'Briefing',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Learning',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.link_rounded),
              label: 'Sources',
            ),
          ],
        ),
      ),
    );
  }
}
