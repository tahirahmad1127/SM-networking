import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sm_networking/infrastructure/model/city.dart';

class CityServices {
  ///Stream Cities
  Future<List<CityModel>> getCities() {
    return FirebaseFirestore.instance.collection('cityCollection').get().then(
        (event) =>
            event.docs.map((e) => CityModel.fromJson(e.data())).toList());
  }
}
