import 'package:firebase_database/firebase_database.dart';

import 'connectivity_service.dart';
import 'offline_storage_service.dart';

class SyncService {
  final OfflineStorageService
      _offlineStorage =
      OfflineStorageService();

  final ConnectivityService
      _connectivity =
      ConnectivityService();

  final DatabaseReference
      _patientsRef =
      FirebaseDatabase.instance
          .ref('patients');

  Future<bool> syncPendingPatients() async {
    final online =
        await _connectivity.hasInternet();

    if (!online) {
      return false;
    }

    final pending =
        await _offlineStorage
            .getPendingPatients();

    if (pending.isEmpty) {
      return true;
    }

    try {
      for (final patient in pending) {
        final id =
            patient['id'] ??
                DateTime.now()
                    .millisecondsSinceEpoch
                    .toString();

        await _patientsRef
            .child(id.toString())
            .set(patient);
      }

      await _offlineStorage
          .removePendingPatients();

      return true;
    } catch (e) {
      return false;
    }
  }
}
