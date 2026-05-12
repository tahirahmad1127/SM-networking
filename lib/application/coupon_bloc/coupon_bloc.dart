// lib/application/coupon_bloc/coupon_bloc.dart

import 'dart:async';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/model/coupon.dart';
import '../../infrastructure/services/coupon.dart';

part 'coupon_event.dart';
part 'coupon_state.dart';

class CouponBloc extends Bloc<CouponEvent, CouponState> {
  final CouponRepositoryImp repository;

  CouponBloc(this.repository) : super(CouponInitial()) {
    on<ApplyCouponEvent>(_onApplyCoupon);
  }

  Future<void> _onApplyCoupon(ApplyCouponEvent event, Emitter<CouponState> emit) async {
    try {
      emit(CouponLoading());
      final failureOrSuccess = await repository.applyCoupon(event.body);

      failureOrSuccess.fold(
            (l) => emit(CouponFailed(l.error.toString())),
            (r) => emit(CouponLoaded(r)),
      );
    } catch (e, s) {
      log("❌ Coupon Error: $e\n$s");
      emit(CouponFailed(e.toString()));
    }
  }
}
