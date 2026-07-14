import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/application/order_bloc/order_bloc.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:provider/provider.dart';

import '../../../../../injection_container.dart';
import '../../no_data_found_view.dart';
import '../../order_details/order_details_view.dart';
import '../../widgets/order_card.dart';

class CancelledTabBar extends StatefulWidget {
  const CancelledTabBar({super.key});

  @override
  State<CancelledTabBar> createState() => _CancelledTabBarState();
}

class _CancelledTabBarState extends State<CancelledTabBar>
    with AutomaticKeepAliveClientMixin {
  late final OrderBloc _bloc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bloc = sl<OrderBloc>();
    _refresh();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _refresh() {
    final userId = Provider.of<UserProvider>(context, listen: false)
        .getSalesUserDetails()
        ?.user
        ?.id
        ?.toString();
    if (userId != null) _bloc.add(GetCancelledOrderEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading || state is OrderInitial) {
            return const Center(child: ProcessingWidget());
          } else if (state is OrderLoaded) {
            if (state.model.data!.isEmpty) return const NoDataFoundView();
            return ListView.builder(
              itemCount: state.model.data!.length,
              itemBuilder: (context, i) {
                final order = state.model.data![i];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsView(model: order),
                      ),
                    ).then((val) {
                      if (val == true) _refresh();
                    });
                  },
                  child: OrderCard(status: 'Cancelled', model: order),
                );
              },
            );
          } else if (state is OrderFailed) {
            return Center(child: Text(state.message.toString()));
          }
          return const Center(child: Text("Something went wrong"));
        },
      ),
    );
  }
}