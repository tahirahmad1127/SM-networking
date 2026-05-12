import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../infrastructure/model/brand.dart';
import '../../infrastructure/model/user.dart';
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
          // if (model == null) {
            final failureOrSuccess =
                await repositoryImp.getBrands(event.categoryID);
            failureOrSuccess.fold((l) => emit(BrandFailed(l.error.toString())),
                (r) {
              CacheServices.instance.writeBrands(r);
              emit(BrandLoaded(r));
            });
          // } else {
          //   emit(BrandLoaded(model));
          // }
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}
