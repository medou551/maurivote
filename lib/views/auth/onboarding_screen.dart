import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String titleAr;
  final String subtitle;
  final Color color;
  const _OnboardingPage({
    required this.icon, required this.title, required this.titleAr,
    required this.subtitle, required this.color,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.shield_outlined,
    title: 'Vote Sécurisé',
    titleAr: 'تصويت آمن',
    subtitle:
      'Votre vote est chiffré avec AES-256 avant d\'être transmis. '
      'Personne — pas même la CENI — ne peut connaître votre choix.',
    color: Color(0xFF1B5E20),
  ),
  _OnboardingPage(
    icon: Icons.how_to_vote_outlined,
    title: 'Vote Simple',
    titleAr: 'سهولة التصويت',
    subtitle:
      'Connectez-vous avec votre NNI et le code SMS reçu sur votre téléphone. '
      'Votez en quelques secondes depuis n\'importe où en Mauritanie.',
    color: Color(0xFF1565C0),
  ),
  _OnboardingPage(
    icon: Icons.bar_chart_outlined,
    title: 'Résultats en Direct',
    titleAr: 'النتائج المباشرة',
    subtitle:
      'Suivez l\'évolution des résultats en temps réel. '
      'Vérifiez votre reçu de vote avec le QR Code personnel remis après chaque vote.',
    color: Color(0xFF4A148C),
  ),
];

/// Écran d'onboarding — 3 slides de présentation
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _currentPage = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── Bouton passer ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Passer', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),

            // ── Slides ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) => _buildPage(_pages[i]),
              ),
            ),

            // ── Indicateur + bouton ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _ctrl,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: _pages[_currentPage].color,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8, dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color),
                      onPressed: () {
                        if (isLast) {
                          _finish();
                        } else {
                          _ctrl.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(isLast ? 'Commencer' : 'Suivant'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cercle coloré avec icône
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: page.color.withOpacity(0.3), width: 2),
            ),
            child: Icon(page.icon, size: 70, color: page.color),
          ),
          const SizedBox(height: 40),
          // Titre français
          Text(page.title,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                  color: page.color),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          // Titre arabe
          Text(page.titleAr,
              style: TextStyle(fontSize: 18, color: page.color.withOpacity(0.7),
                  fontFamily: 'Cairo'),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Séparateur doré
          Container(width: 50, height: 3,
              decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          // Description
          Text(page.subtitle,
              style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary,
                  height: 1.6),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
