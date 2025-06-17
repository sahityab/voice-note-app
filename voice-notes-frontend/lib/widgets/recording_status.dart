import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RecordingStatus extends StatelessWidget {
  final String status;
  final bool isRecording;

  const RecordingStatus({
    Key? key,
    required this.status,
    required this.isRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isRecording 
            ? Colors.red.withOpacity(0.1) 
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isRecording) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            status,
            style: AppTextStyles.label2.copyWith(
              color: isRecording ? Colors.red : AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}