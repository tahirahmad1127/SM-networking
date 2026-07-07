import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';

import 'orderbooker_actions_view.dart';

/// Shown only for the `warehouseManager` role. The orderBookers list is
/// already part of the login response (`UserModel.orderBookers`), so this
/// screen just reads it straight from [UserProvider] — no extra API call.
class OrderBookersListView extends StatelessWidget {
  const OrderBookersListView({super.key});

  @override
  Widget build(BuildContext context) {
    final orderBookers =
        context.watch<UserProvider>().getSalesUserDetails()?.orderBookers ??
            const [];

    return Scaffold(
      appBar: customAppBar(context, text: 'Orderbookers', showText: true),
      body: SafeArea(
        child: orderBookers.isEmpty
            ? const Center(child: Text('No orderbookers found'))
            : ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: orderBookers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final ob = orderBookers[i];
            return InkWell(
              borderRadius: FrontendConfigs.kAppBorder,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderBookerActionsView(orderBooker: ob),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: FrontendConfigs.kAppBorder,
                  color: FrontendConfigs.kTextFieldColor,
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: (ob.image != null && ob.image!.isNotEmpty)
                          ? Image.network(
                        ob.image!,
                        height: 46,
                        width: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _fallbackAvatar(),
                      )
                          : _fallbackAvatar(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: ob.name ?? '',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 3),
                          if ((ob.salesId ?? '').isNotEmpty)
                            Text(
                              'ID: ${ob.salesId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          if ((ob.phone ?? '').isNotEmpty)
                            Text(
                              ob.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: FrontendConfigs.kAuthTextColor,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fallbackAvatar() => Container(
    height: 46,
    width: 46,
    color: Colors.grey.shade300,
    child: const Icon(Icons.person, color: Colors.white),
  );
}