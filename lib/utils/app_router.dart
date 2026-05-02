import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/auth/splash_screen.dart';
import '../views/auth/onboarding_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/otp_screen.dart';
import '../views/auth/biometric_screen.dart';
import '../views/home/home_screen.dart';
import '../views/election/election_detail_screen.dart';
import '../views/vote/vote_screen.dart';
import '../views/vote/vote_receipt_screen.dart';
import '../views/resultats/resultats_screen.dart';
import '../views/profil/profil_screen.dart';
import '../views/admin/admin_dashboard_screen.dart';

class AppRoutes {
  static const splash         = '/';
  static const onboarding     = '/onboarding';
  static const login          = '/login';
  static const otp            = '/otp';
  static const biometric      = '/biometric';
  static const home           = '/home';
  static const voteReceipt    = '/vote/receipt';
  static const profil         = '/profil';
  static const bureauVote     = '/profil/bureau';
  static const admin          = '/admin';
}

final appRouterProvider = Provider<GoRouter>((ref) => GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  redirect: (_, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null && !session.isExpired;
    final authRoutes = [AppRoutes.splash, AppRoutes.onboarding,
        AppRoutes.login, AppRoutes.otp, AppRoutes.biometric];
    final onAuth = authRoutes.contains(state.matchedLocation);
    if (!loggedIn && !onAuth) return AppRoutes.login;
    if (loggedIn && onAuth && state.matchedLocation != AppRoutes.splash) return AppRoutes.home;
    return null;
  },
  routes: [
    GoRoute(path: AppRoutes.splash,     builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.login,      builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.otp,        builder: (_, s) => OtpScreen(phone: s.extra as String? ?? '')),
    GoRoute(path: AppRoutes.biometric,  builder: (_, __) => const BiometricScreen()),
    ShellRoute(
      builder: (_, __, child) => _HomeShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.home,   builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/resultats',     builder: (_, __) => const ResultatsScreen(electionId: null)),
        GoRoute(path: AppRoutes.profil, builder: (_, __) => const ProfilScreen()),
      ],
    ),
    GoRoute(path: '/election/:id',
        builder: (_, s) => ElectionDetailScreen(electionId: s.pathParameters['id']!)),
    GoRoute(path: '/vote/:electionId',
        builder: (_, s) => VoteScreen(electionId: s.pathParameters['electionId']!)),
    GoRoute(path: AppRoutes.voteReceipt,
        builder: (_, s) => VoteReceiptScreen(
          recuHash: (s.extra as Map<String, dynamic>?)?['recuHash'])),
    GoRoute(path: '/resultats/:id',
        builder: (_, s) => ResultatsScreen(electionId: s.pathParameters['id'])),
    GoRoute(path: AppRoutes.bureauVote, builder: (_, __) => const BureauVoteScreen()),
    GoRoute(path: AppRoutes.admin,
        redirect: (_, __) {
          final u = Supabase.instance.client.auth.currentUser;
          return u?.appMetadata['role'] == 'ceni_admin' ? null : AppRoutes.home;
        },
        builder: (_, __) => const AdminDashboardScreen()),
  ],
));

class _HomeShell extends StatelessWidget {
  final Widget child;
  const _HomeShell({required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx(context),
      onTap: (i) { switch(i) {
        case 0: context.go(AppRoutes.home); break;
        case 1: context.go('/resultats'); break;
        case 2: context.go(AppRoutes.profil); break;
      }},
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.how_to_vote_outlined),
            activeIcon: Icon(Icons.how_to_vote), label: 'Élections'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart), label: 'Résultats'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person), label: 'Profil'),
      ],
    ),
  );

  int _idx(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).matchedLocation;
    if (loc.startsWith('/resultats')) return 1;
    if (loc.startsWith('/profil')) return 2;
    return 0;
  }
}
