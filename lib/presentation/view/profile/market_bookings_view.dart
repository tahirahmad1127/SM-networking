import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/order_booker_activity.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';

/// Market bookings placed by [orderBooker], scoped to the logged-in
/// warehouseManager (TSM). Reached from [OrderBookerActionsView] →
/// "Market Bookings".
class MarketBookingsView extends StatefulWidget {
  final OrderBooker orderBooker;

  const MarketBookingsView({super.key, required this.orderBooker});

  @override
  State<MarketBookingsView> createState() => _MarketBookingsViewState();
}

class _MarketBookingsViewState extends State<MarketBookingsView> {
  late Future<Either<GlobalErrorModel, OrderListingModel>> _future;
  bool _futureInited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureInited) return;
    _futureInited = true;
    _future = _load();
  }

  Future<Either<GlobalErrorModel, OrderListingModel>> _load() {
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
    return OrderBookerActivityRepositoryImp().getMarketBookingOrders(
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
      appBar: customAppBar(context, text: 'Market Bookings', showText: true),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Either<GlobalErrorModel, OrderListingModel>>(
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
                final orders = r.data ?? [];
                if (orders.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No market bookings yet')),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order.items ?? [];
    final firstItemName =
    items.isNotEmpty ? (items.first.productId?.englishTitle ?? '') : '';
    final extraCount = items.length > 1 ? items.length - 1 : 0;
    final status = order.status ?? '';
    final id = order.id ?? '';
    final shortId = id.length > 6 ? id.substring(id.length - 6) : id;
    final date = order.createdAt;

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
                  '#$shortId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${(order.total ?? 0).toStringAsFixed(0)} Rs',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FrontendConfigs.kPrimaryColor,
                ),
              ),
            ],
          ),
          if (firstItemName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              extraCount > 0
                  ? '$firstItemName  +$extraCount more'
                  : firstItemName,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if ((order.shippingAddress ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              order.shippingAddress!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (status.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FrontendConfigs.kPrimaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (date != null)
                Text(
                  '${date.day.toString().padLeft(2, '0')}/'
                      '${date.month.toString().padLeft(2, '0')}/'
                      '${date.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}