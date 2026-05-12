part of 'product_bloc.dart';

@immutable
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

class GetProductEvent extends ProductEvent {
  final String cityID;
  final String categoryID;
  final String brandID;
  final bool isRefresh;

  const GetProductEvent(
      {required this.cityID,
      required this.isRefresh,
      required this.brandID,
      required this.categoryID});
}

class GetProductByBrandEvent extends ProductEvent {
  final String brandID;

  const GetProductByBrandEvent(this.brandID);
}

class GetProductByID extends ProductEvent {
  final String productID;

  const GetProductByID(this.productID);
}
