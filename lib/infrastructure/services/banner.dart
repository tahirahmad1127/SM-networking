import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sm_networking/infrastructure/model/banner.dart';

class BannerServices {
  ///Stream Banners
  Stream<List<BannerModel>> streamBanners(String cityID) {
    log(cityID);
    return FirebaseFirestore.instance
        .collection('bannerCollection')
        .where('cityID', isEqualTo: cityID)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)

        .snapshots()
        .map((event) =>
            event.docs.map((e) => BannerModel.fromJson(e.data())).toList());
  }
}
