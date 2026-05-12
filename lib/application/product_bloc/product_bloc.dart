import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/infrastructure/model/product.dart';

import '../../../../infrastructure/services/product.dart';
import '../../infrastructure/model/product.dart';
import '../../infrastructure/model/user.dart';

part 'product_event.dart';

part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepositoryImp repositoryImp;
  int page = 1;

  ProductBloc(this.repositoryImp) : super(ProductInitial()) {
    on<ProductEvent>((event, emit) async {
      if (event is GetProductEvent) {
        try {
          emit(ProductLoading());
          if (event.isRefresh) {
            page = 1;
          }
          final failureOrSuccess =
              await repositoryImp.getProducts(cityID: event.cityID,brandID: event.brandID, page: page, categoryID: event.categoryID);

          failureOrSuccess.fold((l) => emit(ProductFailed(l.error.toString())),
              (r) {
            return emit(ProductLoaded(r));
          });

          page++;
        } catch (e) {
          rethrow;
        }
      } else if (event is GetProductByBrandEvent) {
        try {
          emit(ProductLoading());

          final failureOrSuccess = await repositoryImp
              .getProductsByBrandID(event.brandID.toString());
          failureOrSuccess.fold((l) => emit(ProductFailed(l.error.toString())),
              (r) {
            return emit(ProductLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is GetProductByID) {
        try {
          emit(ProductLoading());

          final failureOrSuccess =
              await repositoryImp.getProductByID(event.productID.toString());
          failureOrSuccess.fold((l) => emit(ProductFailed(l.error.toString())),
              (r) {
            return emit(SingleProductLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}
