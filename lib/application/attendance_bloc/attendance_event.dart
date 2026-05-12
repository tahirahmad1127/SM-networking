part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class CheckInEvent extends AttendanceEvent {
  final Map<String, dynamic> body;

  const CheckInEvent(this.body);

  @override
  List<Object?> get props => [body];
}

class CheckOutEvent extends AttendanceEvent {
  final String attendanceId;
  final Map<String, dynamic> body;

  const CheckOutEvent(this.attendanceId, this.body);

  @override
  List<Object?> get props => [attendanceId, body];
}
