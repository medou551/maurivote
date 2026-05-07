import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nniCtrl    = TextEditingController();
  final _nomCtrl    = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _dateCtrl   = TextEditingController();
  String  _sexe     = 'M';
  bool    _loading  = false;
  String? _error;

  @override
  void dispose() {
    _nniCtrl.dispose(); _nomCtrl.dispose();
    _prenomCtrl.dispose(); _telCtrl.dispose(); _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final sb = Supabase.instance.client;
      final existing = await sb
          .from('voters')
          .select('id')
          .eq('nni', _nniCtrl.text.trim())
          .maybeSingle();
      if (existing != null) {
        setState(() {
          _error = 'Ce NNI est deja enregistre.';
          _loading = false;
        });
        return;
      }
      final commune = await sb
          .from('communes')
          .select('id, wilaya_id')
          .limit(1)
          .single();
      await sb.from('voters').insert({
        'nni'            : _nniCtrl.text.trim(),
        'nom'            : _nomCtrl.text.trim().toUpperCase(),
        'prenom'         : _prenomCtrl.text.trim(),
        'date_naissance' : _dateCtrl.text.trim(),
        'sexe'           : _sexe,
        'commune_id'     : commune['id'],
        'wilaya_id'      : commune['wilaya_id'],
        'telephone'      : '+222' + _telCtrl.text.trim(),
        'is_verified'    : false,
        'is_active'      : true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte cree ! Connectez-vous avec votre NNI.'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } catch (e) {
      setState(() {
        _error   = 'Erreur. Reessayez.';
        _loading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) {
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() => _dateCtrl.text = '${picked.year}-$m-$d');
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 12),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Creer un compte'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_outlined,
                        size: 40, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 12),
                  const Text('Creer un compte',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ])),
                _label('NNI (10 chiffres)'),
                TextFormField(
                  controller: _nniCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '1234567890',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                  validator: (v) =>
                      v == null || v.length != 10 ? 'NNI invalide' : null,
                ),
                _label('Nom'),
                TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nom de famille',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nom requis' : null,
                ),
                _label('Prenom'),
                TextFormField(
                  controller: _prenomCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Prenom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Prenom requis' : null,
                ),
                _label('Date de naissance'),
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    hintText: 'Selectionner',
                    prefixIcon: Icon(Icons.cake_outlined),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Date requise' : null,
                ),
                _label('Sexe'),
                Row(children: [
                  Expanded(child: RadioListTile<String>(
                    title: const Text('Masculin'),
                    value: 'M',
                    groupValue: _sexe,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => setState(() => _sexe = v!),
                  )),
                  Expanded(child: RadioListTile<String>(
                    title: const Text('Feminin'),
                    value: 'F',
                    groupValue: _sexe,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => setState(() => _sexe = v!),
                  )),
                ]),
                _label('Telephone'),
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '20001234',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+222 ',
                    counterText: '',
                  ),
                  validator: (v) =>
                      v == null || v.length < 7 ? 'Numero invalide' : null,
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.errorRed.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.errorRed))),
                    ]),
                  ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _register,
                  icon: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add),
                  label: Text(
                      _loading ? 'Creation...' : 'Creer mon compte'),
                ),
                const SizedBox(height: 12),
                Center(child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Deja un compte ? Se connecter',
                    style: TextStyle(color: AppTheme.primaryGreen),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
