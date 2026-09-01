import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';
import 'connectivity_service.dart';
import 'offline_storage_service.dart';

class PatientService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ConnectivityService
      _connectivityService =
      ConnectivityService();

  final OfflineStorageService
      _offlineStorageService =
      OfflineStorageService();

  Future<String> addPatient(
    Patient patient,
  ) async {
    final online =
        await _connectivityService
            .hasInternet();

    if (!online) {
      await _offlineStorageService
          .savePendingPatient(patient);

      return patient.id;
    }

    final docRef =
        await _firestore
            .collection('patients')
            .add(patient.toMap());

    return docRef.id;
  }

  Stream<List<Patient>> getPatients() {
    return _firestore
        .collection('patients')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Patient.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> getPatient(
    String patientId,
  ) async {
    final doc = await _firestore
        .collection('patients')
        .doc(patientId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  Future<void> updateStatus(
    String patientId,
    String status,
  ) async {
    await _firestore
        .collection('patients')
        .doc(patientId)
        .update({
      'status': status,
    });
  }

  Future<void> deletePatient(
    String patientId,
  ) async {
    await _firestore
        .collection('patients')
        .doc(patientId)
        .delete();
  }
}
