import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/presentation/view/favorite_items/layout/body.dart';

import '../../elements/custom_text.dart';

class FavoriteItemsView extends StatelessWidget {
  const FavoriteItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: CustomText(
          text: TranslationHelper.getTranslatedText('saved_items'),
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      body: FavoriteItemsBody(),
    );
  }
}
