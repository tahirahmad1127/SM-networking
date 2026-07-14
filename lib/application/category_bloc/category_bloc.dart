import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/infrastructure/model/category.dart';

import '../../../../infrastructure/services/Category.dart';
import '../../infrastructure/services/cache.dart';

part 'category_event.dart';

part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepositoryImp repositoryImp;

  CategoryBloc(this.repositoryImp) : super(CategoryInitial()) {
    on<CategoryEvent>((event, emit) async {
      if (event is GetCategoryEvent) {
        try {
          emit(CategoryLoading());
          CategoryListingModel? model =
              await CacheServices.instance.readCategories();
          // if (model == null) {
          final failureOrSuccess =
              await repositoryImp.getCategories(event.cityID.toString());
          failureOrSuccess.fold((l) => emit(CategoryFailed(l.error.toString())),
              (r) {
            CacheServices.instance.writeCategories(r);
            return emit(CategoryLoaded(r));
          });
          // } else {
          //   emit(CategoryLoaded(model));
          // }
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}
