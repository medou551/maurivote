import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// SupabaseAuthService — Singleton complet J3
/// NNI → RAVEL → OTP SMS Twilio +222 → JWT → Biométrie → Session timeout
class SupabaseAuthService {
  SupabaseAuthService._internal();
  static final SupabaseAuthService instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => instance;

  final _localAuth = LocalAuthentication();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kJwt           = 'mv_jwt';
  static const _kRefreshToken  = 'mv_refresh';
  static const _kPendingPhone  = 'mv_pending_phone';
  static const _kPendingNni    = 'mv_pending_nni';
  static const _kLastActivity  = 'mv_last_activity';
  static const _kOtpAttempts   = 'mv_otp_attempts';
  static const _kBlockedUntil  = 'mv_blocked_until';

  Timer? _activityTimer;

  // ── Sécurité appareil ────────────────────────────────────────────────────
  Future<bool> isDeviceSecure() async {
    try {
      // En production : ajouter flutter_jailbreak_detection
      return true;
    } catch (_) { return true; }
  }

  // ── ÉTAPE 1 : Envoi OTP ──────────────────────────────────────────────────
  Future<OtpSendResult> sendOtp(String nni) async {
    if (await _isBlocked()) return OtpSendResult.rateLimited;
    try {
      final resp = await supabase
          .from('voters')
          .select('telephone, is_active')
          .eq('nni', nni.trim())
          .maybeSingle();

      if (resp == null) return OtpSendResult.nniNotFound;
      if (resp['is_active'] == false) return OtpSendResult.accountSuspended;

      final phone = resp['telephone'] as String;
      await supabase.auth.signInWithOtp(phone: phone, shouldCreateUser: false);
      await _storage.write(key: _kPendingPhone, value: phone);
      await _storage.write(key: _kPendingNni, value: nni.trim());
      await _resetAttempts();
      debugPrint('OTP → $phone');
      return OtpSendResult.success;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('rate')) return OtpSendResult.rateLimited;
      return OtpSendResult.error;
    } catch (_) { return OtpSendResult.networkError; }
  }

  Future<OtpSendResult> resendOtp() async {
    final nni = await _storage.read(key: _kPendingNni);
    if (nni == null) return OtpSendResult.error;
    return sendOtp(nni);
  }

  // ── ÉTAPE 2 : Vérification OTP ───────────────────────────────────────────
  Future<OtpVerifyResult> verifyOtp(String code) async {
    final phone = await _storage.read(key: _kPendingPhone);
    if (phone == null) return OtpVerifyResult.sessionExpired;

    final attempts = await _incrementAttempts();
    if (attempts > AppConstants.otpMaxAttempts) {
      await _blockAccount();
      return OtpVerifyResult.tooManyAttempts;
    }
    try {
      final r = await supabase.auth.verifyOTP(
          phone: phone, token: code.trim(), type: OtpType.sms);
      if (r.session == null) return OtpVerifyResult.invalid;
      await _storage.write(key: _kJwt, value: r.session!.accessToken);
      await _storage.write(key: _kRefreshToken, value: r.session!.refreshToken ?? '');
      await _touch();
      await _resetAttempts();
      _startTimer();
      return OtpVerifyResult.success;
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('expired')) return OtpVerifyResult.expired;
      return OtpVerifyResult.invalid;
    } catch (_) { return OtpVerifyResult.networkError; }
  }

  // ── Biométrie ─────────────────────────────────────────────────────────────
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (_) { return false; }
  }

  Future<BiometricResult> authenticateBiometric() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Confirmez votre identité pour voter',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok) { await _touch(); return BiometricResult.success; }
      return BiometricResult.failed;
    } catch (_) { return BiometricResult.error; }
  }

  // ── Session ───────────────────────────────────────────────────────────────
  bool get isLoggedIn {
    final s = supabase.auth.currentSession;
    return s != null && !s.isExpired;
  }

  Future<bool> isSessionTimedOut() async {
    final raw = await _storage.read(key: _kLastActivity);
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes >= AppConstants.sessionTimeoutMin;
  }

  Future<void> recordActivity() => _touch();

  Future<void> refreshSessionIfNeeded() async {
    final s = supabase.auth.currentSession;
    if (s == null) return;
    final exp = DateTime.fromMillisecondsSinceEpoch((s.expiresAt ?? 0) * 1000, isUtc: true);
    if (exp.difference(DateTime.now().toUtc()).inMinutes < 5) {
      try { await supabase.auth.refreshSession(); } catch (_) {}
    }
  }

  void _startTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (await isSessionTimedOut()) { await signOut(); }
    });
  }

  Future<void> _touch() async =>
      _storage.write(key: _kLastActivity, value: DateTime.now().toIso8601String());

  // ── Profil ────────────────────────────────────────────────────────────────
  Future<Voter?> getCurrentVoter() async {
    try {
      final nni = await _storage.read(key: _kPendingNni);
      if (nni == null) return null;
      final data = await supabase.from('voters').select().eq('nni', nni).single();
      return Voter.fromJson(data);
    } catch (_) { return null; }
  }

  Future<String?> getCurrentNni() => _storage.read(key: _kPendingNni);

  // ── Déconnexion ───────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _activityTimer?.cancel();
    try { await supabase.auth.signOut(); } catch (_) {}
    await _storage.deleteAll();
  }

  // ── Blocage OTP ───────────────────────────────────────────────────────────
  Future<bool> _isBlocked() async {
    final raw = await _storage.read(key: _kBlockedUntil);
    if (raw == null) return false;
    final until = DateTime.tryParse(raw);
    if (until == null || DateTime.now().isAfter(until)) {
      await _storage.delete(key: _kBlockedUntil);
      return false;
    }
    return true;
  }

  Future<int> _incrementAttempts() async {
    final raw = await _storage.read(key: _kOtpAttempts);
    final n = (int.tryParse(raw ?? '0') ?? 0) + 1;
    await _storage.write(key: _kOtpAttempts, value: n.toString());
    return n;
  }

  Future<void> _resetAttempts() => _storage.delete(key: _kOtpAttempts);

  Future<void> _blockAccount() async {
    final until = DateTime.now().add(Duration(minutes: AppConstants.otpBlockDurationMin));
    await _storage.write(key: _kBlockedUntil, value: until.toIso8601String());
  }

  Future<Duration?> blockRemainingTime() async {
    final raw = await _storage.read(key: _kBlockedUntil);
    if (raw == null) return null;
    final until = DateTime.tryParse(raw);
    if (until == null || DateTime.now().isAfter(until)) return null;
    return until.difference(DateTime.now());
  }
}

enum OtpSendResult { success, nniNotFound, accountSuspended, rateLimited, networkError, error }
enum OtpVerifyResult { success, invalid, expired, sessionExpired, tooManyAttempts, networkError, error }
enum BiometricResult { success, failed, notAvailable, error }
