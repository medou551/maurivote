import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Écran Biométrie — Proposer / valider l'empreinte ou Face ID
class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  bool _biometricAvailable = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final auth = ref.read(authServiceProvider);
    final available = await auth.isBiometricAvailable();
    if (mounted) setState(() { _biometricAvailable = available; _isChecking = false; });
    // Si biométrie disponible, lancer directement
    if (available) _authenticate();
  }

  Future<void> _authenticate() async {
    await ref.read(authStateProvider.notifier).authenticateBiometric();
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.status == AuthStatus.authenticated) {
      context.go('/home');
    }
  }

  Future<void> _skipBiometric() async {
    // Continuer sans biométrie
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefBiometricEnabled, false);
    await ref.read(authStateProvider.notifier).completeLogin();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _isChecking
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Illustration ──────────────────────────────────────
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _biometricAvailable
                            ? Icons.fingerprint
                            : Icons.no_encryption_outlined,
                        size: 64,
                        color: _biometricAvailable
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      _biometricAvailable
                          ? 'Authentification biométrique'
                          : 'Biométrie non disponible',
                      style: const TextStyle(fontSize: 22,
                          fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _biometricAvailable
                          ? 'Posez votre doigt sur le capteur ou regardez la caméra pour confirmer votre identité'
                          : 'Votre appareil ne supporte pas la biométrie. Vous pouvez continuer sans.',
                      style: const TextStyle(fontSize: 14,
                          color: AppTheme.textSecondary, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    if (authState.status == AuthStatus.error)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.warning_amber_outlined,
                              color: AppTheme.errorRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            authState.errorMessage ?? 'Échec de l\'authentification',
                            style: const TextStyle(
                                color: AppTheme.errorRed, fontSize: 13),
                          )),
                        ]),
                      ),

                    if (_biometricAvailable)
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _authenticate,
                        icon: isLoading
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.fingerprint),
                        label: const Text('Valider avec la biométrie'),
                      ),

                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: isLoading ? null : _skipBiometric,
                      child: Text(_biometricAvailable
                          ? 'Continuer sans biométrie'
                          : 'Continuer'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
