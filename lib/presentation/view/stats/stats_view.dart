import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';

import '../../../configurations/translation_helper.dart';
import '../../elements/custom_text.dart';
import 'layout/body.dart';


class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: StatsViewBody(),
    );
  }
}


