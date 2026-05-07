import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try { await dotenv.load(fileName: '.env'); } catch (_) {}

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://xirdgcgjajwkzwbhbimu.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
  );

  await Hive.initFlutter();
  try { await Hive.openBox('elections_cache'); } catch (_) {}
  try { await Hive.openBox('votes_pending'); } catch (_) {}
  try { await Hive.openBox('user_prefs'); } catch (_) {}

  runApp(const ProviderScope(child: MauriVoteApp()));
}

final supabase = Supabase.instance.client;