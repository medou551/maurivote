import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../views/auth/splash_screen.dart';
import '../views/auth/onboarding_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/auth/otp_screen.dart';
import '../views/auth/biometric_screen.dart';
import '../views/home/home_screen.dart';
import '../views/election/election_detail_screen.dart';
import '../views/vote/vote_screen.dart';
import '../views/vote/qr_scanner_screen.dart';
import '../views/vote/vote_receipt_screen.dart';
import '../views/resultats/resultats_screen.dart';
import '../views/profil/profil_screen.dart';
import '../views/profil/bureau_vote_screen.dart' as bvs;
import '../views/admin/admin_dashboard_screen.dart';

class AppRoutes {
  static const splash      = '/';
  static const onboarding  = '/onboarding';
  static const login       = '/login';
  static const register    = '/register';
  static const otp         = '/otp';
  static const biometric   = '/biometric';
  static const home        = '/home';
  static const voteReceipt = '/vote/receipt';
  static const profil      = '/profil';
  static const bureauVote  = '/profil/bureau';
  static const admin       = '/admin';
}

const _storage = FlutterSecureStorage();

Future<bool> _isLoggedIn() async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null && !session.isExpired) return true;
  final nni = await _storage.read(key: 'mv_pending_nni');
  return nni != null && nni.isNotEmpty;
}

Future<bool> _isAdmin() async {
  try {
    final nni = await _storage.read(key: 'mv_pending_nni');
    if (nni == null || nni.isEmpty) return false;
    final resp = await supabase
        .from('voters')
        .select('account_type')
        .eq('nni', nni)
        .maybeSingle();
    return resp?['account_type'] == 'admin';
  } catch (_) { return false; }
}

const _publicRoutes = [
  AppRoutes.splash, AppRoutes.onboarding,
  AppRoutes.login, AppRoutes.register, AppRoutes.otp,
];

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final location = state.matchedLocation;
      if (_publicRoutes.any((r) => location.startsWith(r))) return null;
      final loggedIn = await _isLoggedIn();
      if (!loggedIn) return AppRoutes.login;
      if (location.startsWith(AppRoutes.admin)) {
        final admin = await _isAdmin();
        if (!admin) return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,
          builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login,
          builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,
          builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.otp,
          builder: (_, s) => OtpScreen(phone: s.extra as String? ?? '')),
      GoRoute(path: AppRoutes.biometric,
          builder: (_, __) => const BiometricScreen()),

      // Shell avec bottom nav — Elections + Profil seulement
      ShellRoute(
        builder: (_, __, child) => _HomeShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,
              builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.profil,
              builder: (_, __) => const ProfilScreen()),
        ]),

      GoRoute(path: '/election/:id',
          builder: (_, s) => ElectionDetailScreen(
              electionId: s.pathParameters['id']!)),
      GoRoute(path: '/vote/:electionId',
          builder: (_, s) => VoteScreen(
              electionId: s.pathParameters['electionId']!)),
      GoRoute(path: AppRoutes.voteReceipt,
          builder: (_, s) => VoteReceiptScreen(
              recuHash: (s.extra as Map<String, dynamic>?)?['recuHash'])),
      GoRoute(path: '/resultats',
          builder: (_, __) => const ResultatsScreen()),
      GoRoute(path: '/resultats/:id',
          builder: (_, s) => ResultatsScreen(
              electionId: s.pathParameters['id'])),
      GoRoute(path: AppRoutes.bureauVote,
          builder: (_, __) => const bvs.BureauVoteScreen()),
      GoRoute(path: AppRoutes.admin,
          builder: (_, __) => const AdminDashboardScreen()),
    ]));

class _HomeShell extends StatelessWidget {
  final Widget child;
  const _HomeShell({required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx(context),
      selectedItemColor: const Color(0xFF006233),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.home); break;
          case 1: context.go(AppRoutes.profil); break;
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote_outlined),
            activeIcon: Icon(Icons.how_to_vote),
            label: 'Elections'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Mon Profil'),
      ]));

  int _idx(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).matchedLocation;
    if (loc.startsWith('/profil')) return 1;
    return 0;
  }
}