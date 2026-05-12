part of 'login_bloc.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class LoginLoaded extends AuthState {
  final UserModel model;

  const LoginLoaded(this.model);
}

class UserLoaded extends AuthState {
  final User model;

  const UserLoaded(this.model);
}

class AuthFailed extends AuthState {
  final String message;

  const AuthFailed(this.message);
}
