import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';

import 'layout/body.dart';

class SearchView extends StatelessWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: "Search Items", showText: true),
      body: SearchViewBody(),
    );
  }
}
