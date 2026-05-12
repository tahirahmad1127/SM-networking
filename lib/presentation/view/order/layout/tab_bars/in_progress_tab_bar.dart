import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/order/no_data_found_view.dart';
import 'package:provider/provider.dart';

import '../../../../../application/order_bloc/order_bloc.dart';
import '../../../../../infrastructure/services/order.dart';
import '../../../../../injection_container.dart';
import '../../../../../utils/utils.dart';
import '../../../../elements/loaders.dart';
import '../../order_details/order_details_view.dart';
import '../../widgets/order_card.dart';

class InProgressTabBar extends StatelessWidget {
  const InProgressTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    return BlocProvider(
      create: (context) => sl<OrderBloc>(),
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderInitial) {
            BlocProvider.of<OrderBloc>(context).add(GetPendingOrderEvent(
                user.getSalesUserDetails()!.user!.id.toString()));

            return const Center(
              child: ProcessingWidget(),
            );
          } else if (state is OrderLoading) {
            return const Center(
              child: ProcessingWidget(),
            );
          } else if (state is OrderLoaded) {
            return state.model.data!.isEmpty
                ? NoDataFoundView()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.model.data!.length,
                    itemBuilder: (context, i) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrderDetailsView(
                                        model: state.model.data![i],
                                      ))).then((val) {
                            if (val == true) {
                              BlocProvider.of<OrderBloc>(context).add(
                                  GetPendingOrderEvent(user
                                      .getSalesUserDetails()!
                                      .user!
                                      .id
                                      .toString()));
                            }
                          });
                        },
                        child: OrderCard(
                          status: 'Pending',
                          model: state.model.data![i],
                        ),
                      );
                    });
          } else if (state is OrderFailed) {
            return Center(
              child: Text(state.message.toString()),
            );
          } else {
            return const Center(
              child: Text("Something went wrong"),
            );
          }
        },
      ),
    );
  }
}
