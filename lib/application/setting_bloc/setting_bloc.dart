import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/infrastructure/model/terms_condition.dart';

import '../../infrastructure/model/user.dart';
import '../../infrastructure/services/Setting.dart';

part 'setting_event.dart';

part 'setting_state.dart';

class SettingBloc extends Bloc<SettingEvent, SettingState> {
  final SettingRepositoryImp repositoryImp;

  SettingBloc(this.repositoryImp) : super(SettingInitial()) {
    on<SettingEvent>((event, emit) async {
      if (event is GetTermsConditionEvent) {
        try {
          emit(SettingLoading());

          final failureOrSuccess = await repositoryImp.getTermsCondition();
          failureOrSuccess.fold((l) => emit(SettingFailed(l.error.toString())),
              (r) {
            return emit(SettingLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is GetPrivacyPolicyEvent) {
        try {
          emit(SettingLoading());

          final failureOrSuccess = await repositoryImp.getTermsCondition();
          failureOrSuccess.fold((l) => emit(SettingFailed(l.error.toString())),
              (r) {
            return emit(SettingLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}
