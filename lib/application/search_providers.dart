import 'package:flutter/material.dart';
import 'package:sm_networking/infrastructure/model/product.dart';

import '../infrastructure/model/retailer.dart';

class SearchProviders extends ChangeNotifier {
  List<ProductModel> _productList = [];
  List<RetailerModel> _retailerList = [];

  //
  void saveProductList(List<ProductModel> list) {
    _productList = list;
  }

  void saveRetailerList(List<RetailerModel> list) {
    _retailerList = list;
  }

  //
  List<ProductModel> get getProductList => _productList;

  List<RetailerModel> get getRetailerList => _retailerList;
}
