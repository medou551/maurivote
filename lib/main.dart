import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Charger les variables d'environnement ──────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── 2. Forcer le mode portrait ────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── 3. Initialiser Supabase ───────────────────────────────────────────────
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // ── 4. Initialiser Hive (stockage local offline) ──────────────────────────
  await Hive.initFlutter();
  await Hive.openBox('elections_cache');
  await Hive.openBox('votes_pending');
  await Hive.openBox('user_prefs');

  // ── 5. Initialiser Firebase ───────────────────────────────────────────────
  await Firebase.initializeApp();

  // ── 6. Initialiser les notifications ─────────────────────────────────────
  await NotificationService.initialize();

  // ── 7. Lancer l'application ───────────────────────────────────────────────
  runApp(
    // ProviderScope encapsule toute l'app pour Riverpod
    const ProviderScope(
      child: MauriVoteApp(),
    ),
  );
}

/// Raccourci global pour accéder au client Supabase depuis n'importe où
final supabase = Supabase.instance.client;
