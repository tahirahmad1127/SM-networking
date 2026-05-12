import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/view/notifications/layout/body.dart';

import '../../../infrastructure/model/notification.dart';

class NotificationView extends StatelessWidget {
  final List<NotificationModel> list;

  NotificationView({Key? key, required this.list}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context),
      body: NotificationsBody(
        list: list,
      ),
    );
  }
}
