import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

class NoteCard extends StatelessWidget {
  final String summary;
  final String timestamp;
  final String group;
  final bool hasReminder;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const NoteCard({
    Key? key,
    required this.summary,
    required this.timestamp,
    required this.group,
    this.hasReminder = false,
    this.onTap,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.noteCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                AppSpacing.gap8,
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            summary,
            style: AppTextStyles.noteText,
          ),
        ),
        AppSpacing.hGap8,
        _buildActions(),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasReminder) ...[
          Icon(
            Icons.alarm,
            size: 16,
            color: AppColors.primary,
          ),
          AppSpacing.hGap4,
        ],
        IconButton(
          icon: const Icon(Icons.more_vert),
          iconSize: 16,
          color: AppColors.textLight,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
          onPressed: onMoreTap,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Text(timestamp, style: AppTextStyles.timestamp),
        AppSpacing.hGap4,
        Text('•', style: AppTextStyles.timestamp),
        AppSpacing.hGap4,
        Text(group, style: AppTextStyles.category),
      ],
    );
  }
}