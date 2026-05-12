import 'dart:async';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/model/attendance.dart';
import '../../infrastructure/services/attendance.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepositoryImp repositoryImp;

  AttendanceBloc(this.repositoryImp) : super(AttendanceInitial()) {
    on<CheckInEvent>(_onCheckIn);
    on<CheckOutEvent>(_onCheckOut);
  }

  Future<void> _onCheckIn(CheckInEvent event, Emitter<AttendanceState> emit) async {
    try {
      emit(AttendanceLoading());
      log("Bloc: ⏱️ Triggering Check-In...");
      final failureOrSuccess = await repositoryImp.checkIn(event.body);

      failureOrSuccess.fold(
            (l) => emit(AttendanceFailed(l.error.toString())),
            (r) => emit(AttendanceLoaded(r, isCheckIn: true)),
      );
    } catch (e, s) {
      log("❌ Check-In Error: $e\n$s");
      emit(AttendanceFailed(e.toString()));
    }
  }

  Future<void> _onCheckOut(CheckOutEvent event, Emitter<AttendanceState> emit) async {
    try {
      emit(AttendanceLoading());
      log("Bloc: ⏱️ Triggering Check-Out...");
      final failureOrSuccess = await repositoryImp.checkOut(event.attendanceId, event.body);

      failureOrSuccess.fold(
            (l) => emit(AttendanceFailed(l.error.toString())),
            (r) => emit(AttendanceLoaded(r, isCheckIn: false)),
      );
    } catch (e, s) {
      log("❌ Check-Out Error: $e\n$s");
      emit(AttendanceFailed(e.toString()));
    }
  }
}
