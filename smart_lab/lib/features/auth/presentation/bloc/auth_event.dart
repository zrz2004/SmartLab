part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String password;
  final String name;
  final String email;
  final String? phone;
  final UserRole requestedRole;

  const AuthRegisterRequested({
    required this.username,
    required this.password,
    required this.name,
    required this.email,
    this.phone,
    this.requestedRole = UserRole.undergraduate,
  });

  @override
  List<Object?> get props => [
        username,
        password,
        name,
        email,
        phone,
        requestedRole,
      ];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthLabChanged extends AuthEvent {
  final String labId;

  const AuthLabChanged({required this.labId});

  @override
  List<Object?> get props => [labId];
}

class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

class AuthUserUpdated extends AuthEvent {
  final Map<String, dynamic> updates;

  const AuthUserUpdated({required this.updates});

  @override
  List<Object?> get props => [updates];
}
