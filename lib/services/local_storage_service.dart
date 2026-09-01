import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String visitBox = 'offline_visits';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    await Hive.openBox(visitBox);
  }

  static Box get _box => Hive.box(visitBox);

  static Future<void> saveVisit(
    Map<String, dynamic> visit,
  ) async {
    await _box.add({
      ...visit,
      'synced': false,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> getPendingVisits() {
    return _box.values
        .where(
          (item) =>
              item is Map &&
              item['synced'] == false,
        )
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static int get pendingCount {
    return getPendingVisits().length;
  }

  static Future<void> markAllAsSynced() async {
    final keys = _box.keys.toList();

    for (final key in keys) {
      final value = _box.get(key);

      if (value is Map &&
          value['synced'] == false) {
        await _box.put(
          key,
          {
            ...Map<String, dynamic>.from(value),
            'synced': true,
          },
        );
      }
    }
  }
}
