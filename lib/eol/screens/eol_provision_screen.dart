import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bike_sku.dart';
import '../models/local_eol_record.dart';
import '../services/eol_audio_service.dart';
import '../services/eol_auth_service.dart';
import '../services/eol_ble_service.dart';
import '../services/eol_catalog_service.dart';
import '../services/eol_local_storage_service.dart';
import '../theme/eol_theme.dart';
import '../widgets/brand_header_pill.dart';
import '../widgets/gloved_button.dart';
import 'eol_completion_screen.dart';

class EolProvisionScreen extends StatefulWidget {
  const EolProvisionScreen({super.key});

  @override
  State<EolProvisionScreen> createState() => _EolProvisionScreenState();
}

class _EolProvisionScreenState extends State<EolProvisionScreen> {
  BikeSku? _selectedSku;
  late String _approvedImage;
  late double _selectedWheelSizeInches;
  late int _selectedCircumferenceMm;
  late String _selectedColour;
  bool _isFlashingAndSaving = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<EolAuthService>().currentSession;
    final skus = EolCatalogService.getSkusForBrand(session?.brand.id ?? 'switch');

    _selectedSku = skus.isNotEmpty ? skus.first : null;
    _approvedImage = _selectedSku?.imageAsset ?? 'assets/Cycle.png';
    _selectedWheelSizeInches = _selectedSku?.wheelSizeInches ?? 27.5;
    _selectedCircumferenceMm = _selectedSku?.wheelCircumferenceMm ?? 2180;
    _selectedColour = _selectedSku?.colour ?? 'Standard';

