import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class SupabaseAuthService {
  static final SupabaseAuthService instance = SupabaseAuthService._();
  SupabaseAuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static const _kPendingNni   = 'mv_pending_nni';
  static const _kPendingPhone = 'mv_pending_phone';
  static const _kLastActivity = 'mv_last_activity';
  static const _kAttempts     = 'mv_attempts';
  static const _kBlockedUntil = 'mv_blocked_until';

  final _localAuth = LocalAuthentication();

  // â”€â”€ OTP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<OtpSendResult> sendOtp(String nni) async {
    try {
      final resp = await supabase.from('voters')
          .select('telephone, is_active')
          .eq('nni', nni.trim()).maybeSingle();
      if (resp == null) return OtpSendResult.nniNotFound;
      if (resp['is_active'] == false) return OtpSendResult.accountSuspended;
      final phone = resp['telephone'] as String;
      await supabase.auth.signInWithOtp(phone: phone, shouldCreateUser: true);
      await _storage.write(key: _kPendingPhone, value: phone);
      await _storage.write(key: _kPendingNni, value: nni.trim());
      debugPrint('OTP envoye');
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
      await _resetAttempts();
      await _touch();
      await _storage.write(key: _kPendingNni,
          value: await _storage.read(key: _kPendingNni) ?? '');
      return OtpVerifyResult.success;
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('expired')) return OtpVerifyResult.expired;
      return OtpVerifyResult.invalid;
    } catch (_) { return OtpVerifyResult.networkError; }
  }

  // â”€â”€ Biometrie â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<BiometricResult> authenticateBiometric() async {
    try {
      final avail = await _localAuth.canCheckBiometrics;
      if (!avail) return BiometricResult.notAvailable;
      final ok = await _localAuth.authenticate(
        localizedReason: 'Confirmez votre identite pour voter');
      if (ok) { await _touch(); return BiometricResult.success; }
      return BiometricResult.failed;
    } catch (_) { return BiometricResult.error; }
  }

  // â”€â”€ NNI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> saveNni(String nni) async {
    await _storage.write(key: _kPendingNni, value: nni);
  }

  Future<String?> getCurrentNni() async {
    return _storage.read(key: _kPendingNni);
  }

  // â”€â”€ Voter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<Voter?> getCurrentVoter() async {
    try {
      final nni = await getCurrentNni();
      if (nni == null || nni.isEmpty) return null;
      final data = await supabase.from('voters')
          .select('*').eq('nni', nni).maybeSingle();
      if (data == null) return null;
      return Voter.fromJson(Map<String, dynamic>.from(data));
    } catch (_) { return null; }
  }

  // â”€â”€ Session â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool get isLoggedIn {
    final s = supabase.auth.currentSession;
    return s != null && !s.isExpired;
  }

  Future<void> _touch() async {
    await _storage.write(
      key: _kLastActivity,
      value: DateTime.now().toIso8601String());
  }

  Future<bool> isSessionTimedOut() async {
    final raw = await _storage.read(key: _kLastActivity);
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes >= AppConstants.sessionTimeoutMinutes;
  }

  Future<void> signOut() async {
    await _storage.deleteAll();
    try { await supabase.auth.signOut(); } catch (_) {}
  }

  // â”€â”€ Rate limiting â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<int> _incrementAttempts() async {
    final raw = await _storage.read(key: _kAttempts);
    final n = (int.tryParse(raw ?? '0') ?? 0) + 1;
    await _storage.write(key: _kAttempts, value: n.toString());
    return n;
  }

  Future<void> _resetAttempts() async {
    await _storage.delete(key: _kAttempts);
  }

  Future<void> _blockAccount() async {
    final until = DateTime.now().add(const Duration(minutes: 30));
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
