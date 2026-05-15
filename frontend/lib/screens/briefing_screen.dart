import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class BriefingScreen extends StatefulWidget {
  const BriefingScreen({super.key});

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  String? _content;
  bool _loading = true;
  bool _fromCache = false;
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
      setState(() {
        _content = data['content'] ?? '';
        _fromCache = data['from_cache'] ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Briefing'),
        actions: [
          if (_fromCache)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('cached', style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _load(force: true),
            tooltip: 'Regenerate',
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _buildMarkdown(),
    );
  }

  Widget _buildMarkdown() {
    return Markdown(
      data: _content ?? '',
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      styleSheet: MarkdownStyleSheet(
        h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 2),
        h3: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.2, height: 2.5),
        p: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
        listBullet: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        strong: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.upcoming, width: 3)),
          color: AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surface2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 28, width: 200, color: AppColors.surface),
            const SizedBox(height: 24),
            ...List.generate(6, (i) => Container(
              height: 16,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              color: AppColors.surface,
            )),
          ],
        ),
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
