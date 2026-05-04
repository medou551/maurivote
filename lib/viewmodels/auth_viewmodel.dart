import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<SupabaseAuthService>((_) => SupabaseAuthService.instance);
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
final currentVoterProvider = FutureProvider<Voter?>((ref) => ref.read(authServiceProvider).getCurrentVoter());

enum AuthStatus { idle, loading, otpSent, otpVerified, authenticated, error, blocked }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final Duration? blockRemaining;
  final Voter? voter;
  const AuthState({required this.status, this.errorMessage, this.blockRemaining, this.voter});
  AuthState copyWith({AuthStatus? status, String? errorMessage, Duration? blockRemaining, Voter? voter}) =>
    AuthState(status: status ?? this.status, errorMessage: errorMessage ?? this.errorMessage,
      blockRemaining: blockRemaining ?? this.blockRemaining, voter: voter ?? this.voter);
  factory AuthState.initial() => const AuthState(status: AuthStatus.idle);
}

class AuthNotifier extends Notifier<AuthState> {
  SupabaseAuthService get _auth => ref.read(authServiceProvider);
  @override
  AuthState build() => AuthState.initial();

  Future<void> sendOtp(String nni) async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.sendOtp(nni);
    switch (r) {
      case OtpSendResult.success: state = state.copyWith(status: AuthStatus.otpSent);
      case OtpSendResult.nniNotFound: state = state.copyWith(status: AuthStatus.error, errorMessage: 'NNI non trouve. Contactez la CENI.');
      case OtpSendResult.accountSuspended: state = state.copyWith(status: AuthStatus.error, errorMessage: 'Compte suspendu.');
      case OtpSendResult.rateLimited:
        final rem = await _auth.blockRemainingTime();
        state = state.copyWith(status: AuthStatus.blocked, blockRemaining: rem, errorMessage: 'Trop de tentatives.');
      case OtpSendResult.networkError: state = state.copyWith(status: AuthStatus.error, errorMessage: 'Erreur reseau.');
      case OtpSendResult.error: state = state.copyWith(status: AuthStatus.error, errorMessage: 'Erreur inattendue.');
    }
  }

  Future<void> resendOtp() async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.resendOtp();
    state = state.copyWith(status: r == OtpSendResult.success ? AuthStatus.otpSent : AuthStatus.error,
      errorMessage: r == OtpSendResult.success ? null : 'Impossible de renvoyer.');
  }

  Future<void> verifyOtp(String code) async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.verifyOtp(code);
    switch (r) {
      case OtpVerifyResult.success: state = state.copyWith(status: AuthStatus.otpVerified);
      case OtpVerifyResult.invalid: state = state.copyWith(status: AuthStatus.error, errorMessage: 'Code incorrect.');
      case OtpVerifyResult.expired: state = state.copyWith(status: AuthStatus.error, errorMessage: 'Code expire.');
      case OtpVerifyResult.tooManyAttempts:
        final rem = await _auth.blockRemainingTime();
        state = state.copyWith(status: AuthStatus.blocked, blockRemaining: rem, errorMessage: 'Compte bloque.');
      case OtpVerifyResult.sessionExpired: state = state.copyWith(status: AuthStatus.error, errorMessage: 'Session expiree.');
      default: state = state.copyWith(status: AuthStatus.error, errorMessage: 'Erreur verification.');
    }
  }

  Future<void> authenticateBiometric() async {
    state = state.copyWith(status: AuthStatus.loading);
    final r = await _auth.authenticateBiometric();
    if (r == BiometricResult.success) { await _final(); }
    else { state = state.copyWith(status: AuthStatus.error, errorMessage: 'Biometrie echouee.'); }
  }

  Future<void> completeLogin() => _final();
  Future<void> _final() async {
    final voter = await _auth.getCurrentVoter();
    state = state.copyWith(status: AuthStatus.authenticated, voter: voter);
  }

  Future<void> signOut() async { await _auth.signOut(); state = AuthState.initial(); }
  void clearError() => state = state.copyWith(status: AuthStatus.idle);
}