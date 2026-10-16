import 'package:flutter/material.dart';
import '../theme/eol_theme.dart';

class RssiSignalMeter extends StatelessWidget {
  final int rssi;
  final int threshold;

  const RssiSignalMeter({
    super.key,
    required this.rssi,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final meetsThreshold = rssi >= threshold;
    final color = meetsThreshold
        ? EolTheme.statusSuccess
        : (rssi >= threshold - 15 ? EolTheme.statusWarning : EolTheme.statusFault);

    // Normalize RSSI (-90 to -30) to 0.0 -> 1.0
    final percent = ((rssi + 90) / 60).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(
            meetsThreshold ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '$rssi dBm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meetsThreshold ? 'PROXIMITY LOCKED' : 'APPROACH VEHICLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: EolTheme.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
