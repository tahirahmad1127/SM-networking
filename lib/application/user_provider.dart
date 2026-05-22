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

  void updateDistributors(List<Distributor> newList) {
    if (_saleUserModel == null) return;
    _saleUserModel = UserModel(
      token: _saleUserModel!.token,
      user: _saleUserModel!.user,
      role: _saleUserModel!.role,
      distributors: newList,
    );
    notifyListeners();
  }

  /// Updates [shopLocation] for the distributor matching [idOrSalesId] (in-memory).
  void patchDistributorShopLocation(
      String idOrSalesId, double lat, double lng) {
    final model = _saleUserModel;
    final distributors = model?.distributors;
    if (model == null || distributors == null || idOrSalesId.isEmpty) {
      return;
    }
    final next = List<Distributor>.from(distributors);
    final i = next.indexWhere(
            (d) => d.id == idOrSalesId || d.salesId == idOrSalesId);
    if (i < 0) return;
    next[i] = next[i].copyWith(
        shopLocation: DistributorLocation(lat: lat, lng: lng));
    _saleUserModel = UserModel(
      token: model.token,
      user: model.user,
      role: model.role,
      distributors: next,
    );
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