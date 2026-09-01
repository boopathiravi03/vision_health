import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/health_analysis.dart';
import 'local_storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<bool> savePatientVisit(
    HealthAnalysis analysis,
  ) async {
    final data = analysis.toMap();

    try {
      await _firestore.collection('visits').add(
        {
          ...data,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      return true;
    } catch (_) {
      await LocalStorageService.saveVisit(data);

      return false;
    }
  }
}
