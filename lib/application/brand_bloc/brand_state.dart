part of 'brand_bloc.dart';

@immutable
abstract class BrandState extends Equatable {
  const BrandState();

  @override
  List<Object> get props => [];
}

class BrandInitial extends BrandState {}

class BrandLoading extends BrandState {}

class BrandLoaded extends BrandState {
  final BrandListingModel model;

  const BrandLoaded(this.model);
}

class AllBrandsLoaded extends BrandState {
  final AllBrandsListingModel model;

  const AllBrandsLoaded(this.model);
}

class BrandFailed extends BrandState {
  final String message;

  const BrandFailed(this.message);
}