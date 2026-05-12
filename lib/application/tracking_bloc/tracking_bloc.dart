import 'dart:async';
import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/model/tracking.dart';
import '../../infrastructure/services/tracking.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepositoryImp repositoryImp;
  Timer? _trackingTimer;

  TrackingBloc(this.repositoryImp) : super(TrackingInitial()) {
    on<SendCoordinatesEvent>(_onSendCoordinates);
    on<StartTrackingEvent>(_onStartTracking);
    on<StopTrackingEvent>(_onStopTracking);
  }

  /// Handle sending coordinates to API
  Future<void> _onSendCoordinates(SendCoordinatesEvent event, Emitter<TrackingState> emit) async {
    try {
      log("📦 BLoC: Preparing to send coordinates: ${event.body}");

      emit(TrackingLoading());
      log("🌍 BLoC: Sending coordinates to API...");

      final failureOrSuccess = await repositoryImp.sendCoordinates(event.body);

      failureOrSuccess.fold((l) {
          log("❌ API Tracking Failed: ${l.error}");
          emit(TrackingFailed(l.error.toString()));
        }, (r) {
          log(" API Tracking Success: ${r.msg}");
          emit(TrackingSuccess(r));
        },
      );
    } catch (e, s) {
      log("🚨 Exception while sending coordinates: $e\n$s");
      emit(TrackingFailed(e.toString()));
    }
  }

  /// Start periodic tracking
  Future<void> _onStartTracking(
      StartTrackingEvent event, Emitter<TrackingState> emit) async {
    log("🟢 Starting periodic tracking every ${event.intervalMinutes} minutes");

    // Cancel any existing timer
    if (_trackingTimer != null) {
      log("⚠️ Existing tracking timer found — cancelling it before starting a new one.");
      _trackingTimer!.cancel();
    }

    // Send first coordinates immediately
    try {
      log("📍 Sending initial coordinates (immediate trigger)");
      final body = await event.getCoordinatesBody();
      add(SendCoordinatesEvent(body));
    } catch (e) {
      log("⚠️ Failed to get initial coordinates: $e");
    }

    // Start the periodic timer
    _trackingTimer = Timer.periodic(
      Duration(minutes: event.intervalMinutes),
          (timer) async {
        log("⏰ Timer tick #${timer.tick} — fetching new coordinates...");
        try {
          final body = await event.getCoordinatesBody();
          log("📦 Timer tick #${timer.tick} — coordinates ready: $body");
          add(SendCoordinatesEvent(body, isPeriodicUpdate: true));
        } catch (e) {
          log("⚠️ Timer tick #${timer.tick} — failed to get coordinates: $e");
        }
      },
    );

    emit(TrackingActive(intervalMinutes: event.intervalMinutes));
  }

  /// Stop periodic tracking
  Future<void> _onStopTracking(StopTrackingEvent event, Emitter<TrackingState> emit) async {
    log("🔴 Stopping periodic tracking");
    if (_trackingTimer != null) {
      _trackingTimer!.cancel();
      _trackingTimer = null;
      log("🧹 Timer cancelled successfully");
    } else {
      log("ℹ️ No active timer found to stop");
    }
    emit(TrackingInactive());
  }

  @override
  Future<void> close() {
    log("🛑 Closing TrackingBloc — cleaning up timer");
    _trackingTimer?.cancel();
    return super.close();
  }
}
