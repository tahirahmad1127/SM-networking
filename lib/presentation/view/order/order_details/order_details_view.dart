import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/application/order_bloc/order_bloc.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/infrastructure/services/order.dart';
import 'package:sm_networking/infrastructure/services/product.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/navigation_dialog.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/order/order_details/layout/body.dart';
import 'package:sm_networking/presentation/view/order/order_invoice/order_invoice.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';

import '../../../../configurations/frontend_configs.dart';
import '../../../../configurations/translation_helper.dart';
import '../../../../injection_container.dart';
import '../../../elements/app_button.dart';
import '../../../elements/custom_appbar.dart';
import '../../reciept/reciept_view.dart';

class OrderDetailsView extends StatefulWidget {
  final OrderModel model;

  const OrderDetailsView({super.key, required this.model});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OrderBloc>(),
      child: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderCancelled) {
            Navigator.pop(context,true);
          }else if(state is OrderFailed){
            getFlushBar(context, title: state.message.toString());
          }
        },
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            return LoadingOverlay(
              isLoading: state is OrderLoading,
              color: Colors.transparent,
              progressIndicator: const ProcessingWidget(),
              child: Scaffold(
                bottomNavigationBar: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              top: BorderSide(
                                  color: FrontendConfigs.kAuthTextColor,
                                  width: 0.2))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ReceiptView(
                                                model: widget.model,
                                              )));
                                },
                                btnLabel: TranslationHelper.getTranslatedText(
                                    "Share Invoice"),
                                width: MediaQuery.of(context).size.width / 2.25,
                                btnColor: const Color(0xff121212),
                                height: 48,
                              ),
                            ),
                            if (widget.model.statuses.toString() != "Cancelled")
                              const SizedBox(
                                width: 10,
                              ),
                            if (widget.model.status != "Completed" &&
                                widget.model.status != "Cancelled")
                              Expanded(
                                child: AppButton(
                                  onPressed: () {
                                    showNavigationDialog(context,
                                        message:
                                            "Do you really want to cancel this order?",
                                        buttonText: "Yes",
                                        navigation: () async {
                                          Navigator.pop(context);
                                          BlocProvider.of<OrderBloc>(context).add(
                                              CancelOrderEvent(
                                                  widget.model.id.toString()));
                                    },
                                        secondButtonText: "No",
                                        showSecondButton: true);
                                  },
                                  btnLabel: TranslationHelper.getTranslatedText(
                                      'cancel_order'),
                                  width:
                                      MediaQuery.of(context).size.width / 2.25,
                                  height: 48,
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                appBar: customAppBar(context),
                body: OrderDetailsBody(
                  model: widget.model,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
