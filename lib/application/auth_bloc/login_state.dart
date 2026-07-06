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

/// Emitted when the backend rejects login with ALREADY_LOGGED_IN. Carries
/// the original credentials so the UI's confirmation dialog can re-fire
/// LoginUserEvent with isForce: true without asking the user to retype
/// their email/password.
class AuthAlreadyLoggedIn extends AuthState {
  final String message;
  final bool canForceLogin;
  final String identifier;
  final String password;
  final bool isPhone;

  const AuthAlreadyLoggedIn({
    required this.message,
    required this.canForceLogin,
    required this.identifier,
    required this.password,
    required this.isPhone,
  });

  @override
  List<Object> get props => [message, canForceLogin, identifier, password, isPhone];
}