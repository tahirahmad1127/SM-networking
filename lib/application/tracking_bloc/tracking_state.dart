// tracking_state.dart
part of 'tracking_bloc.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingSuccess extends TrackingState {
  final TrackingResponseModel model;

  const TrackingSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

class TrackingFailed extends TrackingState {
  final String message;

  const TrackingFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class TrackingActive extends TrackingState {
  final int intervalMinutes;

  const TrackingActive({required this.intervalMinutes});

  @override
  List<Object?> get props => [intervalMinutes];
}

class TrackingInactive extends TrackingState {}