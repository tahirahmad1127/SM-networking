import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/infrastructure/model/stats.dart';

import '../../../../infrastructure/services/stats.dart';
import '../../infrastructure/model/stats.dart';
import '../../infrastructure/model/user.dart';

part 'stats_event.dart';

part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsRepositoryImp repositoryImp;

  StatsBloc(this.repositoryImp) : super(StatsInitial()) {
    on<StatsEvent>((event, emit) async {
      if (event is GetStatsEvent) {
        try {
          emit(StatsLoading());

          final failureOrSuccess = await repositoryImp.getStats(event.userID);

          failureOrSuccess.fold((l) => emit(StatsFailed(l.error.toString())),
              (r) {
            return emit(StatsLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}
