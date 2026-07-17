import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sm_networking/infrastructure/model/maintenance.dart';

class MaintenanceServices {
  /// Live-streams the single appConfig/maintenance document, so toggling
  /// `isUnderMaintenance` in the Firebase console takes effect immediately
  /// for every open app session — no restart required.
  Stream<MaintenanceModel> streamMaintenanceStatus() {
    return FirebaseFirestore.instance
        .collection('appConfig')
        .doc('maintenance')
        .snapshots()
        .map((doc) => MaintenanceModel.fromJson(doc.data()))
        // A transient read error shouldn't lock users out of the app —
        // treat it the same as "not under maintenance".
        .transform(
          StreamTransformer<MaintenanceModel, MaintenanceModel>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.add(const MaintenanceModel(isUnderMaintenance: false)),
          ),
        );
  }
}
