import 'dart:async';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/model/visit.dart';
import '../../infrastructure/services/visit.dart';

part 'visit_event.dart';
part 'visit_state.dart';

class VisitBloc extends Bloc<VisitEvent, VisitState> {
  final VisitRepositoryImp repositoryImp;

  VisitBloc(this.repositoryImp) : super(VisitInitial()) {
    on<AddVisitEvent>(_onAddVisit);
  }


  Future<void> _onAddVisit(AddVisitEvent event, Emitter<VisitState> emit) async {
    try {
      emit(VisitLoading());
      log("Bloc: 🟢 Triggering Add Visit...");

      // Pass the entire visit model
      final result = await repositoryImp.addVisit(event.visit);

      result.fold(
            (l) => emit(VisitFailed(l.error.toString())),
            (r) => emit(VisitLoaded(r)),
      );
    } catch (e, s) {
      log("❌ Add Visit Error: $e\n$s");
      emit(VisitFailed(e.toString()));
    }
  }
}
