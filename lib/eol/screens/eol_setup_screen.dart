import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/eol_auth_service.dart';
import '../theme/eol_theme.dart';
import '../widgets/brand_header_pill.dart';
import '../widgets/gloved_button.dart';
import 'eol_login_screen.dart';
import 'eol_radar_screen.dart';

class EolSetupScreen extends StatefulWidget {
  const EolSetupScreen({super.key});

  @override
  State<EolSetupScreen> createState() => _EolSetupScreenState();
}

class _EolSetupScreenState extends State<EolSetupScreen> {
  late TextEditingController _stationController;
  late double _rssiSliderValue;

  @override
  void initState() {
    super.initState();
    final session = context.read<EolAuthService>().currentSession;
    _stationController = TextEditingController(
      text: session?.stationId ?? 'Station-1-Line-A',
    );
    _rssiSliderValue = (session?.rssiThresholdDbm ?? -40).toDouble();
  }

  Future<void> _handleSave() async {
    final authService = context.read<EolAuthService>();
    await authService.updateStationSetup(
      stationId: _stationController.text.trim().isEmpty
          ? 'Station-1'
          : _stationController.text.trim(),
      rssiThresholdDbm: _rssiSliderValue.round(),
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EolRadarScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EolTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Station Configuration'),
      ),
      body: Column(
        children: [
          const BrandHeaderPill(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: EolTheme.powerpedalBlueLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      color: EolTheme.powerpedalBlue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Line Station & Signal Gate',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: EolTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Locked for this operational session',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: EolTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Station Identifier Field
                              const Text(
                                'Physical Station / Line Identifier',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: EolTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _stationController,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: EolTheme.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: EolTheme.surfaceSubtle,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(EolTheme.borderRadius),
                                    borderSide: const BorderSide(color: EolTheme.borderSubtle),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(EolTheme.borderRadius),
                                    borderSide: const BorderSide(color: EolTheme.borderSubtle),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(EolTheme.borderRadius),
                                    borderSide: const BorderSide(color: EolTheme.powerpedalBlue, width: 2),
                                  ),
                                  prefixIcon: const Icon(Icons.precision_manufacturing_rounded, size: 20, color: EolTheme.textSecondary),
                                  hintText: 'e.g., Station-1-Line-A',
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Bluetooth RSSI Proximity Slider
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Bluetooth RSSI Proximity Gate',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: EolTheme.textSecondary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: EolTheme.powerpedalBlueLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_rssiSliderValue.round()} dBm',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: EolTheme.powerpedalBlueDark,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: EolTheme.powerpedalBlue,
                                  inactiveTrackColor: EolTheme.borderSubtle,
                                  thumbColor: EolTheme.powerpedalBlue,
                                  trackHeight: 6,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                ),
                                child: Slider(
                                  value: _rssiSliderValue,
                                  min: -60,
                                  max: -30,
                                  divisions: 30,
                                  onChanged: (val) {
                                    setState(() => _rssiSliderValue = val);
                                  },
                                ),
                              ),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '-60 dBm (Wider 1.5m Range)',
                                    style: TextStyle(fontSize: 11, color: EolTheme.textMuted),
                                  ),
                                  Text(
                                    '-30 dBm (Touching Casing)',
                                    style: TextStyle(fontSize: 11, color: EolTheme.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Explanatory Note Box
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: EolTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: EolTheme.borderSubtle),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18, color: EolTheme.powerpedalBlue),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Default of -40 dBm ensures the tablet only discovers the bike directly in front of you (within 5-10 cm), filtering out all other bikes on the active assembly line.',
                                        style: TextStyle(fontSize: 11.5, color: EolTheme.textSecondary, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Save Button
                              GlovedButton(
                                label: 'Save & Enter Assembly Radar',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _handleSave,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.logout_rounded, size: 18, color: EolTheme.textMuted),
                                  label: const Text(
                                    'Sign Out Assembler Session',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: EolTheme.textMuted,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final nav = Navigator.of(context);
                                    await context.read<EolAuthService>().logout();
                                    if (mounted) {
                                      nav.pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const EolLoginScreen()),
                                        (route) => false,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stationController.dispose();
    super.dispose();
  }
}
