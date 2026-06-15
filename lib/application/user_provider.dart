import 'package:flutter/cupertino.dart';

import '../infrastructure/model/agent.dart';
import '../infrastructure/model/user.dart';

class UserProvider extends ChangeNotifier {
  AgentModel? _userModel;
  UserModel? _saleUserModel;

  void saveUserDetails(AgentModel? userModel) {
    _userModel = userModel;
    notifyListeners();
  }

  void saveSalesUserDetails(UserModel? userModel) {
    _saleUserModel = userModel;
    notifyListeners();
  }

  AgentModel? getUserDetails() => _userModel;
  UserModel? getSalesUserDetails() => _saleUserModel;

  // ── Helpers to rebuild UserModel immutably ──────────────────────────────

  UserModel _rebuild({
    List<Distributor>? distributors,
    List<Wholesaler>? wholesalers,
    List<Wholesaler>? retailers,
  }) {
    final m = _saleUserModel!;
    return UserModel(
      token: m.token,
      user: m.user,
      role: m.role,
      distributors: distributors ?? m.distributors,
      wholesalers: wholesalers ?? m.wholesalers,
      retailers: retailers ?? m.retailers,
      totalWholesalers: m.totalWholesalers,
      totalRetailers: m.totalRetailers,
    );
  }

  void updateDistributors(List<Distributor> newList) {
    if (_saleUserModel == null) return;
    _saleUserModel = _rebuild(distributors: newList);
    notifyListeners();
  }

  void updateWholesalers(List<Wholesaler> newList) {
    if (_saleUserModel == null) return;
    _saleUserModel = _rebuild(wholesalers: newList);
    notifyListeners();
  }

  void updateRetailers(List<Wholesaler> newList) {
    if (_saleUserModel == null) return;
    _saleUserModel = _rebuild(retailers: newList);
    notifyListeners();
  }

  /// Updates [shopLocation] for the distributor matching [idOrSalesId] (in-memory).
  void patchDistributorShopLocation(
      String idOrSalesId, double lat, double lng) {
    final model = _saleUserModel;
    final distributors = model?.distributors;
    if (model == null || distributors == null || idOrSalesId.isEmpty) return;

    final next = List<Distributor>.from(distributors);
    final i =
    next.indexWhere((d) => d.id == idOrSalesId || d.salesId == idOrSalesId);
    if (i < 0) return;
    next[i] =
        next[i].copyWith(shopLocation: DistributorLocation(lat: lat, lng: lng));
    _saleUserModel = _rebuild(distributors: next);
    notifyListeners();
  }

  /// Updates [shopLocation] for the wholesaler matching [id] (in-memory).
  void patchWholesalerShopLocation(String id, double lat, double lng) {
    final model = _saleUserModel;
    final list = model?.wholesalers;
    if (model == null || list == null || id.isEmpty) return;

    final next = List<Wholesaler>.from(list);
    final i = next.indexWhere((w) => w.id == id);
    if (i < 0) return;
    next[i] =
        next[i].copyWith(shopLocation: DistributorLocation(lat: lat, lng: lng));
    _saleUserModel = _rebuild(wholesalers: next);
    notifyListeners();
  }

  /// Updates [shopLocation] for the retailer matching [id] (in-memory).
  void patchRetailerShopLocation(String id, double lat, double lng) {
    final model = _saleUserModel;
    final list = model?.retailers;
    if (model == null || list == null || id.isEmpty) return;

    final next = List<Wholesaler>.from(list);
    final i = next.indexWhere((r) => r.id == id);
    if (i < 0) return;
    next[i] =
        next[i].copyWith(shopLocation: DistributorLocation(lat: lat, lng: lng));
    _saleUserModel = _rebuild(retailers: next);
    notifyListeners();
  }

  void clearData() {
    _userModel = null;
    notifyListeners();
  }

  /// Clears the sales user session (call this on logout so that
  /// the next login triggers a fresh [didChangeDependencies] sync
  /// in any listening widget).
  void clearSalesData() {
    _saleUserModel = null;
    notifyListeners();
  }
}