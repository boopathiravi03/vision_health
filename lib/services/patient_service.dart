import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/patient.dart';
import 'connectivity_service.dart';
import 'offline_storage_service.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ConnectivityService _connectivityService = ConnectivityService();

  final OfflineStorageService _offlineStorageService = OfflineStorageService();

  Future<String> addPatient(Patient patient) async {
    final online = await _connectivityService.hasInternet();

    if (!online) {
      await _offlineStorageService.savePendingPatient(patient);

      return patient.id;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('An ASHA worker must be signed in.');

    final docRef = await _firestore.collection('patients').add({
      ...patient.toMap(),
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Stream<List<Patient>> getPatients() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _firestore
        .collection('patients')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Patient.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    final doc = await _firestore.collection('patients').doc(patientId).get();

    if (!doc.exists) {
      return null;
    }

    return {'id': doc.id, ...doc.data()!};
  }

  Future<Map<String, dynamic>?> getPatientForAuthUid(String authUid) async {
    final snapshot = await _firestore
        .collection('patients')
        .where('patientAuthUid', isEqualTo: authUid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final document = snapshot.docs.first;
    return {'id': document.id, ...document.data()};
  }

  Future<void> updateStatus(String patientId, String status) async {
    await _firestore.collection('patients').doc(patientId).update({
      'status': status,
    });
  }

  Future<void> deletePatient(String patientId) async {
    await _firestore.collection('patients').doc(patientId).delete();
  }
}
