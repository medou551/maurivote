import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpCtrl = TextEditingController();
  late Timer _timer;
  int _secondsLeft = AppConstants.otpExpirySeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() { _secondsLeft = AppConstants.otpExpirySeconds; _canResend = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) { t.cancel(); if (mounted) setState(() => _canResend = true); }
      else { if (mounted) setState(() => _secondsLeft--); }
    });
  }

  @override
  void dispose() { _timer.cancel(); _otpCtrl.dispose(); super.dispose(); }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Future<void> _verifyOtp(String code) async {
    if (code.length < AppConstants.otpLength) return;
    await ref.read(authStateProvider.notifier).verifyOtp(code);
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.status == AuthStatus.otpVerified) {
      context.go('/biometric');
    } else if (state.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Code incorrect'),
            backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating));
      ref.read(authStateProvider.notifier).clearError();
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    _otpCtrl.clear();
    await ref.read(authStateProvider.notifier).resendOtp();
    if (!mounted) return;
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: AppTheme.primaryGreen,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(width: 80, height: 80,
                decoration: BoxDecoration(color: AppTheme.lightGreen.withOpacity(0.4), shape: BoxShape.circle),
                child: const Icon(Icons.sms_outlined, size: 40, color: AppTheme.primaryGreen)),
              const SizedBox(height: 24),
              const Text('Vérification SMS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Code à 6 chiffres envoyé au\n${widget.phone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 36),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: AppConstants.otpLength,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: const TextStyle(letterSpacing: 12, fontSize: 24, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
                ),
                onChanged: (v) { if (v.length == AppConstants.otpLength) _verifyOtp(v); },
              ),
              const SizedBox(height: 16),
              _canResend
                  ? TextButton.icon(
                      onPressed: isLoading ? null : _resendOtp,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Renvoyer un nouveau code'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen))
                  : Text('Code valide encore $_timerText',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: isLoading ? null : () => _verifyOtp(_otpCtrl.text),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Valider le code'),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text('Ce code est strictement personnel.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}