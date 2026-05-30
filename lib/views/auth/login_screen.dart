import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../services/smart_db_service.dart';
import '../../services/smart_db_service.dart';
import '../../services/smart_db_service.dart';
import '../../services/smart_db_service.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nniCtrl   = TextEditingController();
  bool _nniVisible = false;
  bool _loading    = false;

  @override
  void dispose() { _nniCtrl.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authStateProvider.notifier).sendOtp(_nniCtrl.text.trim());
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.status == AuthStatus.otpSent) {
      context.push('/otp', extra: _nniCtrl.text.trim());
    } else if (state.status == AuthStatus.error) {
      _showError(state.errorMessage ?? 'Erreur');
      ref.read(authStateProvider.notifier).clearError();
    }
  }

  Future<void> _loginBiometric() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final nni = _nniCtrl.text.trim();
      final resp = await supabase.from('voters')
          .select('id, is_active, account_type')
          .eq('nni', nni).maybeSingle();
      if (!mounted) return;
      if (resp == null) {
        _showError('NNI non trouve. Creez un compte.');
        setState(() => _loading = false);
        return;
      }
      if (resp['is_active'] == false) {
        _showError('Compte inactif.');
        setState(() => _loading = false);
        return;
      }
      await ref.read(authStateProvider.notifier).loginDirect(nni);
      await ref.read(authServiceProvider).saveNni(nni);
      await ref.read(authServiceProvider).saveNni(nni);
      if (!mounted) return;
      context.go('/biometric');
    } catch (e) {
      _showError('Erreur reseau.');
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loading ||
        ref.watch(authStateProvider).status == AuthStatus.loading;
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(children: [
          const SizedBox(height: 48),
          Container(width: 100, height: 100,
            decoration: BoxDecoration(color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 20, offset: const Offset(0, 8))]),
            child: const Icon(Icons.how_to_vote_rounded,
                size: 52, color: Colors.white)),
          const SizedBox(height: 20),
          const Text('MauriVote', style: TextStyle(fontSize: 28,
              fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          const Text('Connexion securisee',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 40),
          Form(key: _formKey, child: Column(children: [
            Align(alignment: Alignment.centerLeft,
              child: Text('Votre NNI', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  color: Colors.grey.shade700))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nniCtrl,
              keyboardType: TextInputType.number,
              maxLength: 10,
              obscureText: !_nniVisible,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Numero National d Identification',
                prefixIcon: const Icon(Icons.badge_outlined),
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(_nniVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _nniVisible = !_nniVisible))),
              validator: (v) {
                if (v == null || v.isEmpty) return 'NNI requis';
                if (v.length != 10) return '10 chiffres requis';
                return null;
              }),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.security_outlined,
                    color: AppTheme.primaryGreen, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Verification par SMS ou empreinte obligatoire',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen))),
              ])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _sendOtp,
              icon: isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sms_outlined),
              label: Text(isLoading ? 'Envoi...' : 'Recevoir le code SMS')),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('ou',
                    style: TextStyle(color: Colors.grey.shade400))),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _loginBiometric,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Empreinte / Face ID'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                minimumSize: const Size(double.infinity, 52))),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => context.push('/register'),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Creer un compte'),
              style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary)),
          ])),
          const SizedBox(height: 40),
          const Text('MauriVote v1.0.0',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }
}
