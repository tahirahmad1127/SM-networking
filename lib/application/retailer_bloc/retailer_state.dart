part of 'retailer_bloc.dart';

@immutable
abstract class RetailerState extends Equatable {
  const RetailerState();

  @override
  List<Object> get props => [];
}

class RetailerInitial extends RetailerState {}

class RetailerLoading extends RetailerState {}

class RetailerLoaded extends RetailerState {
  final RetailersListingModel model;
  const RetailerLoaded(this.model);

  @override
  List<Object> get props => [model];
}

class RetailerAdded extends RetailerState {
  final RetailerModel model;
  const RetailerAdded(this.model);

  @override
  List<Object> get props => [model];
}

class RetailerLocationUpdated extends RetailerState {
  final RetailerModel model;
  const RetailerLocationUpdated(this.model);

  @override
  List<Object> get props => [model];
}

class RetailerFailed extends RetailerState {
  final String message;
  const RetailerFailed(this.message);

  @override
  List<Object> get props => [message];
}

// Banks States
class BanksLoading extends RetailerState {}

class BanksLoaded extends RetailerState {
  final BanksListModel model;
  const BanksLoaded(this.model);

  @override
  List<Object> get props => [model];
}

class BanksFailed extends RetailerState {
  final String message;
  const BanksFailed(this.message);

  @override
  List<Object> get props => [message];
}

// Recovery States
class RecoveryLoading extends RetailerState {}

class RecoveryAdded extends RetailerState {
  final RecoveryModel model;
  const RecoveryAdded(this.model);

  @override
  List<Object> get props => [model];
}

class RecoveryFailed extends RetailerState {
  final String message;
  const RecoveryFailed(this.message);

  @override
  List<Object> get props => [message];
}