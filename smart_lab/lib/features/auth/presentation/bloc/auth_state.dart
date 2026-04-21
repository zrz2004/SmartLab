part of 'auth_bloc.dart';

const Object _authCurrentLabSentinel = Object();
const Object _authErrorMessageSentinel = Object();

enum AuthStatus {
  initial,
  checking,
  loading,
  authenticated,
  unauthenticated,
  registrationPending,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final List<LabInfo> accessibleLabs;
  final String? currentLabId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.accessibleLabs = const [],
    this.currentLabId,
    this.errorMessage,
  });

  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;

  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.checking;

  LabInfo? get currentLab {
    if (currentLabId == null) return null;
    try {
      return accessibleLabs.firstWhere((lab) => lab.id == currentLabId);
    } catch (_) {
      return null;
    }
  }

  bool get canControlDevices => user != null && user!.canControlDevices;

  bool get canManageLab => user != null && user!.canManageLab;

  bool get canAcknowledgeAlerts =>
      user != null && user!.canAcknowledgeAlerts;

  bool hasLabAccess(String labId) {
    if (user == null) return false;
    return user!.hasAccessToLab(labId);
  }

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    List<LabInfo>? accessibleLabs,
    Object? currentLabId = _authCurrentLabSentinel,
    Object? errorMessage = _authErrorMessageSentinel,
    bool clearUser = false,
    bool clearCurrentLabId = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      accessibleLabs: accessibleLabs ?? this.accessibleLabs,
      currentLabId: clearCurrentLabId
          ? null
          : identical(currentLabId, _authCurrentLabSentinel)
              ? this.currentLabId
              : currentLabId as String?,
      errorMessage: identical(errorMessage, _authErrorMessageSentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        accessibleLabs,
        currentLabId,
        errorMessage,
      ];
}
