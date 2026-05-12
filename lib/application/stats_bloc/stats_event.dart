part of 'stats_bloc.dart';

@immutable
abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object> get props => [];
}

class GetStatsEvent extends StatsEvent {
  final String userID;
  const GetStatsEvent(this.userID);
}
