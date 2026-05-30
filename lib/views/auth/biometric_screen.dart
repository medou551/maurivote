import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../main.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});
  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen>
    with TickerProviderStateMixin {
  static const Color _green = Color(0xFF006233);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _red = Color(0xFFD90012);
  static const Color _dark = Color(0xFF004D26);

  bool _checking = true;
  bool _available = false;
  bool _failed = false;
  bool _navigated = false;
  int _attempts = 0;
  String _errorMsg = '';
  List<BiometricType> _types = [];
  static const int _maxAttempts = 5;

  late AnimationController _pulseCtrl;
  late AnimationController _shakeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shakeAnim = Tween<double>(begin: 0, end: 8)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _check();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final auth = LocalAuthentication();
      final avail =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      final types =
          avail ? await auth.getAvailableBiometrics() : <BiometricType>[];
      if (mounted) {
        setState(() {
          _available = avail;
          _types = types;
          _checking = false;
        });
        _authenticate();
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _available = false;
          _checking = false;
        });
    }
  }

  Future<void> _authenticate() async {
    if (_navigated || _attempts >= _maxAttempts) return;
    setState(() {
      _failed = false;
      _errorMsg = '';
    });
    try {
      final auth = LocalAuthentication();
      final ok = await auth.authenticate(
        localizedReason: 'Confirmez votre identite pour acceder a MauriVote',
      );
      if (!mounted || _navigated) return;
      if (ok) {
        _navigated = true;
        HapticFeedback.heavyImpact();
        await ref.read(authStateProvider.notifier).completeLogin();
        if (!mounted) return;
        // Vérifier si admin
        final nni = await ref.read(authStateProvider.notifier).getCurrentNni();
        if (!mounted) return;
        if (nni != null) {
          try {
            final resp = await supabase
                .from('voters')
                .select('account_type')
                .eq('nni', nni)
                .maybeSingle();
            final isAdmin = resp?['account_type'] == 'admin';
            if (mounted) context.go(isAdmin ? '/admin' : '/home');
          } catch (_) {
            if (mounted) context.go('/home');
          }
        } else {
          context.go('/home');
        }
      } else {
        HapticFeedback.vibrate();
        _shakeCtrl.forward(from: 0);
        setState(() {
          _attempts++;
          _failed = true;
          _errorMsg =
              'Echec. ${_maxAttempts - _attempts} tentative(s) restante(s).';
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _attempts++;
        _failed = true;
        _errorMsg = 'Erreur biometrie. Reessayez.';
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  String get _label {
    if (_types.contains(BiometricType.face)) return 'Face ID';
    if (_types.contains(BiometricType.fingerprint)) return 'Empreinte digitale';
    return 'Biometrie';
  }

  IconData get _icon {
    if (_types.contains(BiometricType.face))
      return Icons.face_retouching_natural;
    return Icons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _attempts >= _maxAttempts;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF004D26), Color(0xFF006233)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: SafeArea(
            child: Column(children: [
          // Bande rouge haut
          Container(
              height: 5,
              decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_red, Color(0xFFFF1A2E), _red]))),

          // Header
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold, width: 1.5)),
                    child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('☽',
                              style: TextStyle(fontSize: 12, color: _gold)),
                          Icon(Icons.how_to_vote_rounded,
                              size: 14, color: Colors.white),
                        ])),
                const SizedBox(width: 12),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MauriVote',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Verification requise',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
              ])),

          // Contenu principal
          Expanded(
              child: _checking
                  ? const Center(child: CircularProgressIndicator(color: _gold))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          // Icone biométrique animée
                          if (!blocked)
                            GestureDetector(
                                onTap: _authenticate,
                                child: AnimatedBuilder(
                                    animation: Listenable.merge(
                                        [_pulseCtrl, _shakeCtrl]),
                                    builder: (_, child) => Transform.translate(
                                        offset: Offset(
                                            _failed
                                                ? _shakeAnim.value *
                                                    ((_attempts % 2 == 0)
                                                        ? 1
                                                        : -1)
                                                : 0,
                                            0),
                                        child: ScaleTransition(
                                            scale: _failed
                                                ? const AlwaysStoppedAnimation(
                                                    1.0)
                                                : _pulseAnim,
                                            child: child)),
                                    child: Container(
                                        width: 160,
                                        height: 160,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _failed
                                                ? Colors.red.withOpacity(0.15)
                                                : Colors.white
                                                    .withOpacity(0.12),
                                            border: Border.all(
                                                color: _failed
                                                    ? Colors.red
                                                    : _gold,
                                                width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: (_failed
                                                          ? Colors.red
                                                          : _gold)
                                                      .withOpacity(0.3),
                                                  blurRadius: 30,
                                                  spreadRadius: 5)
                                            ]),
                                        child: Icon(_icon,
                                            size: 80,
                                            color: _failed
                                                ? Colors.red
                                                : Colors.white)))),

                          if (blocked)
                            Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.15),
                                    border: Border.all(
                                        color: Colors.red, width: 3)),
                                child: const Icon(Icons.block,
                                    size: 60, color: Colors.red)),

                          const SizedBox(height: 24),

                          // Label
                          if (!blocked)
                            Text(_label,
                                style: TextStyle(
                                    color:
                                        _failed ? Colors.red.shade300 : _gold,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          if (blocked)
                            const Text('Trop de tentatives',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),

                          const SizedBox(height: 8),
                          Text(
                              blocked
                                  ? 'Vous avez depasse le nombre de tentatives'
                                  : _failed
                                      ? _errorMsg
                                      : 'Appuyez sur l\'icone pour vous identifier',
                              style: TextStyle(
                                  color: _failed || blocked
                                      ? Colors.red.shade300
                                      : Colors.white70,
                                  fontSize: 13),
                              textAlign: TextAlign.center),

                          const SizedBox(height: 32),

                          // Erreur
                          if (_failed && !blocked) ...[
                            Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.3))),
                                child: Row(children: [
                                  const Icon(Icons.warning_amber_outlined,
                                      color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(_errorMsg,
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12))),
                                ])),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                                onPressed: _authenticate,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reessayer'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: _gold,
                                    foregroundColor: _dark,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)))),
                          ],
                        ])),

          // Déconnexion
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                  label: Text(
                      blocked
                          ? 'Trop de tentatives — Se deconnecter'
                          : 'Se deconnecter',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12)))),

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
