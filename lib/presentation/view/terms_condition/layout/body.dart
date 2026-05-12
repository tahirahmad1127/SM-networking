import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:sm_networking/application/setting_bloc/setting_bloc.dart';
import 'package:sm_networking/infrastructure/model/terms_condition.dart';
import 'package:sm_networking/infrastructure/services/setting.dart';
import 'package:sm_networking/presentation/view/order/no_data_found_view.dart';
import 'package:provider/provider.dart';

import '../../../../injection_container.dart';
import '../../../elements/processing_widget.dart';

class TermsConditionViewBody extends StatelessWidget {
  const TermsConditionViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SettingBloc>(),
      child: BlocBuilder<SettingBloc, SettingState>(
        builder: (context, state) {
          if (state is SettingInitial) {
            BlocProvider.of<SettingBloc>(context).add(const GetTermsConditionEvent());
            return const Center(
              child: ProcessingWidget(),
            );
          } else if (state is SettingLoading) {
            return const Center(
              child: ProcessingWidget(),
            );
          } else if (state is SettingLoaded) {
            //________If data null then show No Data Found View
            if (state.model.data == null || state.model.data!.isEmpty) {
              return const Center(
                child: NoDataFoundView(),
              );
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: HtmlWidget(state.model.data!.toString()),
              ),
            );
          }
          else if (state is SettingFailed) {
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
