part of 'order_bloc.dart';

@immutable
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object> get props => [];
}

class GetPendingOrderEvent extends OrderEvent {
  final String userID;

  const GetPendingOrderEvent(this.userID);
}

class GetProcessedOrderEvent extends OrderEvent {
  final String userID;

  const GetProcessedOrderEvent(this.userID);
}

class GetCompletedOrderEvent extends OrderEvent {
  final String userID;

  const GetCompletedOrderEvent(this.userID);
}

class GetCancelledOrderEvent extends OrderEvent {
  final String userID;

  const GetCancelledOrderEvent(this.userID);
}

class CreateOrderEvent extends OrderEvent {
  final CreateOrderModel model;

  const CreateOrderEvent(this.model);
}

class CancelOrderEvent extends OrderEvent {
  final String orderID;
  const CancelOrderEvent(this.orderID);
}

class CreateDraftEvent extends OrderEvent {
  final CreateOrderModel model;
  const CreateDraftEvent(this.model);
}