import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_analysis.dart';
import 'local_storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> savePatientVisit(HealthAnalysis analysis) async {
    final data = analysis.toMap();
    final ashaUid = _auth.currentUser?.uid;
    if (ashaUid == null) return false;

    try {
      await _firestore.collection('visits').add({
        ...data,
        'createdBy': ashaUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (_) {
      await LocalStorageService.saveVisit(data);

      return false;
    }
  }
}
