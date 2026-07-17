/// Backed by the single Firestore document at appConfig/maintenance —
/// toggle `isUnderMaintenance` there to show/hide the maintenance screen
/// app-wide without a release. `title`/`message` are optional overrides;
/// sensible defaults are used if they're left blank.
class MaintenanceModel {
  final bool isUnderMaintenance;
  final String? title;
  final String? message;

  const MaintenanceModel({
    required this.isUnderMaintenance,
    this.title,
    this.message,
  });

  /// Fails "open" (not under maintenance) if the document doesn't exist yet
  /// or a field is missing/malformed — a misconfigured flag should never be
  /// able to lock every user out of the app.
  factory MaintenanceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MaintenanceModel(isUnderMaintenance: false);
    return MaintenanceModel(
      isUnderMaintenance: json['isUnderMaintenance'] == true,
      title: (json['title'] as String?)?.trim(),
      message: (json['message'] as String?)?.trim(),
    );
  }
}
