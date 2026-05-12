part of 'coupon_bloc.dart';

abstract class CouponState extends Equatable {
  const CouponState();

  @override
  List<Object?> get props => [];
}

class CouponInitial extends CouponState {}

class CouponLoading extends CouponState {}

class CouponLoaded extends CouponState {
  final CouponModel model;
  const CouponLoaded(this.model);

  @override
  List<Object?> get props => [model];
}

class CouponFailed extends CouponState {
  final String message;
  const CouponFailed(this.message);

  @override
  List<Object?> get props => [message];
}
