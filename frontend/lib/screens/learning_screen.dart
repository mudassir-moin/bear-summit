import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../demo/demo_data.dart';

const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  List<Map<String, dynamic>> _materials = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> get _userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<bool> get _isDemoMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('demo_mode') ?? false;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (await _isDemoMode) {
        setState(() {
          _materials = List<Map<String, dynamic>>.from(kDemoLearningMaterials);
          _loading = false;
        });
        return;
      }

      final userId = await _userId;
      if (userId == null) return;

      final resp = await http.get(
        Uri.parse('$_baseUrl/learning').replace(
          queryParameters: {'user_id': userId},
        ),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _materials = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _materials = List<Map<String, dynamic>>.from(kDemoLearningMaterials);
        _loading = false;
      });
    }
  }

  Future<void> _uploadPdf() async {
    // File picker — use a simple dialog for web compatibility
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Upload PDF',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'On mobile: tap OK then select a PDF from your files.\n\nOn web: PDF upload is not yet supported in the browser demo — use the mobile APK.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: AppColors.upcoming)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeReview(String materialId) async {
    if (await _isDemoMode) {
      _showSnack('Review marked complete — next review in 3 days');
      return;
    }

    final userId = await _userId;
    if (userId == null) return;

    final resp = await http.post(
      Uri.parse('$_baseUrl/learning/complete/$materialId').replace(
        queryParameters: {'user_id': userId},
      ),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      _showSnack('Done! Next review: ${data['next_review_date']}');
      _load();
    }
  }

  Future<void> _deleteMaterial(String materialId) async {
    if (await _isDemoMode) {
      _showSnack('Cannot delete demo materials');
      return;
    }

    final userId = await _userId;
    if (userId == null) return;

    await http.delete(
      Uri.parse('$_baseUrl/learning/$materialId').replace(
        queryParameters: {'user_id': userId},
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
        actions: [
          IconButton(
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textPrimary))
                : const Icon(Icons.upload_file_outlined, size: 22),
            onPressed: _uploading ? null : _uploadPdf,
            tooltip: 'Upload PDF',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.upcoming,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _materials.length,
                    itemBuilder: (ctx, i) =>
                        _MaterialCard(
                          material: _materials[i],
                          onReviewComplete: _completeReview,
                          onDelete: _deleteMaterial,
                        ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.menu_book_outlined,
                  size: 32, color: AppColors.opportunity),
            ),
            const SizedBox(height: 24),
            Text('No learning materials yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Upload a lecture PDF and the AI will extract key concepts and generate review questions.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _uploadPdf,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Upload PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.opportunity,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg), backgroundColor: AppColors.upcoming),
    );
  }
}

// ── Material Card ─────────────────────────────────────────────────────────────

class _MaterialCard extends StatefulWidget {
  final Map<String, dynamic> material;
  final Future<void> Function(String) onReviewComplete;
  final Future<void> Function(String) onDelete;

  const _MaterialCard({
    required this.material,
    required this.onReviewComplete,
    required this.onDelete,
  });

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  bool _expanded = false;
  int? _activeQuestion;
  bool _showAnswer = false;

  bool get _isDueToday {
    final next = widget.material['next_review_date'] as String?;
    if (next == null) return false;
    return next.compareTo(DateTime.now().toIso8601String().substring(0, 10)) <=
        0;
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.material['id'] as String? ?? '';
    final title = widget.material['title'] as String? ?? 'Untitled';
    final summary = widget.material['summary'] as String? ?? '';
    final concepts =
        List<Map<String, dynamic>>.from(widget.material['key_concepts'] ?? []);
    final questions = List<Map<String, dynamic>>.from(
        widget.material['review_questions'] ?? []);
    final nextReview = widget.material['next_review_date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: _isDueToday
            ? Border.all(color: AppColors.important.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.opportunity.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_outlined,
                        size: 18, color: AppColors.opportunity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (_isDueToday) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.important.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('REVIEW DUE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.important)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '${concepts.length} concepts · ${questions.length} questions',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ──────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  if (summary.isNotEmpty) ...[
                    Text(summary,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                  ],

                  // Key concepts
                  if (concepts.isNotEmpty) ...[
                    Text('KEY CONCEPTS',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 10),
                    ...concepts.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6, right: 10),
                                decoration: const BoxDecoration(
                                  color: AppColors.opportunity,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${c['concept']}  ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextSpan(
                                        text: c['explanation'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Review questions
                  if (questions.isNotEmpty) ...[
                    Text('REVIEW QUESTIONS',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 10),
                    ...questions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final q = entry.value;
                      final isActive = _activeQuestion == i;
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (_activeQuestion == i) {
                            _activeQuestion = null;
                            _showAnswer = false;
                          } else {
                            _activeQuestion = i;
                            _showAnswer = false;
                          }
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.surface2
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.opportunity.withOpacity(0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${i + 1}.',
                                    style: const TextStyle(
                                      color: AppColors.opportunity,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      q['question'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isActive) ...[
                                const SizedBox(height: 10),
                                if (!_showAnswer)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _showAnswer = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.opportunity
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.opportunity
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility_outlined,
                                              size: 14,
                                              color: AppColors.opportunity),
                                          SizedBox(width: 6),
                                          Text('Show answer',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.opportunity,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.upcoming.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            AppColors.upcoming.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      q['answer'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onComplete(id),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: const Text('Mark reviewed'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.upcoming,
                            side: BorderSide(
                                color: AppColors.upcoming.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _onDelete(id),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.textSecondary),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),

                  if (nextReview.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Next review: $nextReview',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onComplete(String id) {
    widget.onReviewComplete(id);
    setState(() {
      _expanded = false;
      _activeQuestion = null;
      _showAnswer = false;
    });
  }

  void _onDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete material?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'This will permanently remove this learning material and its review schedule.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.urgent)),
          ),
        ],
      ),
    );
  }
}
