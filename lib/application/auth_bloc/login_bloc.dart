import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../infrastructure/services/auth.dart';
import '../../infrastructure/model/user.dart';

part 'login_event.dart';

part 'login_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImp repositoryImp;

  AuthBloc(this.repositoryImp) : super(AuthInitial()) {
    on<AuthEvent>((event, emit) async {
      if (event is LoginUserEvent) {
        try {
          emit(AuthLoading());

          final failureOrSuccess = await repositoryImp.login(
            identifier: event.identifier,
            password: event.password,
            isPhone: event.isPhone,
            isForce: event.isForce,
          );

          failureOrSuccess.fold((l) {
            if (l.code == 'ALREADY_LOGGED_IN') {
              return emit(AuthAlreadyLoggedIn(
                message: l.error ?? 'This account is already logged in on another device.',
                canForceLogin: l.canForceLogin,
                identifier: event.identifier,
                password: event.password,
                isPhone: event.isPhone,
              ));
            }
            return emit(AuthFailed(l.error.toString()));
          },
                  (r) {
                return emit(LoginLoaded(r));
              });
        } catch (e) {
          rethrow;
        }
      } else if (event is UserDetailsEvent) {
        try {
          emit(AuthLoading());

          final failureOrSuccess = await repositoryImp.getUserByID(event.userID);
          failureOrSuccess.fold((l) => emit(AuthFailed(l.error.toString())),
                  (r) {
                return emit(UserLoaded(r));
              });
        } catch (e) {
          rethrow;
        }
      }
    });
  }
}