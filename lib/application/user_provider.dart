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

  void clearData() {
    _userModel = null;
    notifyListeners();
  }
}
