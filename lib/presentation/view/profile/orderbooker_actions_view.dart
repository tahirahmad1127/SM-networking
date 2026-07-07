import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/view/profile/market_bookings_view.dart';
import 'package:sm_networking/presentation/view/profile/market_recoveries_view.dart';

/// Shown after tapping an orderbooker from [OrderBookersListView].
class OrderBookerActionsView extends StatelessWidget {
  final OrderBooker orderBooker;

  const OrderBookerActionsView({super.key, required this.orderBooker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        text: orderBooker.name ?? 'Orderbooker',
        showText: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              CustomText(
                text: orderBooker.name ?? '',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              if ((orderBooker.salesId ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                CustomText(
                  text: 'ID: ${orderBooker.salesId}',
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ],
              const SizedBox(height: 36),

              // ── Market Bookings ─────────────────────────────────────────
              _ActionButton(
                label: 'Market Bookings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MarketBookingsView(orderBooker: orderBooker),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Market Recoveries ────────────────────────────────────────
              _ActionButton(
                label: 'Market Recoveries',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MarketRecoveriesView(orderBooker: orderBooker),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: FrontendConfigs.kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: FrontendConfigs.kAppBorder,
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}