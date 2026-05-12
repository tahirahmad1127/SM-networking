part of 'stats_bloc.dart';

@immutable
abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final StatsListingModel model;

  const StatsLoaded(this.model);
}

class StatsFailed extends StatsState {
  final String message;

  const StatsFailed(this.message);
}
