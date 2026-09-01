import 'dart:async';

import 'connectivity_service.dart';
import 'sync_service.dart';

class AppSyncManager {
  final ConnectivityService
      _connectivityService =
      ConnectivityService();

  final SyncService _syncService =
      SyncService();

  StreamSubscription<bool>?
      _subscription;

  void start() {
    _subscription =
        _connectivityService
            .connectionStream
            .listen(
      (online) async {
        if (online) {
          await _syncService
              .syncPendingPatients();
        }
      },
    );
  }

  Future<void> syncNow() async {
    await _syncService
        .syncPendingPatients();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
