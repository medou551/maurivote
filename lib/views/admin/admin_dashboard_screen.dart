import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../main.dart';
import '../../utils/mauritania_flag.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  static const Color _green = Color(0xFF006233);
  static const Color _gold  = Color(0xFFFFD700);
  static const Color _red   = Color(0xFFD90012);

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _elections = [];
  List<Map<String, dynamic>> _voters    = [];
  List<Map<String, dynamic>> _votes     = [];
  List<Map<String, dynamic>> _wilayas   = [];
  List<Map<String, dynamic>> _bureaux   = [];
  bool _loading = true;
  String _searchQuery = '';
  String _maskNni(String nni) {
    if (nni.length < 6) return nni;
    return nni.substring(0, 3) + '****' + nni.substring(nni.length - 3);
  }


  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final elections = await supabase.from('elections').select('*').order('created_at', ascending: false);
      final voters    = await supabase.from('voters').select('*').order('created_at', ascending: false);
      final votes     = await supabase.from('votes').select('*, elections(titre_fr), candidates(nom)').order('timestamp_vote', ascending: false).limit(100);
      final wilayas   = await supabase.from('wilayas').select('*').order('code');
      final bureaux   = await supabase.from('bureaux_vote').select('*, communes(nom_fr), wilayas(nom_fr)').order('code_bureau');

      final el = List<Map<String, dynamic>>.from(elections as List);
      final vt = List<Map<String, dynamic>>.from(voters as List);
      final vo = List<Map<String, dynamic>>.from(votes as List);
      final wi = List<Map<String, dynamic>>.from(wilayas as List);
      final bu = List<Map<String, dynamic>>.from(bureaux as List);

      if (mounted) setState(() {
        _elections = el; _voters = vt; _votes = vo; _wilayas = wi; _bureaux = bu;
        _stats = {
          'elections': el.length,
          'en_cours':  el.where((e) => e['statut'] == 'en_cours').length,
          'voters':    vt.length,
          'votes':     vo.length,
          'valides':   vo.where((v) => v['is_valid'] == true).length,
          'annules':   vo.where((v) => v['is_valid'] == false).length,
          'anomalies': vo.where((v) => v['is_anomaly'] == true).length,
          'admins':    vt.where((v) => v['account_type'] == 'admin').length,
          'kyc_ok':    vt.where((v) => v['kyc_completed'] == true).length,
          'bureaux':   bu.length,
        };
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Admin CENI', style: TextStyle(fontSize: 15)),
        ]),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).signOut();
              if (mounted) context.go('/login');
            }),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: _gold,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 16), text: 'Overview'),
            Tab(icon: Icon(Icons.how_to_vote, size: 16), text: 'Elections'),
            Tab(icon: Icon(Icons.people, size: 16), text: 'Electeurs'),
            Tab(icon: Icon(Icons.ballot, size: 16), text: 'Votes'),
            Tab(icon: Icon(Icons.map, size: 16), text: 'Bureaux'),
            Tab(icon: Icon(Icons.bar_chart, size: 16), text: 'Rapports'),
          ])),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _buildOverview(),
              _buildElections(),
              _buildElecteurs(),
              _buildVotes(),
              _buildBureaux(),
              _buildRapports(),
            ]));
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _statCard('Elections', '${_stats['elections'] ?? 0}', Icons.how_to_vote, _green),
            _statCard('En cours', '${_stats['en_cours'] ?? 0}', Icons.play_circle, Colors.orange),
            _statCard('Electeurs', '${_stats['voters'] ?? 0}', Icons.people, Colors.blue),
            _statCard('Votes', '${_stats['votes'] ?? 0}', Icons.ballot, Colors.purple),
            _statCard('Valides', '${_stats['valides'] ?? 0}', Icons.check_circle, Colors.green),
            _statCard('Anomalies', '${_stats['anomalies'] ?? 0}', Icons.warning, Colors.red),
          ]),
        const SizedBox(height: 20),
        _sectionTitle('Notifications Push'),
        _card(child: Column(children: [
          _notifBtn('Ouverture scrutin'),
          _notifBtn('Rappel voter'),
          _notifBtn('Resultats disponibles'),
        ])),
        const SizedBox(height: 16),
        _sectionTitle('Votes recents'),
        ..._votes.take(5).map((v) => _voteCard(v)),
      ]));
  }

  Widget _notifBtn(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      const Icon(Icons.notifications_outlined, color: Color(0xFF006233), size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      ElevatedButton(
        onPressed: () async {
          try {
            await supabase.from('audit_logs').insert({'action': 'NOTIFICATION_PUSH', 'details': {'type': title}});
          } catch (_) {}
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Notification envoyee: $title'),
            backgroundColor: _green, behavior: SnackBarBehavior.floating));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _green, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('Envoyer', style: TextStyle(fontSize: 11))),
    ]));

  Widget _buildElections() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _creerElection,
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle election'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46)))),
      Expanded(child: _elections.isEmpty
          ? const Center(child: Text('Aucune election'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _elections.length,
              itemBuilder: (_, i) => _electionCard(_elections[i]))),
    ]);
  }

  Widget _electionCard(Map<String, dynamic> e) {
    final statut = e['statut'] ?? '';
    final color = statut == 'en_cours' ? Colors.green : statut == 'terminee' ? Colors.grey : Colors.orange;
    final isPublic = e['is_public'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(e['titre_fr'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: const TextStyle(color: Colors.white, fontSize: 11))),
            const SizedBox(width: 8),
            Icon(isPublic ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.grey),
          ]),
          const SizedBox(height: 4),
          Text(e['type_election'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            if (statut == 'planifiee')
              _btnSmall('Demarrer', Colors.green, () => _changerStatut(e['id'], 'en_cours')),
            if (statut == 'en_cours') ...[
              _btnSmall('Terminer', Colors.red, () => _changerStatut(e['id'], 'terminee')),
              _btnSmall('+ Candidat', _green, () => _ajouterCandidat(e['id'], e['titre_fr'])),
            ],
            if (statut == 'terminee')
              _btnSmall('Resultats', _green, () => context.push('/resultats/${e['id']}')),
            _btnSmall(isPublic ? 'Masquer' : 'Publier',
                isPublic ? Colors.grey : Colors.blue,
                () => _togglePublic(e['id'], !isPublic)),
          ]),
        ])));
  }

  Future<void> _creerElection() async {
    final titreCtrl = TextEditingController();
    final titrArCtrl = TextEditingController();
    String type = 'presidentielle';
    bool isPublic = true;

    await showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: const Text('Nouvelle election'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: 'Titre *', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: titrArCtrl, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            items: ['presidentielle','legislative','municipale','referendum']
                .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setSt(() => type = v!)),
          SwitchListTile(
            value: isPublic, onChanged: (v) => setSt(() => isPublic = v),
            title: const Text('Visible aux electeurs', style: TextStyle(fontSize: 13)),
            activeColor: _green),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (titreCtrl.text.isEmpty) return;
              await supabase.from('elections').insert({
                'titre_fr': titreCtrl.text.trim(),
                'titre_ar': titrArCtrl.text.trim(),
                'type_election': type,
                'statut': 'planifiee',
                'date_ouverture': DateTime.now().toIso8601String(),
                'date_fermeture': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
                'nb_tours': 1, 'tour_actuel': 1,
                'is_public': isPublic,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Election creee !'), backgroundColor: Color(0xFF006233), behavior: SnackBarBehavior.floating));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('Creer')),
        ])));
  }

  Future<void> _ajouterCandidat(String electionId, String? titre) async {
    final nomCtrl = TextEditingController();
    final partiCtrl = TextEditingController();
    final partiArCtrl = TextEditingController();
    final numCtrl = TextEditingController();

    await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Candidat - ${titre ?? ''}', style: const TextStyle(fontSize: 14)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: numCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Numero *', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: partiCtrl, decoration: const InputDecoration(labelText: 'Parti', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: partiArCtrl, textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'الحزب', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            if (nomCtrl.text.isEmpty) return;
            await supabase.from('candidates').insert({
              'election_id': electionId,
              'nom': nomCtrl.text.trim(),
              'parti': partiCtrl.text.trim(),
              'parti_ar': partiArCtrl.text.trim(),
              'numero_candidat': int.tryParse(numCtrl.text.trim()) ?? 1,
              'nb_voix': 0, 'is_active': true, 'tour': 1,
            });
            if (mounted) Navigator.pop(context);
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Candidat ajoute !'), backgroundColor: Color(0xFF006233), behavior: SnackBarBehavior.floating));
          },
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
          child: const Text('Ajouter')),
      ]));
  }

  Future<void> _changerStatut(String id, String statut) async {
    await supabase.from('elections').update({'statut': statut}).eq('id', id);
    _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Statut: $statut'), backgroundColor: _green, behavior: SnackBarBehavior.floating));
  }

  Future<void> _togglePublic(String id, bool isPublic) async {
    await supabase.from('elections').update({'is_public': isPublic}).eq('id', id);
    _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isPublic ? 'Election visible' : 'Election masquee'),
      backgroundColor: _green, behavior: SnackBarBehavior.floating));
  }

  Widget _buildElecteurs() {
    final filtered = _voters.where((v) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty
          
          || (v['nom'] ?? '').toString().toLowerCase().contains(q)
          || (v['prenom'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Rechercher NNI, nom...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(), isDense: true),
          onChanged: (q) => setState(() => _searchQuery = q))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _miniStat('Total', _voters.length, _green),
          const SizedBox(width: 8),
          _miniStat('KYC', _stats['kyc_ok'] ?? 0, Colors.green),
          const SizedBox(width: 8),
          _miniStat('Admins', _stats['admins'] ?? 0, Colors.red),
        ])),
      const SizedBox(height: 8),
      Expanded(child: filtered.isEmpty
          ? const Center(child: Text('Aucun electeur'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _voterCard(filtered[i]))),
    ]);
  }

  Widget _voterCard(Map<String, dynamic> v) {
    final isAdmin = v['account_type'] == 'admin';
    final kycOk   = v['kyc_completed'] == true;
    final basmaOk = v['basma_verified'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.red.shade50 : _green.withOpacity(0.1),
          child: Text(
            (v['prenom'] ?? '').toString().isNotEmpty ? (v['prenom'] as String)[0].toUpperCase() : '?',
            style: TextStyle(color: isAdmin ? Colors.red : _green, fontWeight: FontWeight.bold))),
        title: Text('${v['prenom'] ?? ''} ${v['nom'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(v['nni'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        trailing: Wrap(spacing: 4, children: [
          if (kycOk) const Icon(Icons.badge, color: Colors.blue, size: 16),
          if (basmaOk) const Icon(Icons.fingerprint, color: Colors.green, size: 16),
          if (isAdmin) const Icon(Icons.admin_panel_settings, color: Colors.red, size: 16),
        ]),
        onTap: () => _voterActions(v)));
  }

  void _voterActions(Map<String, dynamic> v) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Text('${v['prenom']} ${v['nom']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ListTile(
          leading: const Icon(Icons.verified_user, color: Colors.blue),
          title: const Text('Valider CNI (KYC)'),
          onTap: () async {
            Navigator.pop(context);
            await supabase.from('voters').update({'kyc_completed': true}).eq('id', v['id']);
            _load();
          }),
        ListTile(
          leading: Icon(v['is_active'] == true ? Icons.block : Icons.check_circle, color: Colors.orange),
          title: Text(v['is_active'] == true ? 'Desactiver' : 'Activer'),
          onTap: () async {
            Navigator.pop(context);
            await supabase.from('voters').update({'is_active': !(v['is_active'] == true)}).eq('id', v['id']);
            _load();
          }),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
          title: Text(v['account_type'] == 'admin' ? 'Retrograder' : v['account_type'] == 'observateur' ? 'Retirer observateur' : 'Promouvoir admin'),
          onTap: () async {
            Navigator.pop(context);
            await supabase.from('voters')
                .update({'account_type': v['account_type'] == 'admin' ? 'user' : 'admin'})
                .eq('id', v['id']);
            _load();
          }),
      ])));
  }

  Widget _buildVotes() {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16),
        child: Row(children: [
          _miniStat('Total', _votes.length, _green),
          const SizedBox(width: 8),
          _miniStat('Valides', _stats['valides'] ?? 0, Colors.green),
          const SizedBox(width: 8),
          _miniStat('Annules', _stats['annules'] ?? 0, Colors.orange),
          const SizedBox(width: 8),
          _miniStat('Anomalies', _stats['anomalies'] ?? 0, Colors.red),
        ])),
      Expanded(child: _votes.isEmpty
          ? const Center(child: Text('Aucun vote', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _votes.length,
              itemBuilder: (_, i) => _voteCard(_votes[i]))),
    ]);
  }

  Widget _voteCard(Map<String, dynamic> v) {
    final isValid   = v['is_valid'] == true;
    final isAnomaly = v['is_anomaly'] == true;
    final date = (v['timestamp_vote'] ?? '').toString();
    final dateStr = date.length >= 10 ? date.substring(0, 10) : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAnomaly ? Colors.red.shade50 : isValid ? Colors.green.shade50 : Colors.orange.shade50,
          child: Icon(
            isAnomaly ? Icons.warning : isValid ? Icons.check : Icons.cancel,
            color: isAnomaly ? Colors.red : isValid ? Colors.green : Colors.orange, size: 20)),
        title: Text(v['elections']?['titre_fr'] ?? 'Election',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(v['candidates']?['nom'] ?? '-', style: const TextStyle(fontSize: 11)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isAnomaly ? Colors.red : isValid ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(10)),
            child: Text(isAnomaly ? 'Anomalie' : isValid ? 'Valide' : 'Annule',
                style: const TextStyle(color: Colors.white, fontSize: 9))),
        ])));
  }

  Widget _buildBureaux() {
    return DefaultTabController(length: 2,
      child: Column(children: [
        const TabBar(
          labelColor: Color(0xFF006233), unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF006233),
          tabs: [Tab(text: 'Bureaux'), Tab(text: 'Wilayas')]),
        Expanded(child: TabBarView(children: [
          Column(children: [
            Padding(padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showBureauDialog(null),
                icon: const Icon(Icons.add_location),
                label: const Text('Ajouter bureau'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44)))),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bureaux.length,
              itemBuilder: (_, i) {
                final b = _bureaux[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.how_to_vote, color: Color(0xFF006233), size: 20)),
                    title: Text(b['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${b['communes']?['nom_fr'] ?? ''} - ${b['wilayas']?['nom_fr'] ?? ''}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: Text('${b['capacite'] ?? 0}', style: const TextStyle(fontSize: 11)),
                    onTap: () => _showBureauDialog(b)));
              })),
          ]),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _wilayas.length,
            itemBuilder: (_, i) {
              final w = _wilayas[i];
              final nb = _bureaux.where((b) => b['wilaya_id'] == w['id']).length;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(w['code'] ?? '',
                        style: TextStyle(color: _green, fontSize: 9, fontWeight: FontWeight.bold)))),
                  title: Text(w['nom_fr'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(w['chef_lieu'] ?? '', style: const TextStyle(fontSize: 11)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$nb', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: nb > 0 ? _green : Colors.grey)),
                    const Text('bureaux', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ])));
            }),
        ])),
      ]));
  }

  Future<void> _showBureauDialog(Map<String, dynamic>? bureau) async {
    final nomCtrl  = TextEditingController(text: bureau?['nom'] ?? '');
    final latCtrl  = TextEditingController(text: bureau?['latitude']?.toString() ?? '');
    final lngCtrl  = TextEditingController(text: bureau?['longitude']?.toString() ?? '');
    final capCtrl  = TextEditingController(text: bureau?['capacite']?.toString() ?? '');
    final codeCtrl = TextEditingController(text: bureau?['code_bureau'] ?? '');
    String? wilayaId = bureau?['wilaya_id'];
    String? communeId = bureau?['commune_id'];
    List<Map<String, dynamic>> communes = [];
    bool accessible = bureau?['is_accessible'] ?? true;
    bool actif = bureau?['is_actif'] ?? true;

    if (wilayaId != null) {
      final data = await supabase.from('communes').select('*').eq('wilaya_id', wilayaId).order('nom_fr');
      communes = List<Map<String, dynamic>>.from(data as List);
    }

    await showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(bureau == null ? 'Nouveau bureau' : 'Modifier bureau'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: wilayaId,
            decoration: const InputDecoration(labelText: 'Wilaya *', border: OutlineInputBorder()),
            items: _wilayas.map((w) => DropdownMenuItem(value: w['id'].toString(), child: Text(w['nom_fr'] ?? ''))).toList(),
            onChanged: (v) async {
              setSt(() { wilayaId = v; communeId = null; });
              if (v != null) {
                final data = await supabase.from('communes').select('*').eq('wilaya_id', v).order('nom_fr');
                communes = List<Map<String, dynamic>>.from(data as List);
                setSt(() {});
              }
            }),
          const SizedBox(height: 8),
          if (communes.isNotEmpty)
            DropdownButtonFormField<String>(
              value: communeId,
              decoration: const InputDecoration(labelText: 'Commune *', border: OutlineInputBorder()),
              items: communes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['nom_fr'] ?? ''))).toList(),
              onChanged: (v) => setSt(() => communeId = v)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: latCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: lngCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 8),
          TextField(controller: capCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacite', border: OutlineInputBorder())),
          SwitchListTile(dense: true, value: accessible, onChanged: (v) => setSt(() => accessible = v),
              title: const Text('Accessible PMR', style: TextStyle(fontSize: 13)), activeColor: _green),
          SwitchListTile(dense: true, value: actif, onChanged: (v) => setSt(() => actif = v),
              title: const Text('Bureau actif', style: TextStyle(fontSize: 13)), activeColor: _green),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.isEmpty || wilayaId == null || communeId == null) return;
              final data = {
                'code_bureau': codeCtrl.text.trim(), 'nom': nomCtrl.text.trim(),
                'wilaya_id': wilayaId, 'commune_id': communeId,
                'latitude': double.tryParse(latCtrl.text) ?? 0,
                'longitude': double.tryParse(lngCtrl.text) ?? 0,
                'capacite': int.tryParse(capCtrl.text) ?? 0,
                'is_accessible': accessible, 'is_actif': actif,
              };
              if (bureau == null) {
                await supabase.from('bureaux_vote').insert(data);
              } else {
                await supabase.from('bureaux_vote').update(data).eq('id', bureau['id']);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(bureau == null ? 'Bureau ajoute !' : 'Bureau modifie !'),
                backgroundColor: _green, behavior: SnackBarBehavior.floating));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            child: Text(bureau == null ? 'Ajouter' : 'Modifier')),
        ])));
  }

  Widget _buildRapports() {
    final taux = _voters.isNotEmpty ? (_votes.length / _voters.length * 100) : 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _sectionTitle('Statistiques'),
        _card(child: Column(children: [
          _rapportRow('Elections', '${_elections.length}'),
          _rapportRow('En cours', '${_stats['en_cours'] ?? 0}'),
          _rapportRow('Electeurs', '${_voters.length}'),
          _rapportRow('Votes', '${_votes.length}'),
          _rapportRow('Taux participation', '${taux.toStringAsFixed(1)}%'),
          _rapportRow('Valides', '${_stats['valides'] ?? 0}'),
          _rapportRow('Anomalies', '${_stats['anomalies'] ?? 0}'),
          _rapportRow('Bureaux', '${_bureaux.length}/26'),
          _rapportRow('Wilayas couvertes', '${_bureaux.map((b) => b['wilaya_id']).toSet().length}/15'),
        ])),
        const SizedBox(height: 16),
        _sectionTitle('Elections'),
        ..._elections.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            title: Text(e['titre_fr'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(e['statut'] ?? '', style: const TextStyle(fontSize: 11)),
            trailing: OutlinedButton(
              onPressed: () => context.push('/resultats/${e['id']}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green, side: const BorderSide(color: Color(0xFF006233)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
              child: const Text('Voir', style: TextStyle(fontSize: 12)))))),
        const SizedBox(height: 16),
        _sectionTitle('Export'),
        _card(child: Column(children: [
          ListTile(dense: true,
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Rapport PDF', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.download, size: 18),
            onTap: () async {
              final txt = 'RAPPORT MAURIVOTE\nElections: ${_elections.length}\nElecteurs: ${_voters.length}\nVotes: ${_votes.length}\nTaux: ${taux.toStringAsFixed(1)}%';
              await Share.share(txt, subject: 'Rapport MauriVote');
            }),
          ListTile(dense: true,
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('CSV Electeurs', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.download, size: 18),
            onTap: () async {
              var csv = 'NNI,Nom,Prenom,Type,KYC\n';
              for (final v in _voters) {
                csv += _maskNni(v['nni'] ?? '') + ',' + (v['nom'] ?? '') + ',' + (v['prenom'] ?? '') + ',' + (v['account_type'] ?? '') + ',' + v['kyc_completed'].toString() + '\n';
              }
              await Share.share(csv, subject: 'electeurs.csv');
            }),
          ListTile(dense: true,
            leading: const Icon(Icons.how_to_vote, color: Colors.blue),
            title: const Text('CSV Votes', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.download, size: 18),
            onTap: () async {
              var csv = 'Election,Candidat,Date,Valide\n';
              for (final v in _votes) {
                csv += '${v['elections']?['titre_fr'] ?? ''},${v['candidates']?['nom'] ?? ''},${(v['timestamp_vote'] ?? '').toString().substring(0, 10)},${v['is_valid']}\n';
              }
              await Share.share(csv, subject: 'votes.csv');
            }),
        ])),
      ]));
  }

  Widget _rapportRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ]));

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 24), const Spacer(),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]));

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Align(alignment: Alignment.centerLeft,
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))));

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))]),
    child: child);

  Widget _btnSmall(String label, Color color, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color, foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: Size.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    child: Text(label, style: const TextStyle(fontSize: 11)));

  Widget _miniStat(String label, int val, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text('$val', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ])));
}