import 'package:flutter/material.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/presentation/view/reciept/layout/body.dart';

class ReceiptView extends StatelessWidget {
  final OrderModel model;

  const ReceiptView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return ReceiptBody(model: model);
  }
}
