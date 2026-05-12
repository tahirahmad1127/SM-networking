part of 'visit_bloc.dart';

abstract class VisitEvent extends Equatable {
  const VisitEvent();

  @override
  List<Object?> get props => [];
}

class AddVisitEvent extends VisitEvent {
  final VisitModel visit;

  const AddVisitEvent(this.visit);

  @override
  List<Object?> get props => [visit];
}
