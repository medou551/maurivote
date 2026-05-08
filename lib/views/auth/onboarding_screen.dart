import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = [
    _OnboardingPage(
      icon: Icons.how_to_vote_rounded,
      color: AppTheme.primaryGreen,
      title: 'Bienvenue sur MauriVote',
      titleAr: 'مرحباً بكم في موريفوت',
      desc: 'Votez en toute sécurité depuis votre téléphone où que vous soyez en Mauritanie.',
    ),
    _OnboardingPage(
      icon: Icons.security_outlined,
      color: Color(0xFF1565C0),
      title: 'Vote 100% Sécurisé',
      titleAr: 'تصويت آمن بنسبة 100٪',
      desc: 'Votre vote est chiffré avec AES-256. Personne ne peut savoir pour qui vous avez voté.',
    ),
    _OnboardingPage(
      icon: Icons.fingerprint,
      color: Color(0xFF6A1B9A),
      title: 'Vérification biométrique',
      titleAr: 'التحقق البيومتري',
      desc: 'Authentifiez-vous avec votre NNI, SMS et empreinte digitale pour garantir votre identité.',
    ),
    _OnboardingPage(
      icon: Icons.bar_chart_rounded,
      color: Color(0xFF00695C),
      title: 'Résultats en temps réel',
      titleAr: 'النتائج في الوقت الفعلي',
      desc: 'Suivez les résultats électoraux en direct depuis votre téléphone.',
    ),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [
        // Skip
        Align(alignment: Alignment.topRight,
          child: TextButton(onPressed: _finish,
            child: const Text('Ignorer', style: TextStyle(color: AppTheme.textSecondary)))),

        // Pages
        Expanded(child: PageView.builder(
          controller: _ctrl,
          itemCount: _pages.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => _pages[i],
        )),

        // Indicateurs
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pages.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _page == i ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _page == i ? AppTheme.primaryGreen : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4)),
          ))),
        const SizedBox(height: 24),

        // Boutons
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: _page < _pages.length - 1
            ? ElevatedButton(
                onPressed: () => _ctrl.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
                child: const Text('Suivant'))
            : ElevatedButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Commencer'))),
      ])),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String titleAr;
  final String desc;
  const _OnboardingPage({required this.icon, required this.color,
    required this.title, required this.titleAr, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 120, height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 2)),
        child: Icon(icon, size: 60, color: color)),
      const SizedBox(height: 32),
      Text(titleAr, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 8),
      Text(title, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Text(desc, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6)),
    ]));
  }
}
