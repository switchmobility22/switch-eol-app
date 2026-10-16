import 'package:flutter/material.dart';
import '../services/eol_audio_service.dart';
import '../theme/eol_theme.dart';

class GlovedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const GlovedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (isSecondary ? EolTheme.surfaceSubtle : EolTheme.powerpedalBlue);
    final fgColor = foregroundColor ??
        (isSecondary ? EolTheme.textPrimary : EolTheme.textOnBlue);

    return SizedBox(
      height: EolTheme.buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: isSecondary ? 0 : 2,
          shadowColor: EolTheme.powerpedalBlue.withAlpha(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EolTheme.borderRadius),
            side: isSecondary
                ? const BorderSide(color: EolTheme.borderSubtle, width: 1.5)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: isLoading || onPressed == null
            ? null
            : () {
                EolAudioService.playTactileClick();
                onPressed!();
              },
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: fgColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: fgColor),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
