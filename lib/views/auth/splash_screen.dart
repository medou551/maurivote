import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/mauritania_flag.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _flagCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _flagOpacity;

  // Couleurs drapeau mauritanien
  static const Color _green = Color(0xFF006233);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _red = Color(0xFFD90012);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _flagCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _logoScale = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _flagOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _flagCtrl, curve: Curves.easeIn));

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _flagCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('onboarded') ?? false;
      final session = Supabase.instance.client.auth.currentSession;
      if (!mounted) return;
      if (!onboarded) {
        context.go('/onboarding');
      } else if (session != null && !session.isExpired) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _flagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF004D26), _green, Color(0xFF007A3D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: SafeArea(
            child: Column(children: [
          // Bande rouge en haut
          AnimatedBuilder(
              animation: _flagCtrl,
              builder: (_, __) => Opacity(
                  opacity: _flagOpacity.value,
                  child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [_red, Color(0xFFFF1A2E), _red]))))),

          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                // Logo animé
                AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, child) => Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                            scale: _logoScale.value, child: child)),
                    child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: _gold, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: _gold.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5),
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8)),
                            ]),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Croissant et étoile mauritaniens
                              const Text('☽',
                                  style: TextStyle(fontSize: 28, color: _gold)),
                              const Text('★',
                                  style: TextStyle(fontSize: 18, color: _gold)),
                              const Icon(Icons.how_to_vote_rounded,
                                  size: 28, color: Colors.white),
                            ]))),

                const SizedBox(height: 32),

                // Texte animé
                AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, child) => Opacity(
                        opacity: _textOpacity.value,
                        child: SlideTransition(
                            position: _textSlide, child: child)),
                    child: Column(children: [
                      const Text('MauriVote',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2))
                              ])),
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                              color: _gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _gold.withOpacity(0.5))),
                          child: const Text(
                              'التصويت الإلكتروني — Vote Électronique',
                              style: TextStyle(
                                  color: _gold,
                                  fontSize: 12,
                                  letterSpacing: 0.5),
                              textAlign: TextAlign.center)),
                      const SizedBox(height: 16),
                      const Text('République Islamique de Mauritanie',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      const Text('الجمهورية الإسلامية الموريتانية',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),

                const SizedBox(height: 60),

                // Loading indicator
                AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, child) =>
                        Opacity(opacity: _textOpacity.value, child: child),
                    child: Column(children: [
                      const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                              color: _gold, strokeWidth: 3)),
                      const SizedBox(height: 16),
                      const Text('Chargement...',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                    ])),
              ])),

          // Bande rouge en bas
          AnimatedBuilder(
              animation: _flagCtrl,
              builder: (_, __) => Opacity(
                  opacity: _flagOpacity.value,
                  child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [_red, Color(0xFFFF1A2E), _red]))))),

          // Footer CENI
          AnimatedBuilder(
              animation: _flagCtrl,
              builder: (_, __) => Opacity(
                  opacity: _flagOpacity.value,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: Colors.white54, size: 14),
                            SizedBox(width: 6),
                            Text(
                                'CENI — Commission Electorale Nationale Independante',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                          ])))),
        ])),
      ),
    );
  }
}
