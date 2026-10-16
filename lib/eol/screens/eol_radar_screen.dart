import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/eol_auth_service.dart';
import '../services/eol_ble_service.dart';
import '../theme/eol_theme.dart';
import '../widgets/brand_header_pill.dart';
import '../widgets/gloved_button.dart';
import '../widgets/rssi_signal_meter.dart';
import 'eol_provision_screen.dart';
import 'eol_queue_screen.dart';
import 'eol_setup_screen.dart';

class EolRadarScreen extends StatefulWidget {
  const EolRadarScreen({super.key});

  @override
  State<EolRadarScreen> createState() => _EolRadarScreenState();
}

class _EolRadarScreenState extends State<EolRadarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }

  void _startScanning() {
    final session = context.read<EolAuthService>().currentSession;
    final rssiThreshold = session?.rssiThresholdDbm ?? -40;
    context.read<EolBleService>().startProximityScan(rssiThresholdDbm: rssiThreshold);
  }

  String? _connectingDeviceId;

  Future<void> _handleConnect(DiscoveredBikeDevice device) async {
    setState(() {
      _connectingDeviceId = device.id;
    });

    final ble = context.read<EolBleService>();
    final connected = await ble.connectToController(device);

    if (!mounted) return;

    setState(() {
      _connectingDeviceId = null;
    });

    if (connected) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EolProvisionScreen()),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cable_rounded, color: EolTheme.powerpedalBlue),
              SizedBox(width: 8),
              Text('Controller Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Text(
            'Could not establish direct GATT connection with "${device.name}" (${device.id}).\n\n'
            'In the factory line, ensure the bike battery is switched on.\n\n'
            'For testing and inspection, would you like to open Vehicle Provisioning in Bench Mode?',
            style: const TextStyle(fontSize: 13, color: EolTheme.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EolTheme.powerpedalBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ble.setBenchDevice(device);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EolProvisionScreen()),
                );
              },
              child: const Text('Open Provisioning'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<EolBleService>();
    final session = context.watch<EolAuthService>().currentSession;
    final threshold = session?.rssiThresholdDbm ?? -40;
    final devices = ble.discoveredDevices;

    return Scaffold(
      backgroundColor: EolTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Proximity Discovery Radar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ble.isScanning ? EolTheme.statusSuccessBg : EolTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ble.isScanning ? EolTheme.statusSuccess : EolTheme.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ble.isScanning ? EolTheme.statusSuccess : EolTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ble.isScanning ? 'SCANNING' : 'IDLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ble.isScanning ? EolTheme.statusSuccess : EolTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          BrandHeaderPill(
            onQueueTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EolQueueScreen()),
              );
            },
            onSettingsTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const EolSetupScreen()),
              );
            },
          ),

          // Radar Instruction Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: EolTheme.surfaceSubtle,
            child: Row(
              children: [
                const Icon(Icons.tap_and_play_rounded, size: 20, color: EolTheme.powerpedalBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Touch phone within 5–10 cm of controller (RSSI ≥ $threshold dBm)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: EolTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ble.isScanning) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: EolTheme.powerpedalBlue),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () => ble.stopScan(),
                    child: const Text('STOP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ] else ...[
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('SCAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    onPressed: _startScanning,
                  ),
                ],
              ],
            ),
          ),

          // Filter Row: E-Bikes Only vs All Bluetooth
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: EolTheme.surfaceCard,
              border: Border(bottom: BorderSide(color: EolTheme.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ble.filterEbikesOnly ? 'E-Bike Controllers' : 'All Nearby Bluetooth',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: EolTheme.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChoiceChip(
                      label: const Text('E-Bikes Only', style: TextStyle(fontSize: 11)),
                      selected: ble.filterEbikesOnly,
                      selectedColor: EolTheme.powerpedalBlueLight,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: ble.filterEbikesOnly ? FontWeight.w800 : FontWeight.w500,
                        color: ble.filterEbikesOnly ? EolTheme.powerpedalBlueDark : EolTheme.textMuted,
                      ),
                      onSelected: (val) {
                        if (val) ble.setFilterEbikesOnly(true);
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text('All (${ble.allDiscoveredDevices.length})', style: const TextStyle(fontSize: 11)),
                      selected: !ble.filterEbikesOnly,
                      selectedColor: EolTheme.powerpedalBlueLight,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: !ble.filterEbikesOnly ? FontWeight.w800 : FontWeight.w500,
                        color: !ble.filterEbikesOnly ? EolTheme.powerpedalBlueDark : EolTheme.textMuted,
                      ),
                      onSelected: (val) {
                        if (val) ble.setFilterEbikesOnly(false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Banner if Bluetooth is off
          if (ble.scanErrorMessage != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: EolTheme.statusFaultBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EolTheme.statusFault.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_disabled_rounded, size: 18, color: EolTheme.statusFault),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ble.scanErrorMessage!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EolTheme.statusFault),
                    ),
                  ),
                  TextButton(
                    onPressed: _startScanning,
                    child: const Text('RETRY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: EolTheme.statusFault)),
                  ),
                ],
              ),
            ),
          ],

          // Discovered Controllers List
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: EolTheme.powerpedalBlueLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sensors_rounded,
                              size: 42,
                              color: EolTheme.powerpedalBlue,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            ble.filterEbikesOnly
                                ? 'No E-Bike Controllers in Proximity'
                                : 'No Bluetooth Devices in Proximity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: EolTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ble.filterEbikesOnly
                                ? 'Power on the bike controller and hold phone within 5–10 cm (RSSI ≥ $threshold dBm).'
                                : 'Bring phone closer to nearby device or lower RSSI threshold in Settings.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: EolTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (ble.filterEbikesOnly && ble.allDiscoveredDevices.isNotEmpty)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.devices_other_rounded, size: 16),
                              label: Text('View ${ble.allDiscoveredDevices.length} other nearby Bluetooth devices'),
                              onPressed: () => ble.setFilterEbikesOnly(false),
                            ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: const Text('Open Vehicle Provisioning (Bench Mode)'),
                            style: TextButton.styleFrom(
                              foregroundColor: EolTheme.powerpedalBlue,
                            ),
                            onPressed: () {
                              ble.setBenchDevice();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const EolProvisionScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final device = devices[index];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Row: Icon + Name/MAC + FreshBoot Badge
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: device.isIdentifiedEbike
                                          ? EolTheme.powerpedalBlueLight
                                          : EolTheme.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      device.isIdentifiedEbike
                                          ? Icons.pedal_bike_rounded
                                          : Icons.bluetooth_rounded,
                                      size: 24,
                                      color: device.isIdentifiedEbike
                                          ? EolTheme.powerpedalBlue
                                          : EolTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: EolTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'MAC: ${device.id}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: EolTheme.textMuted,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (device.isFreshBoot) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: EolTheme.statusSuccess,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'BOOT (<60s)',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Proximity Signal Bar (Full width, responsive)
                              RssiSignalMeter(rssi: device.rssi, threshold: threshold),
                              const SizedBox(height: 14),

                              // Connect Button
                              GlovedButton(
                                label: _connectingDeviceId == device.id ? 'Connecting...' : 'Connect & Flash Vehicle',
                                icon: _connectingDeviceId == device.id ? null : Icons.bolt_rounded,
                                isLoading: _connectingDeviceId == device.id,
                                onPressed: _connectingDeviceId != null ? null : () => _handleConnect(device),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
