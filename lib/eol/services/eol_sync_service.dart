import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'eol_local_storage_service.dart';

class EolSyncService with ChangeNotifier {
  final EolLocalStorageService localStorage;
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;
  String? _lastSyncMessage;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  String? get lastSyncMessage => _lastSyncMessage;
  DateTime? get lastSyncTime => _lastSyncTime;

  EolSyncService({required this.localStorage}) {
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile || r == ConnectivityResult.ethernet,
      );
      if (isConnected) {
        debugPrint('🌐 [Auto-Sync] Network connection detected, triggering background sync...');
        syncPendingQueue();
      }
    });
  }

  Future<void> syncPendingQueue() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _lastSyncMessage = 'Syncing pending records...';
    notifyListeners();

    try {
      final pendingRecords = await localStorage.getPendingRecords();
      if (pendingRecords.isEmpty) {
        _isSyncing = false;
        _lastSyncMessage = 'Queue is clean. 0 pending records.';
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return;
      }

      debugPrint('🚀 [Auto-Sync] Found ${pendingRecords.length} pending records to reconcile with Firestore...');
      final firestore = FirebaseFirestore.instance;

      int successCount = 0;
      for (final record in pendingRecords) {
        try {
          final docRef = firestore.collection('ebikes').doc(record.mac.toUpperCase());
          await docRef.set(record.toFirestoreMap(), SetOptions(merge: true));

          if (record.id != null) {
            await localStorage.markRecordSynced(record.id!);
          }
          successCount++;
        } catch (docErr) {
          debugPrint('❌ [Auto-Sync] Failed uploading record ${record.mac}: $docErr');
        }
      }

      _lastSyncTime = DateTime.now();
      _lastSyncMessage = 'Reconciled $successCount / ${pendingRecords.length} records to cloud.';
      debugPrint('✅ [Auto-Sync] $_lastSyncMessage');
    } catch (e) {
      _lastSyncMessage = 'Sync error: $e';
      debugPrint('❌ [Auto-Sync] Error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
