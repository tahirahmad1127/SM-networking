import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/add_recovery.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/order_booker_activity.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';

/// Market recoveries recorded by [orderBooker], scoped to the logged-in
/// warehouseManager (TSM). Reached from [OrderBookerActionsView] →
/// "Market Recoveries".
class MarketRecoveriesView extends StatefulWidget {
  final OrderBooker orderBooker;

  const MarketRecoveriesView({super.key, required this.orderBooker});

  @override
  State<MarketRecoveriesView> createState() => _MarketRecoveriesViewState();
}

class _MarketRecoveriesViewState extends State<MarketRecoveriesView> {
  late Future<Either<GlobalErrorModel, RecoveryListingModel>> _future;
  bool _futureInited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureInited) return;
    _futureInited = true;
    _future = _load();
  }

  Future<Either<GlobalErrorModel, RecoveryListingModel>> _load() {
    final details = context.read<UserProvider>().getSalesUserDetails();
    final tsmId = details?.user?.id ?? '';
    final orderBookerId = widget.orderBooker.id ?? '';
    final token = details?.token ?? '';

    if (tsmId.isEmpty || orderBookerId.isEmpty || token.isEmpty) {
      return Future.value(
        Left(
          GlobalErrorModel(
              error: 'Session expired or not logged in. Please sign in again.'),
        ),
      );
    }
    return OrderBookerActivityRepositoryImp().getMarketRecoveries(
      tsmId: tsmId,
      orderBookerId: orderBookerId,
      token: token,
    );
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      customAppBar(context, text: 'Market Recoveries', showText: true),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Either<GlobalErrorModel, RecoveryListingModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: ProcessingWidget());
            }
            final result = snapshot.data;
            if (result == null) return const SizedBox.shrink();

            return result.fold(
                  (l) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.error.toString(),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
                  (r) {
                if (r.data.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No market recoveries yet')),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: r.data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = r.data[i];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: FrontendConfigs.kAppBorder,
                        color: FrontendConfigs.kTextFieldColor,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  m.srNo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                '${m.amount.toStringAsFixed(0)} Rs',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: FrontendConfigs.kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.distributionName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (m.zoneName.isNotEmpty)
                            Text(
                              'Zone: ${m.zoneName}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                          if (m.townName.isNotEmpty)
                            Text(
                              'Town: ${m.townName}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                          if (m.date != null && m.date!.isNotEmpty)
                            Text(
                              'Date: ${m.date}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '${m.bankName} · ${m.paymentMode}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}