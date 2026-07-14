import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../infrastructure/model/all_brands.dart';
import '../../infrastructure/model/brand.dart';
import '../../infrastructure/services/brand.dart';
import '../../infrastructure/services/cache.dart';

part 'brand_event.dart';

part 'brand_state.dart';

class BrandBloc extends Bloc<BrandEvent, BrandState> {
  final BrandRepositoryImp repositoryImp;

  BrandBloc(this.repositoryImp) : super(BrandInitial()) {
    on<BrandEvent>((event, emit) async {
      if (event is GetBrandEvent) {
        try {
          emit(BrandLoading());
          BrandListingModel? model = await CacheServices.instance.readBrands();
          log(model.toString());
          final failureOrSuccess =
              await repositoryImp.getBrands(event.categoryID);
          failureOrSuccess.fold((l) => emit(BrandFailed(l.error.toString())),
              (r) {
            CacheServices.instance.writeBrands(r);
            emit(BrandLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is GetAllBrandsEvent) {
        try {
          emit(BrandLoading());
          final failureOrSuccess = await repositoryImp.getAllBrands();
          failureOrSuccess.fold(
            (l) => emit(BrandFailed(l.error.toString())),
            (r) => emit(AllBrandsLoaded(r)),
          );
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}
