part of 'order_bloc.dart';

@immutable
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final OrderListingModel model;

  const OrderLoaded(this.model);
}

class OrderCreated extends OrderState {


  const OrderCreated();
}

class OrderCancelled extends OrderState {
  const OrderCancelled();
}

class DraftCreated extends OrderState {
  const DraftCreated();
}

class OrderFailed extends OrderState {
  final String message;

  const OrderFailed(this.message);
}