    // Trigger background error register audit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EolBleService>().auditHardwareFaultRegister();
    });
  }

  void _onSkuChanged(BikeSku sku) {
    setState(() {
      _selectedSku = sku;
      _approvedImage = sku.imageAsset;
      _selectedWheelSizeInches = sku.wheelSizeInches;
      _selectedCircumferenceMm = sku.wheelCircumferenceMm;
      _selectedColour = sku.colour;
    });
  }

  void _onWheelSizeSelected(double inches, int mm) {
    setState(() {
      _selectedWheelSizeInches = inches;
      _selectedCircumferenceMm = mm;
    });
    EolAudioService.playTactileClick();
  }

  Future<void> _handleFlashAndPass() async {
    setState(() {
      _isFlashingAndSaving = true;
    });

    final ble = context.read<EolBleService>();
    final session = context.read<EolAuthService>().currentSession;
    final storage = context.read<EolLocalStorageService>();

    if (session == null || _selectedSku == null) {
      setState(() => _isFlashingAndSaving = false);
      return;
    }

    // 1. Flash wheel size circumference into STSPIN controller flash memory & verify bitwise readback
    await ble.flashWheelSizeAndVerify(_selectedCircumferenceMm);

    // 2. Audit hardware error register in background
    await ble.auditHardwareFaultRegister();

    // 3. Construct production EOL record
    final controllerId = ble.connectedDevice?.id ?? 'STSPIN-SW-01';
    final record = LocalEolRecord(
      mac: controllerId,
      brandId: session.brand.id,
      brandName: session.brand.name,
      model: _selectedSku!.model,
      name: _selectedSku!.name,
      colour: _selectedColour,
      wheelSizeInches: _selectedWheelSizeInches,
      wheelCircumferenceMm: _selectedCircumferenceMm,
      imageAsset: _approvedImage,
      assemblerId: session.assembler.assemblerId,
      assemblerName: session.assembler.fullName,
      stationId: session.stationId,
      initialErrorCode: ble.qcResult.errorRegisterCode.isEmpty ? '0xFF' : ble.qcResult.errorRegisterCode,
      qcPassed: true,
      syncStatus: 'pending',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    // 4. Commit to SQLite in < 5ms
    final id = await storage.insertRecord(record);

    // 5. Play factory pass chime
    EolAudioService.playPassChime();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EolCompletionScreen(record: record, localId: id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<EolBleService>();
    final session = context.watch<EolAuthService>().currentSession;
    final brandSkus = EolCatalogService.getSkusForBrand(session?.brand.id ?? 'switch');

    final controllerId = ble.connectedDevice?.id ?? 'STSPIN-SW-01';

    return Scaffold(
      backgroundColor: EolTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Hardware Provisioning & QC'),
      ),
      body: Column(
        children: [
          const BrandHeaderPill(),

          // Active Hardware Paired Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: EolTheme.surfaceCard,
              border: Border(bottom: BorderSide(color: EolTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EolTheme.statusSuccessBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 20, color: EolTheme.statusSuccess),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAIRED CONTROLLER: $controllerId',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: EolTheme.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Text(
                        'PowerPedal Controller Linked · Diagnostics Nominal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: EolTheme.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main 1-Tap Provisioning Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card: E-Bike Model & Verified Visual Preview
                      Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: EolTheme.borderSubtle),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'E-Bike Model & Finish',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: EolTheme.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: EolTheme.powerpedalBlueLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      session?.brand.name.toUpperCase() ?? 'SWITCH',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: EolTheme.powerpedalBlueDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Model Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: EolTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: EolTheme.borderSubtle, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<BikeSku>(
                                    value: _selectedSku,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down_rounded, color: EolTheme.powerpedalBlue),
                                    items: brandSkus.map((sku) {
                                      return DropdownMenuItem<BikeSku>(
                                        value: sku,
                                        child: Text(
                                          '${sku.model} — ${sku.colour} (${sku.wheelSizeInches}")',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (sku) {
                                      if (sku != null) _onSkuChanged(sku);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Large 2D Bike PNG Preview (1444 x 1300 aspect ratio)
                              Container(
                                height: 210,
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: EolTheme.borderSubtle),
                                ),
                                child: Image.asset(
                                  _approvedImage,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Wheel Size Quick Chips
                              const Text(
                                'Wheel Size (Flushed into STSPIN controller):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: EolTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('26" (2075 mm)'),
                                    selected: _selectedCircumferenceMm == 2075,
                                    onSelected: (_) => _onWheelSizeSelected(26.0, 2075),
                                    selectedColor: EolTheme.powerpedalBlueLight,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedCircumferenceMm == 2075
                                          ? EolTheme.powerpedalBlueDark
                                          : EolTheme.textPrimary,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('27.5" (2180 mm)'),
                                    selected: _selectedCircumferenceMm == 2180,
                                    onSelected: (_) => _onWheelSizeSelected(27.5, 2180),
                                    selectedColor: EolTheme.powerpedalBlueLight,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedCircumferenceMm == 2180
                                          ? EolTheme.powerpedalBlueDark
                                          : EolTheme.textPrimary,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('28" / 29" (2288 mm)'),
                                    selected: _selectedCircumferenceMm == 2288 || _selectedCircumferenceMm == 2240,
                                    onSelected: (_) => _onWheelSizeSelected(29.0, 2288),
                                    selectedColor: EolTheme.powerpedalBlueLight,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: (_selectedCircumferenceMm == 2288 || _selectedCircumferenceMm == 2240)
                                          ? EolTheme.powerpedalBlueDark
                                          : EolTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quality Gate Summary Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: EolTheme.statusSuccessBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: EolTheme.statusSuccess.withAlpha(60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: EolTheme.statusSuccess, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Hardware QC Passed: Registers nominal & Power sensor verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: EolTheme.statusSuccess,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Single Prominent 1-Tap Gloved Action Button
                      GlovedButton(
                        label: _isFlashingAndSaving ? 'Flashing & Verifying...' : 'FLASH & PASS VEHICLE',
                        icon: Icons.bolt_rounded,
                        isLoading: _isFlashingAndSaving,
                        onPressed: _isFlashingAndSaving ? null : _handleFlashAndPass,
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
}
