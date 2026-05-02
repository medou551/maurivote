import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<SupabaseAuthService>(
  (_) => SupabaseAuthService.instance,
);
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
final currentVoterProvider = FutureProvider<Voter?>(
  (ref) => ref.read(authServiceProvider).getCurrentVoter(),
);

enum AuthStatus { idle, loading, otpSent, otpVerified, authenticated, error, blocked }

class AuthState {
  final AuthStatus status;
  final String?   errorMessage;
  final Duration? blockRemaining;
  final Voter?    voter;
  const AuthState({required this.status, this.errorMessage, this.blockRemaining, this.voter});
  AuthState copyWith({AuthStatus? status, String? errorMessage, Duration? blockRemaining, Voter? voter}) =>
    AuthState(status: status ?? this.status, errorMessage: errorMessage ?? this.errorMessage,
      blockRemaining: blockRemaining ?? this.blockRemaining, voter: voter ?? this.voter);
  factory AuthState.initial() => const AuthState(status: AuthStatus.idle);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _auth;
  AuthNotifier(this._auth) : super(AuthState.initial());

  Future<void> sendOtp(String nni) async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.sendOtp(nni);
    switch (r) {
      case OtpSendResult.success:
        state = state.copyWith(status: AuthStatus.otpSent);
      case OtpSendResult.nniNotFound:
        state = state.copyWith(status: AuthStatus.error,
          errorMessage: 'NNI non trouvé dans la base électorale.\nContactez la CENI : +222 45 25 25 25');
      case OtpSendResult.accountSuspended:
        state = state.copyWith(status: AuthStatus.error,
          errorMessage: 'Compte électoral suspendu. Contactez la CENI.');
      case OtpSendResult.rateLimited:
        final rem = await _auth.blockRemainingTime();
        state = state.copyWith(status: AuthStatus.blocked, blockRemaining: rem,
          errorMessage: 'Trop de tentatives. Réessayez dans ${rem?.inMinutes ?? 30} min.');
      case OtpSendResult.networkError:
        state = state.copyWith(status: AuthStatus.error,
          errorMessage: 'Erreur réseau. Vérifiez votre connexion.');
      case OtpSendResult.error:
        state = state.copyWith(status: AuthStatus.error,
          errorMessage: 'Erreur inattendue. Réessayez.');
    }
  }

  Future<void> resendOtp() async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.resendOtp();
    state = state.copyWith(status: r == OtpSendResult.success
      ? AuthStatus.otpSent : AuthStatus.error,
      errorMessage: r == OtpSendResult.success ? null : 'Impossible de renvoyer le code.');
  }

  Future<void> verifyOtp(String code) async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.verifyOtp(code);
    switch (r) {
      case OtpVerifyResult.success:
        state = state.copyWith(status: AuthStatus.otpVerified);
      case OtpVerifyResult.invalid:
        state = state.copyWith(status: AuthStatus.error, errorMessage: 'Code incorrect.');
      case OtpVerifyResult.expired:
        state = state.copyWith(status: AuthStatus.error, errorMessage: 'Code expiré. Demandez un nouveau code.');
      case OtpVerifyResult.tooManyAttempts:
        final rem = await _auth.blockRemainingTime();
        state = state.copyWith(status: AuthStatus.blocked, blockRemaining: rem,
          errorMessage: 'Compte bloqué ${rem != null ? "${rem.inMinutes} min" : "30 min"}.');
      case OtpVerifyResult.sessionExpired:
        state = state.copyWith(status: AuthStatus.error, errorMessage: 'Session expirée. Recommencez.');
      default:
        state = state.copyWith(status: AuthStatus.error, errorMessage: 'Erreur de vérification.');
    }
  }

  Future<void> authenticateBiometric() async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.authenticateBiometric();
    if (r == BiometricResult.success) {
      await _finalizeLogin();
    } else {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Biométrie échouée.');
    }
  }

  Future<void> completeLogin() => _finalizeLogin();

  Future<void> _finalizeLogin() async {
    final voter = await _auth.getCurrentVoter();
    state = state.copyWith(status: AuthStatus.authenticated, voter: voter);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = AuthState.initial();
  }

  void clearError() => state = state.copyWith(status: AuthStatus.idle);
}
