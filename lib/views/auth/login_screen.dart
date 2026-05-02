import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Écran de connexion — Saisie du NNI mauritanien
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nniCtrl   = TextEditingController();
  bool _nniVisible = false;   // Afficher/masquer le NNI

  @override
  void dispose() {
    _nniCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authStateProvider.notifier).sendOtp(_nniCtrl.text.trim());

    if (!mounted) return;
    final state = ref.read(authStateProvider);

    if (state.status == AuthStatus.otpSent) {
      context.push('/otp', extra: _nniCtrl.text.trim());
    } else if (state.status == AuthStatus.error) {
      _showError(state.errorMessage ?? 'Erreur inconnue');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // ── En-tête ─────────────────────────────────────────────────
              Center(
                child: Column(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.how_to_vote,
                        size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('MauriVote',
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen, fontFamily: 'Cairo',
                      )),
                  const SizedBox(height: 4),
                  const Text('Connexion sécurisée',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ]),
              ),
              const SizedBox(height: 48),

              // ── Formulaire NNI ───────────────────────────────────────────
              const Text('Votre NNI',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text(
                'Numéro National d\'Identification (10 chiffres)',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nniCtrl,
                  obscureText: !_nniVisible,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: AppValidators.validateNni,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••••',
                    hintStyle: const TextStyle(letterSpacing: 6, fontSize: 20),
                    prefixIcon: const Icon(Icons.badge_outlined,
                        color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_nniVisible
                          ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textSecondary),
                      onPressed: () =>
                          setState(() => _nniVisible = !_nniVisible),
                    ),
                    counterText: '', // Masquer le compteur de caractères
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Info sécurité ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.lightGreen),
                ),
                child: const Row(children: [
                  Icon(Icons.shield_outlined,
                      size: 16, color: AppTheme.primaryGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Un code SMS de vérification sera envoyé '
                      'au numéro enregistré à votre NNI',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // ── Bouton de connexion ──────────────────────────────────────
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Recevoir le code SMS'),
              ),
              const SizedBox(height: 24),

              // ── Lien CENI ────────────────────────────────────────────────
              Center(
                child: TextButton.icon(
                  onPressed: () {/* Ouvrir myceni.org */},
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Besoin d\'aide ? Contactez la CENI'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 32),

              // ── Pied de page ─────────────────────────────────────────────
              const Center(
                child: Text(
                  'Commission Électorale Nationale Indépendante\n'
                  'République Islamique de Mauritanie',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
