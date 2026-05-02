import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Écran OTP — Saisie du code SMS à 6 chiffres
class OtpScreen extends ConsumerStatefulWidget {
  final String phone; // numéro masqué ex: +222 XX XX XX 34

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpCtrl      = TextEditingController();
  final _streamCtrl   = StreamController<ErrorAnimationType>();
  late Timer _timer;
  int  _secondsLeft   = AppConstants.otpExpirySeconds; // 120s
  bool _canResend     = false;
  int  _attempts      = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() { _secondsLeft = AppConstants.otpExpirySeconds; _canResend = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpCtrl.dispose();
    _streamCtrl.close();
    super.dispose();
  }

  // ── Formater le compte à rebours mm:ss ───────────────────────────────────
  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Vérifier le code OTP ─────────────────────────────────────────────────
  Future<void> _verifyOtp(String code) async {
    if (code.length < AppConstants.otpLength) return;

    _attempts++;
    if (_attempts > AppConstants.otpMaxAttempts) {
      _showBlockedDialog();
      return;
    }

    await ref.read(authStateProvider.notifier).verifyOtp(code);
    if (!mounted) return;

    final state = ref.read(authStateProvider);

    switch (state.status) {
      case AuthStatus.otpVerified:
        // OTP correct → vérifier si biométrie disponible
        context.go('/biometric');
      case AuthStatus.error:
        // Animation d'erreur sur les champs
        _streamCtrl.add(ErrorAnimationType.shake);
        _otpCtrl.clear();
        _showError(state.errorMessage ?? 'Code incorrect');
        ref.read(authStateProvider.notifier).clearError();
      default:
        break;
    }
  }

  // ── Renvoyer un nouveau code OTP ─────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (!_canResend) return;
    _otpCtrl.clear();
    _attempts = 0;
    // Re-déclencher l'envoi OTP (le NNI est déjà en secure storage)
    await ref.read(authStateProvider.notifier).resendOtp();
    if (!mounted) return;
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nouveau code SMS envoyé'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: AppTheme.errorRed, size: 48),
        title: const Text('Compte temporairement bloqué'),
        content: Text(
          'Trop de tentatives incorrectes.\n'
          'Réessayez dans ${AppConstants.otpBlockDurationMin} minutes.\n\n'
          'Contactez la CENI si le problème persiste :\n'
          '${AppConstants.ceniPhone}',
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.go('/login'); },
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Icône ────────────────────────────────────────────────────
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_outlined,
                    size: 40, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 24),

              // ── Titre ────────────────────────────────────────────────────
              const Text('Vérification SMS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Text(
                'Entrez le code à 6 chiffres envoyé au\n${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 36),

              // ── Champs PIN ───────────────────────────────────────────────
              PinCodeTextField(
                appContext: context,
                length: AppConstants.otpLength,
                controller: _otpCtrl,
                errorAnimationController: _streamCtrl,
                keyboardType: TextInputType.number,
                autoFocus: true,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 56, fieldWidth: 46,
                  activeFillColor: AppTheme.lightGreen.withOpacity(0.2),
                  inactiveFillColor: const Color(0xFFF5F5F5),
                  selectedFillColor: AppTheme.lightGreen.withOpacity(0.3),
                  activeColor: AppTheme.primaryGreen,
                  inactiveColor: Colors.grey.shade300,
                  selectedColor: AppTheme.primaryGreen,
                ),
                enableActiveFill: true,
                onCompleted: (code) => _verifyOtp(code),
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),

              // ── Compte à rebours ──────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _canResend
                  ? TextButton.icon(
                      key: const ValueKey('resend'),
                      onPressed: isLoading ? null : _resendOtp,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Renvoyer un nouveau code'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen),
                    )
                  : Row(
                      key: const ValueKey('timer'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Code valide encore $_timerText',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 28),

              // ── Bouton valider ────────────────────────────────────────────
              ElevatedButton(
                onPressed: isLoading ? null : () => _verifyOtp(_otpCtrl.text),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Valider le code'),
              ),
              const SizedBox(height: 16),

              // ── Indicateur tentatives ─────────────────────────────────────
              if (_attempts > 0)
                Text(
                  '$_attempts / ${AppConstants.otpMaxAttempts} tentatives',
                  style: TextStyle(
                    fontSize: 12,
                    color: _attempts >= 2 ? AppTheme.errorRed : AppTheme.textSecondary,
                  ),
                ),

              const Spacer(),

              // ── Info sécurité ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce code est strictement personnel. '
                      'La CENI ne vous le demandera jamais par téléphone.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
