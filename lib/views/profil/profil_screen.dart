import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../app.dart';
import 'package:go_router/go_router.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});
  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  Map<String, dynamic>? _voter;
  List<Map<String, dynamic>> _votes = [];
  bool _loading = true;
  bool _nniVisible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _maskNni(String nni) {
    if (nni.length < 6) return nni;
    return nni.substring(0, 3) + '****' + nni.substring(nni.length - 3);
  }

  Future<void> _load() async {
    try {
      final nni = await ref.read(authServiceProvider).getCurrentNni();
      if (nni == null || nni.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final voterData = await supabase
          .from('voters')
          .select('*')
          .eq('nni', nni)
          .maybeSingle();
      if (voterData == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final votesData = await supabase
          .from('votes')
          .select(
              'id, timestamp_vote, election_id, recu_hash, is_valid, elections(titre_fr)')
          .eq('voter_hash', voterData['id'].toString())
          .order('timestamp_vote', ascending: false);
      if (mounted)
        setState(() {
          _voter = Map<String, dynamic>.from(voterData);
          _votes = List<Map<String, dynamic>>.from(votesData as List);
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Deconnexion'),
                content: const Text('Voulez-vous vous deconnecter ?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      child: const Text('Deconnecter')),
                ]));
    if (ok == true && mounted) {
      await ref.read(authStateProvider.notifier).signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _voter == null
              ? _buildNotFound()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _buildAvatar(),
                        const SizedBox(height: 24),
                        _buildInfosCard(),
                        const SizedBox(height: 16),
                        _buildStatutCard(),
                        const SizedBox(height: 16),
                        _buildVotesCard(),
                        const SizedBox(height: 16),
                        _buildSecuriteCard(),
                        const SizedBox(height: 16),
                        _buildCarteCard(),
                        const SizedBox(height: 24),
                      ]))),
    );
  }

  Widget _buildAvatar() {
    final nom = _voter?['nom'] ?? '';
    final prenom = _voter?['prenom'] ?? '';
    final initiale = prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';
    return Column(children: [
      Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ]),
          child: Center(
              child: Text(initiale,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold)))),
      const SizedBox(height: 12),
      Text('$prenom $nom',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Electeur enregistre',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]);
  }

  Widget _buildInfosCard() {
    final nni = _voter?['nni'] ?? '';
    return _card('Informations personnelles', Icons.person, [
      _row(
          Icons.badge_outlined,
          'NNI',
          Row(children: [
            Text(_nniVisible ? nni : _maskNni(nni),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: () => setState(() => _nniVisible = !_nniVisible),
                child: Icon(
                    _nniVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppTheme.primaryGreen)),
            const SizedBox(width: 4),
            GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: nni));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('NNI copie !'),
                      backgroundColor: AppTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2)));
                },
                child: const Icon(Icons.copy,
                    size: 16, color: AppTheme.textSecondary)),
          ])),
      _row(
          Icons.person_outline,
          'Nom',
          Text('${_voter?['prenom'] ?? ''} ${_voter?['nom'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold))),
      _row(
          Icons.cake_outlined,
          'Date de naissance',
          Text(_voter?['date_naissance'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold))),
      _row(
          Icons.wc_outlined,
          'Sexe',
          Text(_voter?['sexe'] == 'M' ? 'Masculin' : 'Feminin',
              style: const TextStyle(fontWeight: FontWeight.bold))),
      _row(
          Icons.phone_outlined,
          'Telephone',
          Text(_voter?['telephone'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildStatutCard() {
    final isVerified = _voter?['is_verified'] == true;
    final kycDone = _voter?['kyc_completed'] == true;
    final basma = _voter?['basma_verified'] == true;
    final accountType = _voter?['account_type'] ?? 'user';
    return _card('Statut du compte', Icons.verified_user, [
      _statusRow('Compte verifie', isVerified),
      _statusRow('KYC complete (CNI)', kycDone),
      _statusRow('Biometrie (Basma)', basma),
      _row(
          Icons.admin_panel_settings_outlined,
          'Type de compte',
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: accountType == 'admin'
                      ? Colors.red.shade50
                      : AppTheme.lightGreen.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                  accountType == 'admin' ? 'Administrateur' : 'Electeur',
                  style: TextStyle(
                      color: accountType == 'admin'
                          ? Colors.red
                          : AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)))),
    ]);
  }

  Widget _buildVotesCard() {
    return _card('Historique des votes', Icons.history, [
      if (_votes.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text('Aucun vote enregistre',
                    style: TextStyle(color: AppTheme.textSecondary))))
      else
        ..._votes.map((v) {
          final election = v['elections'];
          final titre = election?['titre_fr'] ?? 'Election';
          final date =
              (v['timestamp_vote'] ?? v['created_at'] ?? '').toString();
          final dateStr = date.length >= 10 ? date.substring(0, 10) : '';
          final isValid = v['is_valid'] == true;
          return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: isValid
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : Colors.orange.shade50,
                        shape: BoxShape.circle),
                    child: Icon(
                        isValid ? Icons.how_to_vote : Icons.warning_outlined,
                        color: isValid ? AppTheme.primaryGreen : Colors.orange,
                        size: 20)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(titre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(dateStr,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: isValid ? AppTheme.primaryGreen : Colors.orange,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(isValid ? 'Valide' : 'Annule',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))),
              ]));
        }),
    ]);
  }

  Widget _buildLangueCard() {
    return _card('Langue / اللغة', Icons.language, [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        ElevatedButton(
            onPressed: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('fr')),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006233),
                foregroundColor: Colors.white),
            child: const Text('Francais')),
        ElevatedButton(
            onPressed: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('ar')),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                foregroundColor: Colors.white),
            child: const Text('العربية')),
      ]),
    ]);
  }

  Widget _buildSecuriteCard() {
    return _card('Securite', Icons.security, [
      _row(
          Icons.fingerprint,
          'Biometrie',
          const Text('Activee',
              style: TextStyle(
                  color: AppTheme.primaryGreen, fontWeight: FontWeight.bold))),
      _row(Icons.lock_outline, 'Chiffrement',
          const Text('AES-256', style: TextStyle(fontWeight: FontWeight.bold))),
      _row(
          Icons.shield_outlined,
          'Protection',
          const Text('CENI certifie',
              style: TextStyle(fontWeight: FontWeight.bold))),
      const SizedBox(height: 8),
      SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Se deconnecter',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red)))),
    ]);
  }

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]));

  Widget _row(IconData icon, String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        value,
      ]));

  Widget _statusRow(String label, bool done) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(done ? Icons.check_circle : Icons.cancel,
            color: done ? AppTheme.primaryGreen : Colors.grey, size: 20),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: done ? Colors.black : Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(done ? 'Oui' : 'Non',
            style: TextStyle(
                color: done ? AppTheme.primaryGreen : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ]));

  Widget _buildCarteCard() => _card('Mon Bureau de Vote', Icons.map, [
        const Text('Trouvez votre bureau de vote le plus proche',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
            onPressed: () => context.push('/profil/bureau'),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Voir la carte des bureaux'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                backgroundColor: const Color(0xFF006233),
                foregroundColor: Colors.white)),
      ]);

  Widget _buildNotFound() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.person_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Profil introuvable', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Se connecter')),
      ]));
}
