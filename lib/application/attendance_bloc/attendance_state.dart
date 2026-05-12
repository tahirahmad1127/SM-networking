part of 'attendance_bloc.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final AttendanceModel model;
  final bool isCheckIn;

  const AttendanceLoaded(this.model, {required this.isCheckIn});

  @override
  List<Object?> get props => [model, isCheckIn];
}

class AttendanceFailed extends AttendanceState {
  final String message;

  const AttendanceFailed(this.message);

  @override
  List<Object?> get props => [message];
}
