import 'package:flutter/material.dart';

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
