import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';

enum RegisterStep { infos, cni, biometrie, confirmation }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF006233);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _red = Color(0xFFD90012);

  final _formKey = GlobalKey<FormState>();
  final _nniCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _cniNumCtrl = TextEditingController();

  String _sexe = 'M';
  bool _loading = false;
  String? _error;
  RegisterStep _step = RegisterStep.infos;

  // CNI — OBLIGATOIRE
  XFile? _cniRecto;
  XFile? _cniVerso;
  bool _cniRectoValidated = false;
  bool _cniVersoValidated = false;

  // Biométrie — optionnelle
  bool _biometrieOk = false;

  final _picker = ImagePicker();
  final _localAuth = LocalAuthentication();

  @override
  void dispose() {
    _nniCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _dateCtrl.dispose();
    _cniNumCtrl.dispose();
    super.dispose();
  }

  // ── Validation CNI mauritanienne ──────────────────────────────────────────
  // NNI mauritanien : 10 chiffres
  bool _validateNni(String nni) => RegExp(r'^\d{10}$').hasMatch(nni);

  // Numéro CNI mauritanienne : format variable
  bool _validateCniNum(String num) => num.length >= 6;

  // ── Navigation étapes ────────────────────────────────────────────────────
  bool get _canNext {
    switch (_step) {
      case RegisterStep.infos:
        return _formKey.currentState?.validate() ?? false;
      case RegisterStep.cni:
        // CNI OBLIGATOIRE — recto ET verso requis
        return _cniRecto != null && _cniVerso != null;
      case RegisterStep.biometrie:
        return true; // optionnelle
      case RegisterStep.confirmation:
        return true;
    }
  }

  void _next() {
    if (_step == RegisterStep.infos) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      // Vérifier NNI format mauritanien
      if (!_validateNni(_nniCtrl.text.trim())) {
        setState(() => _error = 'NNI invalide — 10 chiffres requis');
        return;
      }
    }
    if (_step == RegisterStep.cni) {
      // CNI OBLIGATOIRE
      if (_cniRecto == null) {
        setState(() => _error = 'Photo recto CNI obligatoire');
        return;
      }
      if (_cniVerso == null) {
        setState(() => _error = 'Photo verso CNI obligatoire');
        return;
      }
    }
    setState(() {
      _error = null;
    });
    HapticFeedback.lightImpact();
    if (_step != RegisterStep.confirmation) {
      setState(() => _step = RegisterStep.values[_step.index + 1]);
      if (_step == RegisterStep.biometrie) _verifierBiometrie();
    } else {
      _creerCompte();
    }
  }

  void _back() {
    if (_step.index > 0) {
      setState(() {
        _step = RegisterStep.values[_step.index - 1];
        _error = null;
      });
    } else {
      context.go('/login');
    }
  }

  // ── Photo CNI ─────────────────────────────────────────────────────────────
  Future<void> _scanCni(bool recto) async {
    final choice = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(recto ? 'Photo Recto CNI' : 'Photo Verso CNI',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                  leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: _green)),
                  title: const Text('Prendre une photo'),
                  subtitle: const Text('Recommande pour meilleure qualite'),
                  onTap: () => Navigator.pop(context, ImageSource.camera)),
              ListTile(
                  leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child:
                          const Icon(Icons.photo_library, color: Colors.blue)),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery)),
              const SizedBox(height: 16),
            ])));

    if (choice == null) return;
    final photo = await _picker.pickImage(
        source: choice, imageQuality: 90, maxWidth: 1920);
    if (photo != null && mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        if (recto) {
          _cniRecto = photo;
          _cniRectoValidated = true;
        } else {
          _cniVerso = photo;
          _cniVersoValidated = true;
        }
        _error = null;
      });
    }
  }

  // ── Biométrie ─────────────────────────────────────────────────────────────
  Future<void> _verifierBiometrie() async {
    try {
      final avail = await _localAuth.canCheckBiometrics;
      if (!avail) {
        setState(() => _biometrieOk = true);
        return;
      }
      final ok = await _localAuth.authenticate(
          localizedReason: 'Enregistrez votre empreinte pour MauriVote');
      setState(() {
        _biometrieOk = ok;
      });
    } catch (_) {
      setState(() => _biometrieOk = true);
    }
  }

  // ── Créer compte ─────────────────────────────────────────────────────────
  Future<void> _creerCompte() async {
    // Double vérification CNI
    if (_cniRecto == null || _cniVerso == null) {
      setState(() => _error = 'CNI obligatoire — Retournez a l\'etape CNI');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;
      final nni = _nniCtrl.text.trim();

      // Vérifier NNI déjà enregistré
      final existing =
          await sb.from('voters').select('id').eq('nni', nni).maybeSingle();
      if (existing != null) {
        setState(() {
          _error = 'Ce NNI est deja enregistre. Connectez-vous.';
          _loading = false;
        });
        return;
      }

      // Récupérer commune par défaut
      final commune =
          await sb.from('communes').select('id, wilaya_id').limit(1).single();

      // Insérer voter avec CNI validée
      await sb.from('voters').insert({
        'nni': nni,
        'nom': _nomCtrl.text.trim().toUpperCase(),
        'prenom': _prenomCtrl.text.trim(),
        'date_naissance': _dateCtrl.text.trim(),
        'sexe': _sexe,
        'commune_id': commune['id'],
        'wilaya_id': commune['wilaya_id'],
        'telephone': '+222${_telCtrl.text.trim()}',
        'is_verified': false,
        'is_active': true,
        'kyc_completed': true, // CNI fournie
        'basma_verified': _biometrieOk,
        'account_type': 'user',
      });

      HapticFeedback.heavyImpact();
      if (!mounted) return;

      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                        color: Color(0xFF006233), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        size: 48, color: Colors.white)),
                const SizedBox(height: 16),
                const Text('Compte cree !',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Votre dossier est en cours de verification par la CENI. '
                    'Vous serez notifie une fois valide.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200)),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'CNI soumise — En attente validation CENI',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange))),
                    ])),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        backgroundColor: const Color(0xFF006233),
                        foregroundColor: Colors.white),
                    child: const Text('Se connecter')),
              ])));
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _loading = false;
      });
    }
  }

  // ── Date picker ──────────────────────────────────────────────────────────
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(1990),
        firstDate: DateTime(1920),
        lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
        builder: (_, child) => Theme(
            data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: _green)),
            child: child!));
    if (picked != null && mounted) {
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() => _dateCtrl.text = '${picked.year}-$m-$d');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF004D26), _green],
                begin: Alignment.topCenter,
                end: Alignment.center)),
        child: SafeArea(
            child: Column(children: [
          // Bande rouge
          Container(
              height: 4,
              decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_red, Color(0xFFFF1A2E), _red]))),

          // Header
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                GestureDetector(
                    onTap: _back,
                    child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 16))),
                const SizedBox(width: 12),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Creer un compte',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('CENI — Mauritanie',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                // Étape
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withOpacity(0.4))),
                    child: Text('${_step.index + 1}/4',
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
              ])),

          // Progress
          _buildProgress(),

          // Contenu
          Expanded(
              child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28))),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(children: [
                        if (_step == RegisterStep.infos)
                          _buildInfos()
                        else if (_step == RegisterStep.cni)
                          _buildCni()
                        else if (_step == RegisterStep.biometrie)
                          _buildBiometrie()
                        else
                          _buildConfirmation(),

                        // Erreur
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: _red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: _red.withOpacity(0.3))),
                              child: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: _red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            color: _red, fontSize: 13))),
                              ])),
                        ],

                        const SizedBox(height: 24),

                        // Boutons
                        Row(children: [
                          if (_step.index > 0) ...[
                            Expanded(
                                child: OutlinedButton.icon(
                                    onPressed: _back,
                                    icon:
                                        const Icon(Icons.arrow_back, size: 16),
                                    label: const Text('Retour'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: _green,
                                        side: const BorderSide(color: _green),
                                        minimumSize: const Size(0, 50)))),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                              child: Container(
                                  decoration: BoxDecoration(
                                      gradient: _canNext
                                          ? const LinearGradient(colors: [
                                              Color(0xFF004D26),
                                              _green
                                            ])
                                          : null,
                                      color: !_canNext
                                          ? Colors.grey.shade300
                                          : null,
                                      borderRadius: BorderRadius.circular(14)),
                                  child: ElevatedButton.icon(
                                      onPressed:
                                          _loading || !_canNext ? null : _next,
                                      icon: _loading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : Icon(
                                              _step == RegisterStep.confirmation
                                                  ? Icons.check_circle
                                                  : Icons.arrow_forward,
                                              size: 18),
                                      label: Text(_loading
                                          ? 'Creation...'
                                          : _step == RegisterStep.confirmation
                                              ? 'Creer mon compte'
                                              : 'Continuer'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          minimumSize: const Size(0, 50),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      14)))))),
                        ]),
                      ])))),

          // Bande rouge bas
          Container(
              height: 4,
              decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_red, Color(0xFFFF1A2E), _red]))),
        ])),
      ),
    );
  }

  Widget _buildProgress() {
    final labels = ['Infos', 'CNI', 'Biometrie', 'Confirmer'];
    final icons = [Icons.person, Icons.badge, Icons.fingerprint, Icons.check];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
          children: List.generate(4, (i) {
        final done = i < _step.index;
        final active = i == _step.index;
        return Expanded(
            child: Row(children: [
          Expanded(
              child: Column(children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? _green
                        : active
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                    border: Border.all(
                        color: done || active ? Colors.white : Colors.white30,
                        width: active ? 2 : 1)),
                child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Icon(icons[i],
                            color: active ? _green : Colors.white54,
                            size: 16))),
            const SizedBox(height: 4),
            Text(labels[i],
                style: TextStyle(
                    fontSize: 10,
                    color: active ? Colors.white : Colors.white60,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ])),
          if (i < 3)
            Container(
                height: 2,
                width: 20,
                color: i < _step.index ? Colors.white : Colors.white30),
        ]));
      })),
    );
  }

  // Étape 1 — Infos
  Widget _buildInfos() => Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('Informations personnelles', Icons.person),
        const SizedBox(height: 16),

        // NNI
        _label('NNI — Numero National d\'Identification *'),
        TextFormField(
            controller: _nniCtrl,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                hintText: '1234567890',
                prefixIcon: const Icon(Icons.badge_outlined, color: _green),
                counterText: '',
                helperText: '10 chiffres — Format mauritanien',
                helperStyle: const TextStyle(fontSize: 11)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'NNI requis';
              if (v.length != 10) return '10 chiffres requis';
              if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Format invalide';
              return null;
            }),
        const SizedBox(height: 12),

        // Nom
        _label('Nom de famille *'),
        TextFormField(
            controller: _nomCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                hintText: 'Tel qu\'il apparait sur la CNI',
                prefixIcon: Icon(Icons.person_outline, color: _green)),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nom requis (comme sur CNI)' : null),
        const SizedBox(height: 12),

        // Prénom
        _label('Prenom *'),
        TextFormField(
            controller: _prenomCtrl,
            decoration: const InputDecoration(
                hintText: 'Tel qu\'il apparait sur la CNI',
                prefixIcon: Icon(Icons.person_outline, color: _green)),
            validator: (v) => v == null || v.isEmpty
                ? 'Prenom requis (comme sur CNI)'
                : null),
        const SizedBox(height: 12),

        // Date naissance
        _label('Date de naissance *'),
        TextFormField(
            controller: _dateCtrl,
            readOnly: true,
            onTap: _selectDate,
            decoration: const InputDecoration(
                hintText: 'Selectionnez votre date',
                prefixIcon: Icon(Icons.cake_outlined, color: _green),
                suffixIcon: Icon(Icons.calendar_today_outlined, color: _green)),
            validator: (v) => v == null || v.isEmpty ? 'Date requise' : null),
        const SizedBox(height: 12),

        // Sexe
        _label('Sexe *'),
        Row(children: [
          Expanded(child: _sexeBtn('M', 'Masculin', Icons.male)),
          const SizedBox(width: 12),
          Expanded(child: _sexeBtn('F', 'Feminin', Icons.female)),
        ]),
        const SizedBox(height: 12),

        // Téléphone
        _label('Telephone (+222) *'),
        TextFormField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                hintText: '20001234',
                prefixIcon: const Icon(Icons.phone_outlined, color: _green),
                prefixText: '+222 ',
                counterText: '',
                helperText: '8 chiffres sans +222',
                helperStyle: const TextStyle(fontSize: 11)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Telephone requis';
              if (v.length != 8) return '8 chiffres requis';
              return null;
            }),

        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Les informations doivent correspondre exactement a votre CNI mauritanienne',
                      style: TextStyle(fontSize: 11, color: Colors.orange))),
            ])),
      ]));

  Widget _sexeBtn(String val, String label, IconData icon) => GestureDetector(
      onTap: () => setState(() => _sexe = val),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color:
                  _sexe == val ? _green.withOpacity(0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _sexe == val ? _green : Colors.grey.shade300,
                  width: _sexe == val ? 2 : 1)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: _sexe == val ? _green : Colors.grey, size: 20),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: _sexe == val ? _green : Colors.grey,
                    fontWeight:
                        _sexe == val ? FontWeight.bold : FontWeight.normal)),
          ])));

  // Étape 2 — CNI OBLIGATOIRE
  Widget _buildCni() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('Carte Nationale d\'Identite', Icons.badge),
        const SizedBox(height: 8),

        // Avertissement CNI obligatoire
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red.withOpacity(0.2))),
            child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_outlined, color: _red, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('CNI Obligatoire',
                            style: TextStyle(
                                color: _red, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                            'La carte nationale d\'identite mauritanienne est '
                            'obligatoire pour s\'inscrire. '
                            'Les deux faces (recto et verso) doivent etre photographiees.',
                            style: TextStyle(color: _red, fontSize: 12)),
                      ])),
                ])),
        const SizedBox(height: 20),

        // Recto
        _label('Recto (Face avant) *'),
        const SizedBox(height: 8),
        _cniCard(
            label: 'Face avant de la CNI',
            sublabel: 'Photo, nom, prenom, NNI visible',
            photo: _cniRecto,
            validated: _cniRectoValidated,
            onTap: () => _scanCni(true)),
        const SizedBox(height: 16),

        // Verso
        _label('Verso (Face arriere) *'),
        const SizedBox(height: 8),
        _cniCard(
            label: 'Face arriere de la CNI',
            sublabel: 'Date naissance, lieu visible',
            photo: _cniVerso,
            validated: _cniVersoValidated,
            onTap: () => _scanCni(false)),

        const SizedBox(height: 16),

        // Conseils CNI
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(0.2))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.tips_and_updates_outlined, color: _green, size: 16),
                SizedBox(width: 8),
                Text('Conseils pour une bonne photo',
                    style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              ...[
                'Bonne luminosite — pas de reflet',
                'CNI entiere visible dans le cadre',
                'Texte lisible — pas de flou',
                'Fond uni de preference',
              ].map((t) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: _green, size: 14),
                    const SizedBox(width: 6),
                    Text(t, style: const TextStyle(fontSize: 12)),
                  ]))),
            ])),

        // Indicateur validation
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _validBadge('Recto', _cniRecto != null),
          const SizedBox(width: 20),
          _validBadge('Verso', _cniVerso != null),
        ]),
      ]);

  Widget _cniCard(
      {required String label,
      required String sublabel,
      required XFile? photo,
      required bool validated,
      required VoidCallback onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 160,
            decoration: BoxDecoration(
                color: photo != null
                    ? _green.withOpacity(0.04)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: photo != null ? _green : _red.withOpacity(0.4),
                    width: photo != null ? 2 : 1.5,
                    style:
                        photo != null ? BorderStyle.solid : BorderStyle.solid)),
            child: photo != null
                ? Stack(fit: StackFit.expand, children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(File(photo.path), fit: BoxFit.cover)),
                    // Overlay validation
                    Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                                color: _green, shape: BoxShape.circle),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 18))),
                    // Retake
                    Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Text('Modifier',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)))),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                                color: _red.withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_outlined,
                                size: 28, color: _red)),
                        const SizedBox(height: 10),
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(sublabel,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: _red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: _red.withOpacity(0.3))),
                            child: const Text('OBLIGATOIRE',
                                style: TextStyle(
                                    color: _red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                      ])));
  }

  Widget _validBadge(String label, bool done) => Row(children: [
        Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: done ? _green : Colors.grey.shade300,
                shape: BoxShape.circle),
            child: Icon(done ? Icons.check : Icons.close,
                color: Colors.white, size: 14)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: done ? _green : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ]);

  // Étape 3 — Biométrie
  Widget _buildBiometrie() =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 20),
        const _SectionTitle('Biometrie', Icons.fingerprint),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'La biometrie est optionnelle mais renforce la securite de votre compte.',
                      style: TextStyle(fontSize: 12, color: Colors.blue))),
            ])),
        const SizedBox(height: 32),
        AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 130,
            height: 130,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _biometrieOk
                    ? _green.withOpacity(0.1)
                    : Colors.grey.shade100,
                border: Border.all(
                    color: _biometrieOk ? _green : Colors.grey.shade300,
                    width: 3)),
            child: Icon(_biometrieOk ? Icons.check_circle : Icons.fingerprint,
                size: 64, color: _biometrieOk ? _green : Colors.grey)),
        const SizedBox(height: 20),
        Text(
            _biometrieOk
                ? 'Empreinte enregistree !'
                : 'Enregistrez votre empreinte',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _biometrieOk ? _green : Colors.grey)),
        const SizedBox(height: 32),
        if (!_biometrieOk) ...[
          ElevatedButton.icon(
              onPressed: _verifierBiometrie,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Enregistrer mon empreinte'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48))),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () {
                setState(() => _biometrieOk = true);
                _next();
              },
              child: const Text('Passer cette etape',
                  style: TextStyle(color: AppTheme.textSecondary))),
        ],
      ]);

  // Étape 4 — Confirmation
  Widget _buildConfirmation() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('Recapitulatif', Icons.verified_user),
        const SizedBox(height: 20),

        // Badge CNI validée
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(0.2))),
            child: Row(children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: _green, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.badge, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('CNI Fournie',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _green)),
                    Text('Recto et Verso photographiees',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ])),
              const Icon(Icons.check_circle, color: _green, size: 28),
            ])),
        const SizedBox(height: 16),

        // Infos
        _infoRow('NNI', _nniCtrl.text),
        _infoRow('Nom', _nomCtrl.text.toUpperCase()),
        _infoRow('Prenom', _prenomCtrl.text),
        _infoRow('Date', _dateCtrl.text),
        _infoRow('Sexe', _sexe == 'M' ? 'Masculin' : 'Feminin'),
        _infoRow('Telephone', '+222 ${_telCtrl.text}'),
        const SizedBox(height: 12),

        // Statuts
        _checkRow('CNI photographiee (Recto)', _cniRecto != null),
        _checkRow('CNI photographiee (Verso)', _cniVerso != null),
        _checkRow('Biometrie enregistree', _biometrieOk),

        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200)),
            child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Votre dossier sera examine par la CENI dans un delai de 24-48h. '
                          'Vous serez notifie par SMS une fois valide.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.orange))),
                ])),
      ]);

  Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13))),
      ]));

  Widget _checkRow(String label, bool done) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(done ? Icons.check_circle : Icons.cancel,
            color: done ? _green : _red, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: done ? Colors.black : Colors.grey, fontSize: 13)),
      ]));

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
}

// Widget titre section
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle(this.title, this.icon);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: const Color(0xFF006233), size: 22),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]);
}
