part of 'retailer_bloc.dart';

@immutable
abstract class RetailerEvent extends Equatable {
  const RetailerEvent();

  @override
  List<Object> get props => [];
}

class GetRetailerEvent extends RetailerEvent {
  final String cityID;
  const GetRetailerEvent(this.cityID);

  @override
  List<Object> get props => [cityID];
}

class AddRetailerEvent extends RetailerEvent {
  final AddRetailerModel model;
  const AddRetailerEvent(this.model);

  @override
  List<Object> get props => [model];
}

class UpdateRetailerLocationEvent extends RetailerEvent {
  final String retailerId;
  final double lat;
  final double lng;

  const UpdateRetailerLocationEvent({
    required this.retailerId,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object> get props => [retailerId, lat, lng];
}

class GetAllBanksEvent extends RetailerEvent {
  const GetAllBanksEvent();
}

class AddRecoveryEvent extends RetailerEvent {
  final AddRecoveryModel model;
  const AddRecoveryEvent(this.model);

  @override
  List<Object> get props => [model];
}