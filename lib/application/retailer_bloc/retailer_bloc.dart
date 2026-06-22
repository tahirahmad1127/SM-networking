//
// import 'package:equatable/equatable.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sm_networking/infrastructure/model/add_retailer.dart';
// import 'package:sm_networking/infrastructure/model/retailer.dart';
//
// import '../../infrastructure/services/Retailer.dart';
//
//
//
// part 'retailer_event.dart';
// part 'retailer_state.dart';
//
// class RetailerBloc extends Bloc<RetailerEvent, RetailerState> {
//   final RetailerRepositoryImp repositoryImp;
//
//   RetailerBloc(this.repositoryImp) : super(RetailerInitial()) {
//     on<RetailerEvent>((event, emit) async {
//       if (event is GetRetailerEvent) {
//         try {
//           emit(RetailerLoading());
//           final failureOrSuccess =
//           await repositoryImp.getRetailers(event.cityID.toString());
//           failureOrSuccess.fold(
//                 (l) => emit(RetailerFailed(l.error.toString())),
//                 (r) => emit(RetailerLoaded(r)),
//           );
//         } catch (e) {
//           emit(RetailerFailed(e.toString()));
//         }
//       } else if (event is AddRetailerEvent) {
//         try {
//           emit(RetailerLoading());
//           final failureOrSuccess = await repositoryImp.addRetailer(event.model);
//           failureOrSuccess.fold(
//                 (l) => emit(RetailerFailed(l.error.toString())),
//                 (r) => emit(RetailerAdded(r)),
//           );
//         } catch (e) {
//           emit(RetailerFailed(e.toString()));
//         }
//       } else if (event is UpdateRetailerLocationEvent) {
//         try {
//           emit(RetailerLoading());
//           final failureOrSuccess = await repositoryImp.updateRetailerLocation(
//             retailerId: event.retailerId,
//             lat: event.lat,
//             lng: event.lng,
//           );
//           failureOrSuccess.fold(
//                 (l) => emit(RetailerFailed(l.error.toString())),
//                 (r) => emit(RetailerLocationUpdated(r)),
//           );
//         } catch (e) {
//           emit(RetailerFailed(e.toString()));
//         }
//       }
//     });
//   }
// }


// import 'package:equatable/equatable.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sm_networking/infrastructure/model/add_retailer.dart';
// import 'package:sm_networking/infrastructure/model/retailer.dart';
// import 'package:sm_networking/infrastructure/services/Retailer.dart';
// import '../../infrastructure/services/retailers_cache.dart';
//
// part 'retailer_event.dart';
// part 'retailer_state.dart';
//
// class RetailerBloc extends Bloc<RetailerEvent, RetailerState> {
//   final RetailerRepositoryImp repositoryImp;
//
//   RetailerBloc(this.repositoryImp) : super(RetailerInitial()) {
//     on<GetRetailerEvent>(_onGetRetailer);
//     on<AddRetailerEvent>(_onAddRetailer);
//     on<UpdateRetailerLocationEvent>(_onUpdateRetailerLocation);
//   }
//
//   Future<void> _onGetRetailer(GetRetailerEvent event, Emitter<RetailerState> emit) async {
//     try {
//       emit(RetailerLoading());
//
//       // 1) show cached if present
//       final cachedRetailers = await RetailerCacheService.getCachedRetailers();
//       if (cachedRetailers != null && cachedRetailers.isNotEmpty) {
//         emit(RetailerLoaded(RetailersListingModel(data: cachedRetailers)));
//       }
//
//       // 2) fetch fresh list from API
//       final result = await repositoryImp.getRetailers(event.cityID.toString());
//       await result.fold(
//             (l) async {
//           emit(RetailerFailed(l.error.toString()));
//         }, (r) async {
//           // r is RetailersListingModel — save r.data (list) to cache
//           final list = r.data ?? [];
//           await RetailerCacheService.saveRetailers(list);
//           emit(RetailerLoaded(r));
//         },
//       );
//     } catch (e) {
//       emit(RetailerFailed(e.toString()));
//     }
//   }
//
//   Future<void> _onAddRetailer(AddRetailerEvent event, Emitter<RetailerState> emit) async {
//     try {
//       emit(RetailerLoading());
//
//       final result = await repositoryImp.addRetailer(event.model);
//       await result.fold(
//             (l) async {
//           emit(RetailerFailed(l.error.toString()));
//         },
//             (r) async {
//           // r is a single RetailerModel (newly created)
//           final newRetailer = r; // RetailerModel
//           final cached = await RetailerCacheService.getCachedRetailers() ?? [];
//
//           // avoid duplicates: check by id
//           final existsIndex = cached.indexWhere((e) => e.id == newRetailer.id);
//           if (existsIndex == -1) {
//             cached.add(newRetailer);
//           } else {
//             cached[existsIndex] = newRetailer;
//           }
//
//           await RetailerCacheService.saveRetailers(cached);
//
//           emit(RetailerAdded(newRetailer));
//           emit(RetailerLoaded(RetailersListingModel(data: cached)));
//         },
//       );
//     } catch (e) {
//       emit(RetailerFailed(e.toString()));
//     }
//   }
//
//   Future<void> _onUpdateRetailerLocation(UpdateRetailerLocationEvent event, Emitter<RetailerState> emit) async {
//     try {
//       emit(RetailerLoading());
//
//       final result = await repositoryImp.updateRetailerLocation(
//         retailerId: event.retailerId,
//         lat: event.lat,
//         lng: event.lng,
//       );
//
//       await result.fold(
//             (l) async {
//           emit(RetailerFailed(l.error.toString()));
//         },
//             (r) async {
//           // r is the updated RetailerModel
//           final updatedRetailer = r;
//           final cached = await RetailerCacheService.getCachedRetailers() ?? [];
//
//           final index = cached.indexWhere((e) => e.id == updatedRetailer.id || e.id == event.retailerId);
//           if (index != -1) {
//             // If your model has copyWith, you can also do:
//             // cached[index] = cached[index].copyWith(lat: event.lat, lng: event.lng);
//             // But since API returns updatedRetailer, just replace it:
//             cached[index] = updatedRetailer;
//             await RetailerCacheService.saveRetailers(cached);
//           }
//
//           emit(RetailerLocationUpdated(updatedRetailer));
//           emit(RetailerLoaded(RetailersListingModel(data: cached)));
//         },
//       );
//     } catch (e) {
//       emit(RetailerFailed(e.toString()));
//     }
//   }
// }


