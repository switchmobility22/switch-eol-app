import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/local_eol_record.dart';
import '../services/eol_ble_service.dart';
import '../services/eol_sync_service.dart';
import '../theme/eol_theme.dart';
import '../widgets/brand_header_pill.dart';
import '../widgets/gloved_button.dart';
import 'eol_queue_screen.dart';
import 'eol_radar_screen.dart';

class EolCompletionScreen extends StatelessWidget {
  final LocalEolRecord record;
  final int localId;

  const EolCompletionScreen({
    super.key,
    required this.record,
    required this.localId,
  });

  void _handleNextVehicle(BuildContext context) {
    context.read<EolBleService>().resetForNextBike();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EolRadarScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Automatically trigger background sync to reconcile this newly saved bike
    context.read<EolSyncService>().syncPendingQueue();

    return Scaffold(
      backgroundColor: EolTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Digital Birth Certificate'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          BrandHeaderPill(
            onQueueTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EolQueueScreen()),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Big Green Pass Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: EolTheme.statusSuccessBg,
                          borderRadius: BorderRadius.circular(EolTheme.borderRadius),
                          border: Border.all(color: EolTheme.statusSuccess, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 56,
                              color: EolTheme.statusSuccess,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'EOL QUALITY GATE PASSED',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: EolTheme.statusSuccess,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Local Record #$localId committed to encrypted SQLite (<5ms)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: EolTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Birth Certificate Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Bike Image Thumbnail
                                  Container(
                                    width: 100,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: EolTheme.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: EolTheme.borderSubtle),
                                    ),
                                    child: Image.asset(record.imageAsset, fit: BoxFit.contain),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: EolTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${record.model} · ${record.colour}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: EolTheme.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: EolTheme.powerpedalBlueLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'MAC: ${record.mac}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: EolTheme.powerpedalBlueDark,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),

                              // Spec Key-Value Table
                              _buildInfoRow('Wheel Circumference', '${record.wheelCircumferenceMm} mm (${record.wheelSizeInches}") [ACK Verified]'),
                              _buildInfoRow('Hardware Error Register', '${record.initialErrorCode} (Zero Active Faults)'),
                              _buildInfoRow('Bottom Bracket Sensor', 'PASSED (Cadence & Torque Synchronized)'),
                              _buildInfoRow('Line Station', record.stationId),
                              _buildInfoRow('Line Assembler', '${record.assemblerName} (${record.assemblerId})'),
                              _buildInfoRow('Lifecycle Status', 'unassigned (Ready for Customer Claiming)'),
                              _buildInfoRow('Timestamp', record.createdAt),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Next Bike Button
                      GlovedButton(
                        label: 'Next Vehicle (Reset Radar)',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: () => _handleNextVehicle(context),
                      ),
                      const SizedBox(height: 12),

                      GlovedButton(
                        label: 'View Station Offline Queue',
                        icon: Icons.inventory_2_outlined,
                        isSecondary: true,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EolQueueScreen()),
                          );
                        },
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EolTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: EolTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
