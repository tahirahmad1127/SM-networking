import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/view/notifications/layout/body.dart';

import '../../../infrastructure/model/notification.dart';

class NotificationView extends StatelessWidget {
  final List<NotificationModel> list;

  const NotificationView({super.key, required this.list});

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
