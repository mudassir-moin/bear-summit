import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NotificationBannerType { urgent, important, reminder, learning }

class NotificationBannerData {
  final String title;
  final String body;
  final NotificationBannerType type;

  const NotificationBannerData({
    required this.title,
    required this.body,
    this.type = NotificationBannerType.urgent,
  });
}

class NotificationBanner extends StatefulWidget {
  final NotificationBannerData data;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const NotificationBanner({
    super.key,
    required this.data,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    // Auto-dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _animatedDismiss();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animatedDismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  Color get _accentColor {
    switch (widget.data.type) {
      case NotificationBannerType.urgent:
        return AppColors.urgent;
      case NotificationBannerType.important:
        return AppColors.important;
      case NotificationBannerType.learning:
        return AppColors.opportunity;
      case NotificationBannerType.reminder:
        return AppColors.upcoming;
    }
  }

  IconData get _icon {
    switch (widget.data.type) {
      case NotificationBannerType.urgent:
        return Icons.warning_amber_rounded;
      case NotificationBannerType.important:
        return Icons.info_outline_rounded;
      case NotificationBannerType.learning:
        return Icons.menu_book_outlined;
      case NotificationBannerType.reminder:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accentColor.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icon, size: 18, color: _accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.data.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _animatedDismiss,
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
