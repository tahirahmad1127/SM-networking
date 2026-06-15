part of 'brand_bloc.dart';

@immutable
abstract class BrandEvent extends Equatable {
  const BrandEvent();

  @override
  List<Object> get props => [];
}

class GetBrandEvent extends BrandEvent {
  final String categoryID;
  const GetBrandEvent(this.categoryID);
}

class GetAllBrandsEvent extends BrandEvent {
  const GetAllBrandsEvent();
}