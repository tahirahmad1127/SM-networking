import 'package:flutter/foundation.dart';
import 'package:sm_networking/infrastructure/model/wholesaler_retailer_model.dart';
import 'package:sm_networking/infrastructure/services/wholesaler_retailer_service.dart';

/// Holds in-memory lists of wholesalers and retailers for the current session.
///
/// Usage pattern mirrors how [UserProvider.updateDistributors] is used in
/// [AddDistributorView]: after a successful POST the view appends the new
/// entry to the provider list so the listing screen refreshes instantly
/// without a second network call.
class WholesalerRetailerProvider extends ChangeNotifier {
  final WholesalerRetailerService _service = WholesalerRetailerService();

  // ── State ──────────────────────────────────────────────────────────────────

  List<WholesalerRetailerModel> _wholesalers = [];
  List<WholesalerRetailerModel> _retailers = [];

  bool _loadingWholesalers = false;
  bool _loadingRetailers = false;

  String? _wholesalerError;
  String? _retailerError;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<WholesalerRetailerModel> get wholesalers =>
      List.unmodifiable(_wholesalers);
  List<WholesalerRetailerModel> get retailers =>
      List.unmodifiable(_retailers);

  bool get loadingWholesalers => _loadingWholesalers;
  bool get loadingRetailers => _loadingRetailers;

  String? get wholesalerError => _wholesalerError;
  String? get retailerError => _retailerError;

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadWholesalers({
    required String token,
    String? tsmId,
    String? zoneId,
    String? townId,
  }) async {
    _loadingWholesalers = true;
    _wholesalerError = null;
    notifyListeners();

    try {
      _wholesalers = await _service.fetchEntries(
        endpoint: 'wholesaler/',
        token: token,
        tsmId: tsmId,
        zoneId: zoneId,
        townId: townId,
      );
    } catch (e) {
      _wholesalerError = e.toString();
    } finally {
      _loadingWholesalers = false;
      notifyListeners();
    }
  }

  Future<void> loadRetailers({
    required String token,
    String? tsmId,
    String? zoneId,
    String? townId,
  }) async {
    _loadingRetailers = true;
    _retailerError = null;
    notifyListeners();

    try {
      _retailers = await _service.fetchEntries(
        endpoint: 'retailer/',
        token: token,
        tsmId: tsmId,
        zoneId: zoneId,
        townId: townId,
      );
    } catch (e) {
      _retailerError = e.toString();
    } finally {
      _loadingRetailers = false;
      notifyListeners();
    }
  }

  // ── Optimistic local append (used after successful POST) ──────────────────
  // Same technique as UserProvider.updateDistributors — avoids a round-trip.

  void appendWholesaler(WholesalerRetailerModel entry) {
    _wholesalers = [entry, ..._wholesalers];
    notifyListeners();
  }

  void appendRetailer(WholesalerRetailerModel entry) {
    _retailers = [entry, ..._retailers];
    notifyListeners();
  }
  // ── Clear ──────────────────────────────────────────────────────────────────

  void clearAll() {
    _wholesalers = [];
    _retailers = [];
    notifyListeners();
  }
}