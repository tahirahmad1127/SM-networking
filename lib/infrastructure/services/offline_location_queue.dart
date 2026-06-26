// lib/infrastructure/services/offline_location_queue_service.dart
import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

const String _kOfflineLocationQueueKey = 'offline_location_queue';

/// A single GPS ping that couldn't be written to Firestore at the time it
/// was captured (no internet, or Firestore unreachable). Queued locally so
/// it can be replayed in order once connectivity returns, reconstructing
/// the rider's actual path during the offline period.
class OfflineLocationPing {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  OfflineLocationPing({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };

  factory OfflineLocationPing.fromJson(Map<String, dynamic> j) {
    return OfflineLocationPing(
      userId: j['userId'] ?? '',
      latitude: (j['latitude'] ?? 0).toDouble(),
      longitude: (j['longitude'] ?? 0).toDouble(),
      timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Runs entirely inside the background-service isolate (same one that
/// already does the periodic GPS capture in background_location.dart), so
/// it uses its own SharedPreferences key — separate from anything the main
/// UI isolate reads/writes — to avoid any cross-isolate key confusion.
class OfflineLocationQueueService {
  static Future<List<OfflineLocationPing>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kOfflineLocationQueueKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => OfflineLocationPing.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      log('OfflineLocationQueueService.getAll error: $e');
      return [];
    }
  }

  static Future<void> _saveAll(List<OfflineLocationPing> pings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kOfflineLocationQueueKey,
      jsonEncode(pings.map((p) => p.toJson()).toList()),
    );
  }

  static Future<void> add(OfflineLocationPing ping) async {
    final all = await getAll();
    all.add(ping);
    await _saveAll(all);
  }

  /// Removes the oldest [count] pings (call after successfully replaying
  /// them to Firestore, in the same chronological order they were read).
  static Future<void> removeOldest(int count) async {
    final all = await getAll();
    if (count >= all.length) {
      await clearAll();
      return;
    }
    await _saveAll(all.sublist(count));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOfflineLocationQueueKey);
  }

  static Future<int> count() async => (await getAll()).length;
}