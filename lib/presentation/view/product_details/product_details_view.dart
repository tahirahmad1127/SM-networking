import 'package:flutter/material.dart';
import 'package:sm_networking/infrastructure/model/product.dart';
import 'package:sm_networking/presentation/view/product_details/layout/body.dart';

class ProductDetailsView extends StatelessWidget {
  final ProductModel model;

  const ProductDetailsView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return ProductDetailsBody(
      model: model,
    );
  }
}
