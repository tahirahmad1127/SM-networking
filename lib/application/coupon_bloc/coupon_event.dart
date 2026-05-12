part of 'coupon_bloc.dart';

abstract class CouponEvent extends Equatable {
  const CouponEvent();

  @override
  List<Object?> get props => [];
}

class ApplyCouponEvent extends CouponEvent {
  final Map<String, dynamic> body;
  const ApplyCouponEvent(this.body);

  @override
  List<Object?> get props => [body];
}
