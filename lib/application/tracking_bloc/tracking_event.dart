// tracking_event.dart
part of 'tracking_bloc.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

class SendCoordinatesEvent extends TrackingEvent {
  final Map<String, dynamic> body;
  final bool isPeriodicUpdate;

  const SendCoordinatesEvent(this.body, {this.isPeriodicUpdate = false});

  @override
  List<Object?> get props => [body, isPeriodicUpdate];
}

class StartTrackingEvent extends TrackingEvent {
  final int intervalMinutes;
  final Future<Map<String, dynamic>> Function() getCoordinatesBody;

  const StartTrackingEvent({
    required this.intervalMinutes,
    required this.getCoordinatesBody,
  });

  @override
  List<Object?> get props => [intervalMinutes];
}

class StopTrackingEvent extends TrackingEvent {
  const StopTrackingEvent();
}