import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

/// Écran Splash — affiché au démarrage de l'application
/// Logique :
///  1. Animation logo (2 secondes)
///  2. Vérifier si l'onboarding a déjà été fait
///  3. Vérifier si une session est active → accueil ou login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Attendre l'animation + un léger délai supplémentaire
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null && !session.isExpired;

    if (!mounted) return;

    if (!onboardingDone) {
      context.go('/onboarding');
    } else if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo MauriVote ──────────────────────────────────────────
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.how_to_vote,
                      size: 64,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Nom de l'application ────────────────────────────────────
                const Text(
                  'MauriVote',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),

                // ── Sous-titre bilingue ─────────────────────────────────────
                const Text(
                  'Vote Électronique · التصويت الإلكتروني',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ── Ligne décorative ────────────────────────────────────────
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // ── République Islamique de Mauritanie ──────────────────────
                const Text(
                  'République Islamique de Mauritanie',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 60),

                // ── Indicateur de chargement ────────────────────────────────
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
