import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? latLng;

  void setLatLng(LatLng newLatLng) {
    latLng = newLatLng;
    notifyListeners();
  }

  LatLng? getLatLng() {
    return latLng;
  }
}
