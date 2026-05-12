part of 'visit_bloc.dart';

abstract class VisitState extends Equatable {
  const VisitState();

  @override
  List<Object?> get props => [];
}

class VisitInitial extends VisitState {}

class VisitLoading extends VisitState {}

class VisitLoaded extends VisitState {
  final VisitModel model;

  const VisitLoaded(this.model);

  @override
  List<Object?> get props => [model];
}

class VisitFailed extends VisitState {
  final String message;

  const VisitFailed(this.message);

  @override
  List<Object?> get props => [message];
}
