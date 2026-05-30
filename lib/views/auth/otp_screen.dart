import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF006233);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _red = Color(0xFFD90012);
  static const Color _dark = Color(0xFF004D26);

  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _seconds = 120;
  bool _canResend = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
    _startTimer();
    // Focus premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 120;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        setState(() => _canResend = true);
        t.cancel();
      }
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  String get _timerStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez le code a 6 chiffres'), backgroundColor: Color(0xFFB71C1C), behavior: SnackBarBehavior.floating));
      return;
    }
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    await ref.read(authStateProvider.notifier).verifyOtp(_otp);
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.status == AuthStatus.otpVerified ||
        state.status == AuthStatus.authenticated) {
      HapticFeedback.heavyImpact();
      context.go('/biometric');
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Code invalide'), backgroundColor: const Color(0xFFB71C1C), behavior: SnackBarBehavior.floating));
      // Vider les cases
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
      ref.read(authStateProvider.notifier).clearError();
    }
  }

  Future<void> _resend() async {
    HapticFeedback.lightImpact();
    await ref.read(authStateProvider.notifier).resendOtp();
    if (!mounted) return;
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code renvoye !'), backgroundColor: Color(0xFF006233), behavior: SnackBarBehavior.floating));
  }

  void _onChanged(String val, int idx) {
    if (val.length == 1 && idx < 5) {
      _nodes[idx + 1].requestFocus();
    }
    if (val.isEmpty && idx > 0) {
      _nodes[idx - 1].requestFocus();
    }
    // Auto-verify si 6 chiffres
    if (_otp.length == 6) {
      Future.delayed(const Duration(milliseconds: 200), _verify);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).status == AuthStatus.loading;
    final phone = widget.phone;
    final maskedPhone = phone.length > 4
        ? '+222 ****${phone.substring(phone.length - 4)}'
        : '+222 $phone';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF004D26), Color(0xFF006233)],
                begin: Alignment.topCenter,
                end: Alignment.center)),
        child: SafeArea(
            child: Column(children: [
          // Bande rouge
          Container(
              height: 5,
              decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_red, Color(0xFFFF1A2E), _red]))),

          // Header
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(children: [
                GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 18))),
                const SizedBox(width: 12),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verification SMS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Code a 6 chiffres',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
              ])),

          // Contenu
          Expanded(
            child: Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32))),
                child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: Column(children: [
                          // Icone SMS
                          Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                  color: _green.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _green.withOpacity(0.2),
                                      width: 2)),
                              child: const Icon(Icons.sms_outlined,
                                  color: _green, size: 36)),
                          const SizedBox(height: 20),

                          const Text('Code envoyé !',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          RichText(
                              text: TextSpan(
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                  children: [
                                const TextSpan(
                                    text:
                                        'Un code a 6 chiffres a ete envoye au '),
                                TextSpan(
                                    text: maskedPhone,
                                    style: const TextStyle(
                                        color: _green,
                                        fontWeight: FontWeight.bold)),
                              ])),
                          const SizedBox(height: 32),

                          // Cases OTP
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (i) {
                                final hasValue = _ctrls[i].text.isNotEmpty;
                                return SizedBox(
                                    width: 44,
                                    child: TextFormField(
                                      controller: _ctrls[i],
                                      focusNode: _nodes[i],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      obscureText: true,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: _dark),
                                      decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: hasValue
                                              ? _green.withOpacity(0.08)
                                              : Colors.grey.shade50,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: hasValue
                                                      ? _green
                                                      : Colors.grey.shade300,
                                                  width: hasValue ? 2 : 1)),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: hasValue
                                                      ? _green
                                                      : Colors.grey.shade300,
                                                  width: hasValue ? 2 : 1)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color: _green, width: 2)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 14)),
                                      onChanged: (v) => _onChanged(v, i),
                                    ));
                              })),
                          const SizedBox(height: 28),

                          // Timer
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                  color: _canResend
                                      ? Colors.orange.shade50
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _canResend
                                          ? Colors.orange.shade200
                                          : Colors.grey.shade200)),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        _canResend
                                            ? Icons.timer_off
                                            : Icons.timer_outlined,
                                        size: 18,
                                        color: _canResend
                                            ? Colors.orange
                                            : Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                        _canResend
                                            ? 'Code expire — Renvoyer'
                                            : 'Expire dans $_timerStr',
                                        style: TextStyle(
                                            color: _canResend
                                                ? Colors.orange
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold)),
                                  ])),
                          const SizedBox(height: 24),

                          // Bouton vérifier
                          Container(
                              decoration: BoxDecoration(
                                  gradient: _otp.length == 6
                                      ? const LinearGradient(colors: [
                                          Color(0xFF004D26),
                                          Color(0xFF006233)
                                        ])
                                      : null,
                                  color: _otp.length != 6
                                      ? Colors.grey.shade300
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _otp.length == 6
                                      ? [
                                          BoxShadow(
                                              color: _green.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4))
                                        ]
                                      : null),
                              child: ElevatedButton.icon(
                                  onPressed: (_otp.length == 6 && !isLoading)
                                      ? _verify
                                      : null,
                                  icon: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.check_circle_outlined),
                                  label: Text(isLoading
                                      ? 'Verification...'
                                      : 'Verifier le code'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      minimumSize:
                                          const Size(double.infinity, 52),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14))))),
                          const SizedBox(height: 16),

                          // Renvoyer
                          if (_canResend)
                            OutlinedButton.icon(
                                onPressed: _resend,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Renvoyer le code'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: _green,
                                    side: const BorderSide(color: _green),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)))),

                          const SizedBox(height: 20),

                          // Info sécurité
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: _gold.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: _gold.withOpacity(0.3))),
                              child: const Row(children: [
                                Icon(Icons.lock_outlined,
                                    color: _gold, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        'Ce code est valable 2 minutes. Ne le partagez jamais.',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey))),
                              ])),
                        ])))),
          ),

          // Bande rouge bas
          Container(
              height: 5,
              decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_red, Color(0xFFFF1A2E), _red]))),
        ])),
      ),
    );
  }
}
