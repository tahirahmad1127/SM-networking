part of 'login_bloc.dart';

@immutable
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginUserEvent extends AuthEvent {
  final String identifier;
  final String password;
  final bool isPhone;

  const LoginUserEvent({
    required this.identifier,
    required this.password,
    this.isPhone = false,
  });

  @override
  List<Object> get props => [identifier, password, isPhone];
}


class UserDetailsEvent extends AuthEvent {
  final String userID;

  const UserDetailsEvent({required this.userID});
}
