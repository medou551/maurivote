import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const Color _green = Color(0xFF006233);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _red = Color(0xFFD90012);
  static const Color _dark = Color(0xFF004D26);

  final _ctrl = PageController();
  int _page = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<_PageData> _pages = [
    _PageData(
      icon: Icons.how_to_vote_rounded,
      emoji: '🗳️',
      gradient: [Color(0xFF004D26), Color(0xFF006233)],
      accentColor: Color(0xFFFFD700),
      title: 'Bienvenue sur MauriVote',
      titleAr: 'مرحباً بك في موري فوت',
      subtitle:
          'La plateforme officielle de vote electronique de la Republique Islamique de Mauritanie',
      subtitleAr: 'المنصة الرسمية للتصويت الإلكتروني',
      features: [
        'Vote securise et confidentiel',
        'Resultats en temps reel',
        'Certifie CENI'
      ],
    ),
    _PageData(
      icon: Icons.fingerprint,
      emoji: '🔐',
      gradient: [Color(0xFF1A237E), Color(0xFF283593)],
      accentColor: Color(0xFFFFD700),
      title: 'Securite Maximale',
      titleAr: 'أمان قصوى',
      subtitle:
          'Authentification biometrique et chiffrement AES-256 pour proteger votre vote',
      subtitleAr: 'المصادقة البيومترية وتشفير AES-256',
      features: [
        'Empreinte digitale / Face ID',
        'OTP par SMS',
        'Chiffrement AES-256'
      ],
    ),
    _PageData(
      icon: Icons.bar_chart_rounded,
      emoji: '📊',
      gradient: [Color(0xFF7B1FA2), Color(0xFF8E24AA)],
      accentColor: Color(0xFFFFD700),
      title: 'Resultats Transparents',
      titleAr: 'نتائج شفافة',
      subtitle:
          'Suivez les resultats en direct avec des graphiques clairs et verifiables',
      subtitleAr: 'تابع النتائج مباشرة مع رسوم بيانية واضحة',
      features: [
        'Resultats en temps reel',
        'Graphiques interactifs',
        'Recu de vote QR'
      ],
    ),
    _PageData(
      icon: Icons.verified_user_rounded,
      emoji: '🇲🇷',
      gradient: [Color(0xFF006233), Color(0xFF004D26)],
      accentColor: Color(0xFFFFD700),
      title: 'Commencez a Voter',
      titleAr: 'ابدأ التصويت',
      subtitle:
          'Creez votre compte avec votre NNI et participez a la democratie mauritanienne',
      subtitleAr: 'أنشئ حسابك باستخدام رقم هويتك الوطنية',
      features: ['Inscription rapide', 'Verification CNI', 'Vote en 1 clic'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light));
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: page.gradient,
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

          // Skip button
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicateurs de page
                    Row(
                        children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                width: _page == i ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: _page == i ? _gold : Colors.white38,
                                    borderRadius: BorderRadius.circular(4))))),
                    if (_page < _pages.length - 1)
                      TextButton(
                          onPressed: _finish,
                          child: const Text('Passer',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14))),
                  ])),

          // Contenu principal
          Expanded(
              child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _page = i);
              _animCtrl.reset();
              _animCtrl.forward();
            },
            itemCount: _pages.length,
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          )),

          // Bouton suivant
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(children: [
                GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: _gold.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5))
                            ]),
                        child: Center(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              Text(
                                  _page == _pages.length - 1
                                      ? 'Commencer'
                                      : 'Suivant',
                                  style: const TextStyle(
                                      color: Color(0xFF004D26),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                              const SizedBox(width: 8),
                              Icon(
                                  _page == _pages.length - 1
                                      ? Icons.arrow_forward_rounded
                                      : Icons.chevron_right_rounded,
                                  color: const Color(0xFF004D26),
                                  size: 22),
                            ])))),
                const SizedBox(height: 12),
                if (_page == _pages.length - 1)
                  TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Deja un compte ? Se connecter',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13))),
              ])),

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

  Widget _buildPage(_PageData p) {
    return FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Emoji + Icon
              Stack(alignment: Alignment.center, children: [
                Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _gold.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: _gold.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 5)
                        ]),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 42)),
                          Icon(p.icon,
                              color: Colors.white.withOpacity(0.7), size: 24),
                        ])),
              ]),
              const SizedBox(height: 36),

              // Titre
              Text(p.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(p.titleAr,
                  style: TextStyle(color: _gold.withOpacity(0.8), fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),

              // Sous-titre
              Text(p.subtitle,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),

              // Features
              ...p.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: _gold.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: _gold.withOpacity(0.4))),
                        child: const Icon(Icons.check_rounded,
                            color: _gold, size: 16)),
                    const SizedBox(width: 12),
                    Text(f,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  ]))),
            ])));
  }
}

class _PageData {
  final IconData icon;
  final String emoji;
  final List<Color> gradient;
  final Color accentColor;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final List<String> features;

  const _PageData(
      {required this.icon,
      required this.emoji,
      required this.gradient,
      required this.accentColor,
      required this.title,
      required this.titleAr,
      required this.subtitle,
      required this.subtitleAr,
      required this.features});
}
