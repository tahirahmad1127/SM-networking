part of 'product_bloc.dart';

@immutable
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final ProductListingModel model;

  const ProductLoaded(this.model);
}
class SingleProductLoaded extends ProductState {
  final ProductModel model;

  const SingleProductLoaded(this.model);
}

class ProductFailed extends ProductState {
  final String message;

  const ProductFailed(this.message);
}
