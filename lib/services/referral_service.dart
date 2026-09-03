import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/referral.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createReferral({
    required String patientName,
    required int age,
    required String gender,
    required String riskLevel,
    required List<String> symptoms,
    required String reason,
    required String recommendedAction,
  }) async {
    final doc = _firestore.collection('referrals').doc();
    final ashaUid = _auth.currentUser?.uid;
    if (ashaUid == null) {
      throw StateError('An ASHA worker must be signed in.');
    }

    final referral = Referral(
      id: doc.id,
      patientName: patientName,
      age: age,
      gender: gender,
      riskLevel: riskLevel,
      symptoms: symptoms,
      reason: reason,
      recommendedAction: recommendedAction,
      createdAt: DateTime.now(),
      status: 'Pending',
    );

    await doc.set({...referral.toMap(), 'createdBy': ashaUid});

    return doc.id;
  }

  Future<Map<String, dynamic>?> getReferral(String referralId) async {
    final document = await _firestore
        .collection('referrals')
        .doc(referralId)
        .get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }
}
