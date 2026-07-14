import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sm_networking/infrastructure/model/privacy_policy.dart';

class PrivacyPolicyServices {
  ///Stream Privacy Policy
  Stream<List<PrivacyPolicyModel>> streamPrivacyPolicy() {
    return FirebaseFirestore.instance
        .collection('privacyPolicyCollection')
        .snapshots()
        .map((event) => event.docs
            .map((e) => PrivacyPolicyModel.fromJson(e.data()))
            .toList());
  }
}
