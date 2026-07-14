import 'package:flutter/cupertino.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RetailerProvider extends ChangeNotifier {
  RetailerModel? _model;

  void saveRetailer(RetailerModel model) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString("RETAILER_DATA", retailersModelToJson(model));
    _model = model;
    notifyListeners();
  }

  RetailerModel? getRetailer() => _model;
}
