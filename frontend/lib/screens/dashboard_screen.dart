import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_card.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSignOut;
  const DashboardScreen({super.key, this.onSignOut});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getBriefing(force: force);
      final raw = List<Map<String, dynamic>>.from(data['items'] ?? []);
      setState(() { _items = raw; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> _byPriority(String p) =>
      _items.where((i) => i['priority'] == p).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _load(force: true),
            tooltip: 'Refresh briefing',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline, size: 22),
            tooltip: 'Account',
            onSelected: (value) async {
              if (value == 'signout') {
                await AuthService.signOut();
                if (mounted) widget.onSignOut?.call();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: () => _load(force: true),
                  color: AppColors.upcoming,
                  backgroundColor: AppColors.surface,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: AppColors.upcoming),
            const SizedBox(height: 16),
            Text('You\'re all caught up.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Pull down to refresh your briefing.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ..._section('urgent', AppColors.urgent),
        ..._section('missed', AppColors.missed),
        ..._section('important', AppColors.important),
        ..._section('upcoming', AppColors.upcoming),
        ..._section('opportunity', AppColors.opportunity),
      ],
    );
  }

  List<Widget> _section(String priority, Color color) {
    final items = _byPriority(priority);
    if (items.isEmpty) return [];
    return [
      SectionHeader(label: priority, color: color),
      ...items.map((item) => PriorityCard(
        title: item['title'] ?? '',
        body: item['body'],
        source: item['source'] ?? 'other',
        priority: priority,
        deadline: item['deadline'],
        actionRequired: item['action_required'] ?? false,
      )),
    ];
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surface2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(5, (_) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        )),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Could not load briefing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error ?? '', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
