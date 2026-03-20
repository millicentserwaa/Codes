import 'package:flutter/material.dart';
//import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class TtsButton extends StatefulWidget {
  final Future<void> Function() onSpeak; // what to say
  final double size;

  const TtsButton({
    super.key,
    required this.onSpeak,
    this.size = 20,
  });

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  bool _isSpeaking = false;

  Future<void> _handleTap() async {
    setState(() => _isSpeaking = true);
    try {
      await widget.onSpeak();
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isSpeaking ? null : _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isSpeaking
              ? AppTheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _isSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
          size: widget.size,
          color: _isSpeaking ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