import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/infrastructure/model/add_retailer.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import '../../infrastructure/model/add_recovery.dart';
import '../../infrastructure/model/banks.dart';
import '../../infrastructure/services/retailers_cache.dart';

part 'retailer_event.dart';
part 'retailer_state.dart';

class RetailerBloc extends Bloc<RetailerEvent, RetailerState> {
  final RetailerRepositoryImp repositoryImp;

  RetailerBloc(this.repositoryImp) : super(RetailerInitial()) {
    on<GetRetailerEvent>(_onGetRetailer);
    on<AddRetailerEvent>(_onAddRetailer);
    on<UpdateRetailerLocationEvent>(_onUpdateRetailerLocation);
    on<GetAllBanksEvent>(_onGetAllBanks);
    on<AddRecoveryEvent>(_onAddRecovery);
  }

  Future<void> _onGetRetailer(GetRetailerEvent event, Emitter<RetailerState> emit) async {
    try {
      emit(RetailerLoading());

      // Show cached if present
      final cachedRetailers = await RetailerCacheService.getCachedRetailers();
      if (cachedRetailers != null && cachedRetailers.isNotEmpty) {
        emit(RetailerLoaded(RetailersListingModel(data: cachedRetailers)));
      }

      // Fetch fresh list from both retailer + wholesaler endpoints
      final result = await repositoryImp.getAllRetailersAndWholesalers();
      await result.fold(
            (l) async {
          emit(RetailerFailed(l.error.toString()));
        },
            (r) async {
          final list = r.data ?? [];
          await RetailerCacheService.saveRetailers(list);
          emit(RetailerLoaded(r));
        },
      );
    } catch (e) {
      emit(RetailerFailed(e.toString()));
    }
  }

  Future<void> _onAddRetailer(AddRetailerEvent event, Emitter<RetailerState> emit) async {
    try {
      emit(RetailerLoading());

      final result = await repositoryImp.addRetailer(event.model);
      await result.fold(
            (l) async {
          emit(RetailerFailed(l.error.toString()));
        },
            (r) async {
          final newRetailer = r;
          final cached = await RetailerCacheService.getCachedRetailers() ?? [];

          final existsIndex = cached.indexWhere((e) => e.id == newRetailer.id);
          if (existsIndex == -1) {
            cached.add(newRetailer);
          } else {
            cached[existsIndex] = newRetailer;
          }

          await RetailerCacheService.saveRetailers(cached);

          emit(RetailerAdded(newRetailer));
          emit(RetailerLoaded(RetailersListingModel(data: cached)));
        },
      );
    } catch (e) {
      emit(RetailerFailed(e.toString()));
    }
  }

  Future<void> _onUpdateRetailerLocation(UpdateRetailerLocationEvent event, Emitter<RetailerState> emit) async {
    try {
      emit(RetailerLoading());

      final result = await repositoryImp.updateRetailerLocation(
        retailerId: event.retailerId,
        lat: event.lat,
        lng: event.lng,
        token: event.token,
      );

      await result.fold(
            (l) async {
          emit(RetailerFailed(l.error.toString()));
        },
            (r) async {
          final updatedRetailer = r;
          final cached = await RetailerCacheService.getCachedRetailers() ?? [];

          final index = cached.indexWhere((e) => e.id == updatedRetailer.id || e.id == event.retailerId);
          if (index != -1) {
            cached[index] = updatedRetailer;
            await RetailerCacheService.saveRetailers(cached);
          }

          emit(RetailerLocationUpdated(updatedRetailer));
          emit(RetailerLoaded(RetailersListingModel(data: cached)));
        },
      );
    } catch (e) {
      emit(RetailerFailed(e.toString()));
    }
  }

  Future<void> _onGetAllBanks(GetAllBanksEvent event, Emitter<RetailerState> emit) async {
    try {
      emit(BanksLoading());

      // 1) Show cached banks if present
      final cachedBanks = await RetailerCacheService.getCachedBanks();
      if (cachedBanks != null && cachedBanks.isNotEmpty) {
        emit(BanksLoaded(BanksListModel(banks: cachedBanks)));
      }

      // 2) Fetch fresh banks from API
      final result = await repositoryImp.getAllBanks();
      result.fold(
            (l) => emit(BanksFailed(l.error.toString())),
            (r) {
          // synchronous part only – cache can be awaited BEFORE emit
          RetailerCacheService.saveBanks(r.banks);
          emit(BanksLoaded(r));
        },
      );
    } catch (e) {
      emit(BanksFailed(e.toString()));
    }
  }


  Future<void> _onAddRecovery(AddRecoveryEvent event, Emitter<RetailerState> emit) async {
    try {
      emit(RecoveryLoading());

      final result = await repositoryImp.addRecovery(event.model, event.token);
      result.fold(
            (l) => emit(RecoveryFailed(l.error.toString())),
            (r) => emit(RecoveryAdded(r)),
      );
    } catch (e) {
      emit(RecoveryFailed(e.toString()));
    }
  }
}