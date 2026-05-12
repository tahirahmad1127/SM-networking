part of 'category_bloc.dart';

@immutable
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final CategoryListingModel model;

  const CategoryLoaded(this.model);
}

class CategoryFailed extends CategoryState {
  final String message;

  const CategoryFailed(this.message);
}
