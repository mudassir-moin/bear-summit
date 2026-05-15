import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriorityCard extends StatelessWidget {
  final String title;
  final String? body;
  final String source;
  final String priority;
  final String? deadline;
  final bool actionRequired;

  const PriorityCard({
    super.key,
    required this.title,
    this.body,
    required this.source,
    required this.priority,
    this.deadline,
    this.actionRequired = false,
  });

  IconData get _sourceIcon {
    switch (source) {
      case 'gmail': return Icons.email_outlined;
      case 'calendar': return Icons.calendar_today_outlined;
      case 'telegram': return Icons.send_outlined;
      case 'pdf': return Icons.description_outlined;
      default: return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (body != null && body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (deadline != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        deadline!,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(_sourceIcon, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const SectionHeader({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
