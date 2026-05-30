import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/local_db_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
  } catch (_) {}

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  assert(
    supabaseUrl.isNotEmpty && !supabaseUrl.contains('REMPLACER'),
    '\n\n⚠️  SUPABASE_URL manquant dans .env\n'
    'Ajoutez votre URL depuis dashboard.supabase.com → Settings → API\n',
  );
  assert(
    supabaseKey.isNotEmpty && !supabaseKey.contains('REMPLACER'),
    '\n\n⚠️  SUPABASE_ANON_KEY manquant dans .env\n'
    'Ajoutez votre clé depuis dashboard.supabase.com → Settings → API\n',
  );

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  await Hive.initFlutter();
  try {
    await Hive.openBox('elections_cache');
  } catch (_) {}
  try {
    await Hive.openBox('votes_pending');
  } catch (_) {}
  try {
    await Hive.openBox('user_prefs');
  } catch (_) {}

  await LocalDbService.db;
  runApp(const ProviderScope(child: MauriVoteApp()));
}

final supabase = Supabase.instance.client;
