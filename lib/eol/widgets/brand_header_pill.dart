import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/eol_auth_service.dart';
import '../services/eol_local_storage_service.dart';
import '../theme/eol_theme.dart';

class BrandHeaderPill extends StatelessWidget {
  final VoidCallback? onQueueTap;
  final VoidCallback? onSettingsTap;

  const BrandHeaderPill({
    super.key,
    this.onQueueTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<EolAuthService>().currentSession;
    if (session == null) return const SizedBox.shrink();

    final storage = context.watch<EolLocalStorageService>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: EolTheme.surfaceCard,
        border: Border(
          bottom: BorderSide(color: EolTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EolTheme.powerpedalBlueLight,
              borderRadius: BorderRadius.circular(EolTheme.borderRadiusPill),
              border: Border.all(color: EolTheme.powerpedalBlue.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: EolTheme.powerpedalBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  session.brand.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: EolTheme.powerpedalBlueDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Station & Assembler Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.stationId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: EolTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  session.assembler.fullName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: EolTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Local Queue Pending Pill
          FutureBuilder<Map<String, int>>(
            future: storage.getQueueStats(),
            builder: (context, snapshot) {
              final pending = snapshot.data?['pending'] ?? 0;
              return InkWell(
                onTap: onQueueTap,
                borderRadius: BorderRadius.circular(EolTheme.borderRadiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pending > 0
                        ? EolTheme.statusWarningBg
                        : EolTheme.statusSuccessBg,
                    borderRadius: BorderRadius.circular(EolTheme.borderRadiusPill),
                    border: Border.all(
                      color: pending > 0
                          ? EolTheme.statusWarning.withAlpha(80)
                          : EolTheme.statusSuccess.withAlpha(80),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pending > 0
                            ? Icons.cloud_queue_rounded
                            : Icons.cloud_done_rounded,
                        size: 14,
                        color: pending > 0
                            ? EolTheme.statusWarning
                            : EolTheme.statusSuccess,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pending > 0 ? '$pending Pending' : 'Synced',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pending > 0
                              ? EolTheme.statusWarning
                              : EolTheme.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Station Settings Gear
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: EolTheme.textSecondary,
            tooltip: 'Station Setup',
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}
