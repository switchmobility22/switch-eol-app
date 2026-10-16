import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/local_eol_record.dart';
import '../services/eol_local_storage_service.dart';
import '../services/eol_sync_service.dart';
import '../theme/eol_theme.dart';
import '../widgets/brand_header_pill.dart';

class EolQueueScreen extends StatefulWidget {
  const EolQueueScreen({super.key});

  @override
  State<EolQueueScreen> createState() => _EolQueueScreenState();
}

class _EolQueueScreenState extends State<EolQueueScreen> {
  late Future<List<LocalEolRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _recordsFuture = context.read<EolLocalStorageService>().getAllRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<EolSyncService>();
    final storage = context.watch<EolLocalStorageService>();

    return Scaffold(
      backgroundColor: EolTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Offline Queue & Cloud Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          const BrandHeaderPill(),

          // Queue Statistics Strip
          FutureBuilder<Map<String, int>>(
            future: storage.getQueueStats(),
            builder: (context, snapshot) {
              final total = snapshot.data?['total'] ?? 0;
              final pending = snapshot.data?['pending'] ?? 0;
              final synced = snapshot.data?['synced'] ?? 0;

              return Container(
                padding: const EdgeInsets.all(16),
                color: EolTheme.surfaceCard,
                child: Row(
                  children: [
                    _buildStatCard('TOTAL STATION', '$total', EolTheme.powerpedalBlue),
                    const SizedBox(width: 10),
                    _buildStatCard('LOCAL PENDING', '$pending', EolTheme.statusWarning),
                    const SizedBox(width: 10),
                    _buildStatCard('CLOUD RECONCILED', '$synced', EolTheme.statusSuccess),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),

          // Sync Engine Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: EolTheme.surfaceSubtle,
            child: Row(
              children: [
                Icon(
                  syncService.isSyncing
                      ? Icons.sync_rounded
                      : Icons.cloud_done_rounded,
                  size: 18,
                  color: syncService.isSyncing
                      ? EolTheme.powerpedalBlue
                      : EolTheme.statusSuccess,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    syncService.lastSyncMessage ?? 'Silent auto-sync engine active.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EolTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: syncService.isSyncing
                      ? null
                      : () async {
                          await syncService.syncPendingQueue();
                          _refresh();
                        },
                  child: syncService.isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'SYNC NOW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: EolTheme.powerpedalBlue,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // List of Local SQLite Records
          Expanded(
            child: FutureBuilder<List<LocalEolRecord>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(
                    child: Text(
                      'No bikes provisioned at this station yet.',
                      style: TextStyle(color: EolTheme.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = records[index];
                    final isSynced = r.syncStatus == 'synced';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 40,
                              decoration: BoxDecoration(
                                color: EolTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Image.asset(r.imageAsset, fit: BoxFit.contain),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r.name} (${r.colour})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: EolTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'MAC: ${r.mac} · ${r.wheelSizeInches}" (${r.wheelCircumferenceMm}mm)',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: EolTheme.textMuted,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSynced
                                    ? EolTheme.statusSuccessBg
                                    : EolTheme.statusWarningBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSynced
                                        ? Icons.cloud_done_rounded
                                        : Icons.cloud_upload_outlined,
                                    size: 13,
                                    color: isSynced
                                        ? EolTheme.statusSuccess
                                        : EolTheme.statusWarning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSynced ? 'SYNCED' : 'LOCAL PENDING',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isSynced
                                          ? EolTheme.statusSuccess
                                          : EolTheme.statusWarning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
