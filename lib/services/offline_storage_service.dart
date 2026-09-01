import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient.dart';

class OfflineStorageService {
  static const String _pendingPatientsKey =
      'pending_patients';

  Future<List<Map<String, dynamic>>>
      getPendingPatients() async {
    final prefs =
        await SharedPreferences.getInstance();

    final data =
        prefs.getStringList(_pendingPatientsKey) ??
            [];

    return data
        .map(
          (item) => jsonDecode(item)
              as Map<String, dynamic>,
        )
        .toList();
  }

  Future<void> savePendingPatient(
    Patient patient,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final pending =
        await getPendingPatients();

    pending.add(
      patient.toMap(),
    );

    await prefs.setStringList(
      _pendingPatientsKey,
      pending
          .map(
            (item) => jsonEncode(item),
          )
          .toList(),
    );
  }

  Future<void> removePendingPatients() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _pendingPatientsKey,
    );
  }

  Future<int> getPendingCount() async {
    final pending =
        await getPendingPatients();

    return pending.length;
  }
}
