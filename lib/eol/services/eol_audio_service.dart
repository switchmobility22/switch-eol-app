import 'package:flutter/services.dart';

class EolAudioService {
  // Melodic high-frequency PASS confirmation (1200Hz feel)
  static Future<void> playPassChime() async {
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  // Low-frequency sharp warning BUZZ (300Hz feel)
  static Future<void> playErrorBuzzer() async {
    try {
      await HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 250));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  // Single tactile click for gloved button press
  static Future<void> playTactileClick() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
