import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sm_networking/infrastructure/model/notification.dart';

class NotificationServices {
  ///Stream Notifications
  Stream<List<NotificationModel>> streamNotifications(String userID) {
    return FirebaseFirestore.instance
        .collection('notificationCollection')
        .where('userID', isEqualTo: userID)
        .snapshots()
        .map((event) => event.docs
            .map((e) => NotificationModel.fromJson(e.data()))
            .toList());
  }

  ///Stream UnRead Notifications
  Stream<List<NotificationModel>> streamUnReadNotifications(String userID) {
    return FirebaseFirestore.instance
        .collection('notificationCollection')
        .where('userID', isEqualTo: userID)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((event) => event.docs
            .map((e) => NotificationModel.fromJson(e.data()))
            .toList());
  }

  ///Mark Notification as Read
  Future<void> markNotificationRead(List<NotificationModel> list) async {
    list.map((e) {
      FirebaseFirestore.instance
          .collection('notificationCollection')
          .doc(e.docId)
          .update({'isRead': true});
    }).toList();
  }
}
