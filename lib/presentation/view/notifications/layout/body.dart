import 'package:flutter/material.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/order/no_data_found_view.dart';
import 'package:provider/provider.dart';

import '../../../../configurations/frontend_configs.dart';
import '../../../../infrastructure/model/notification.dart';
import '../../../../infrastructure/services/notification.dart';
import '../../../elements/custom_text.dart';
import '../../../elements/loaders.dart';
import 'widgets/notification_card.dart';

class NotificationsBody extends StatefulWidget {
  final List<NotificationModel> list;

  const NotificationsBody({Key? key, required this.list}) : super(key: key);

  @override
  State<NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<NotificationsBody> {
  @override
  void initState() {
    NotificationServices().markNotificationRead(widget.list);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: TranslationHelper.getTranslatedText('notification'),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ],
            ),
          ),
          FrontendConfigs.appDivider,
          const SizedBox(
            height: 8,
          ),
          Expanded(
            child: StreamProvider.value(
              value: NotificationServices()
                  .streamNotifications(user.getUserDetails()!.docId.toString()),
              initialData: [NotificationModel()],
              builder: (context, child) {
                List<NotificationModel> _list =
                    context.watch<List<NotificationModel>>();
                return _list.isNotEmpty
                    ? _list[0].docId == null
                        ? NotificationLoader()
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _list.length,
                            shrinkWrap: true,
                            itemBuilder: (context, i) {
                              return NotificationCard(
                                model: _list[i],
                              );
                            })
                    : NoDataFoundView();
              },
            ),
          ),
          const SizedBox(
            height: 18,
          ),
        ],
      ),
    );
  }
}
