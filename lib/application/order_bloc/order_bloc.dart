import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/infrastructure/model/create_order.dart';

import '../../infrastructure/model/order.dart';
import '../../infrastructure/services/order.dart';

part 'order_event.dart';

part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepositoryImp repositoryImp;

  OrderBloc(this.repositoryImp) : super(OrderInitial()) {
    on<OrderEvent>((event, emit) async {
      if (event is GetPendingOrderEvent) {
        try {
          emit(OrderLoading());

          final failureOrSuccess =
              await repositoryImp.getPendingOrders(event.userID);
          failureOrSuccess.fold((l) => emit(OrderFailed(l.error.toString())),
              (r) {
            return emit(OrderLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is GetProcessedOrderEvent) {
        try {
          emit(OrderLoading());

          final failureOrSuccess =
              await repositoryImp.getProcessedOrders(event.userID);
          failureOrSuccess.fold((l) => emit(OrderFailed(l.error.toString())),
              (r) {
            return emit(OrderLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is GetCompletedOrderEvent) {
        try {
          emit(OrderLoading());

          final failureOrSuccess =
              await repositoryImp.getCompletedOrders(event.userID);
          failureOrSuccess.fold((l) => emit(OrderFailed(l.error.toString())),
              (r) {
            return emit(OrderLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is GetCancelledOrderEvent) {
        try {
          emit(OrderLoading());

          final failureOrSuccess =
              await repositoryImp.getCancelledOrders(event.userID);

          failureOrSuccess.fold((l) => emit(OrderFailed(l.error.toString())),
              (r) {
            return emit(OrderLoaded(r));
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is CreateOrderEvent) {
        try {
          emit(OrderLoading());

          final failureOrSuccess = await repositoryImp.createOrder(event.model);

          failureOrSuccess.fold((l) => emit(OrderFailed(l.error.toString())),
              (r) {
            return emit(const OrderCreated());
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is CancelOrderEvent) {
        try {
          emit(OrderLoading());

          final failureOrSuccess =
              await repositoryImp.cancelOrder(event.orderID);

          failureOrSuccess.fold((l) => emit(OrderFailed(l.error.toString())),
              (r) {
            return emit(const OrderCancelled());
          });
        } catch (e) {
          rethrow;
        }
      } else if (event is CreateDraftEvent) {
        try {
          emit(OrderLoading());

          final failureOrSuccess = await repositoryImp.createDraft(event.model);

          failureOrSuccess.fold((l) => emit(OrderFailed(l.error.toString())),
              (r) {
            return emit(const DraftCreated());
          });
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}
