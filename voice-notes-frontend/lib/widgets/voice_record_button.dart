import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VoiceRecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const VoiceRecordButton({
    Key? key,
    required this.isRecording,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (!widget.isRecording) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _animationController.stop();
        _animationController.value = 0;
      } else {
        _animationController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isRecording ? 1.0 : _scaleAnimation.value,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: widget.isRecording ? Colors.red : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isRecording ? Colors.red : AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}