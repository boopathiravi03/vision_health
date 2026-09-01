import 'package:firebase_database/firebase_database.dart';

class AlertService {
  final DatabaseReference _alertsRef =
      FirebaseDatabase.instance.ref('alerts');

  Future<void> createAlert({
    required String patientId,
    required String patientName,
    required String riskLevel,
    required String symptoms,
    required String recommendation,
    required String village,
  }) async {
    final alertRef = _alertsRef.push();

    await alertRef.set({
      'id': alertRef.key,
      'patientId': patientId,
      'patientName': patientName,
      'riskLevel': riskLevel,
      'symptoms': symptoms,
      'recommendation': recommendation,
      'village': village,
      'status': 'unread',
      'createdAt': ServerValue.timestamp,
    });
  }
}
