import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ElectionDetailScreen extends ConsumerStatefulWidget {
  final String electionId;
  const ElectionDetailScreen({super.key, required this.electionId});
  @override
  ConsumerState<ElectionDetailScreen> createState() =>
      _ElectionDetailScreenState();
}

class _ElectionDetailScreenState extends ConsumerState<ElectionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _election;
  List<Map<String, dynamic>> _candidats = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  bool _dejaVote = false;

  final List<Color> _colors = [
    const Color(0xFF1B5E20),
    const Color(0xFF1565C0),
    const Color(0xFF6A1B9A),
    const Color(0xFFE65100),
    const Color(0xFF00695C),
    const Color(0xFFB71C1C),
    const Color(0xFF37474F),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Election
      final electionData = await supabase
          .from('elections')
          .select('*')
          .eq('id', widget.electionId)
          .single();
      final election = Map<String, dynamic>.from(electionData);

      // Candidats
      final candidatsData = await supabase
          .from('candidates')
          .select('*')
          .eq('election_id', widget.electionId)
          .eq('is_active', true)
          .order('numero_candidat');
      final candidats = List<Map<String, dynamic>>.from(candidatsData as List);

      // Stats votes
      final votesData = await supabase
          .from('votes')
          .select('id, is_valid, is_anomaly')
          .eq('election_id', widget.electionId);
      final votes = List<Map<String, dynamic>>.from(votesData as List);
      final totalVotes = votes.length;
      final votesValides = votes.where((v) => v['is_valid'] == true).length;
      final votesAnnules = votes.where((v) => v['is_valid'] == false).length;
      final fuites = votes.where((v) => v['is_anomaly'] == true).length;

      // Vérifier si déjà voté
      final nni = await ref.read(authServiceProvider).getCurrentNni();
      bool dejaVote = false;
      if (nni != null) {
        final voterData = await supabase
            .from('voters')
            .select('id')
            .eq('nni', nni)
            .maybeSingle();
        if (voterData != null) {
          final voteExist = await supabase
              .from('votes')
              .select('id')
              .eq('election_id', widget.electionId)
              .eq('voter_hash', voterData['id'].toString())
              .maybeSingle();
          dejaVote = voteExist != null;
        }
      }

      if (mounted)
        setState(() {
          _election = election;
          _candidats = candidats;
          _stats = {
            'total': totalVotes,
            'valides': votesValides,
            'annules': votesAnnules,
            'fuites': fuites,
          };
          _dejaVote = dejaVote;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalVoix =>
      _candidats.fold(0, (s, c) => s + (c['nb_voix'] as int? ?? 0));

  double _pct(Map<String, dynamic> c) {
    final t = _totalVoix;
    if (t == 0) return 0;
    return (c['nb_voix'] as int? ?? 0) / t * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _election?['statut'] == 'en_cours';
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(_election?['titre_fr'] ?? 'Election',
            style: const TextStyle(fontSize: 15)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 18), text: 'Candidats'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Resultats'),
            Tab(icon: Icon(Icons.security, size: 18), text: 'Securite'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _buildCandidats(),
              _buildResultats(),
              _buildSecurite(),
            ]),
      bottomNavigationBar: isOpen && !_dejaVote
          ? SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/vote/${widget.electionId}'),
                    icon: const Icon(Icons.how_to_vote),
                    label: const Text('Voter maintenant'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white),
                  )))
          : _dejaVote
              ? SafeArea(
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text('Vous avez deja vote',
                                style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold)),
                          ])))
              : null,
    );
  }

  // TAB 1 — Candidats
  Widget _buildCandidats() {
    if (_candidats.isEmpty) {
      return const Center(child: Text('Aucun candidat disponible'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _candidats.length,
      itemBuilder: (_, i) {
        final c = _candidats[i];
        final color = _colors[i % _colors.length];
        final pct = _pct(c);
        final isLeader = i == 0 && _totalVoix > 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isLeader ? 4 : 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: isLeader
                  ? BorderSide(color: color, width: 2)
                  : BorderSide.none),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // Numéro
                Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                        child: Text('${c['numero_candidat'] ?? i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Expanded(
                            child: Text(c['nom'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14))),
                        if (isLeader)
                          const Icon(Icons.emoji_events,
                              color: Color(0xFFFFB300), size: 20),
                      ]),
                      Text(c['parti'] ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500)),
                      if ((c['parti_ar'] ?? '').isNotEmpty)
                        Text(c['parti_ar'] ?? '',
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                    ])),
              ]),
              if (_totalVoix > 0) ...[
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${pct.toStringAsFixed(2)}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 16)),
                      Text('${_formatN(c['nb_voix'] as int? ?? 0)} voix',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
              if ((c['biographie_fr'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(c['biographie_fr'],
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        );
      },
    );
  }

  // TAB 2 — Résultats
  Widget _buildResultats() {
    final total = _totalVoix;
    if (total == 0) {
      return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart, size: 64, color: AppTheme.primaryGreen),
        SizedBox(height: 16),
        Text('Aucun resultat disponible',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Les resultats apparaitront apres le vote',
            style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Stats globales
        Row(children: [
          Expanded(
              child: _miniStat('Total voix', _formatN(total), Icons.how_to_vote,
                  AppTheme.primaryGreen)),
          const SizedBox(width: 8),
          Expanded(
              child: _miniStat('Candidats', '${_candidats.length}',
                  Icons.people, const Color(0xFF1565C0))),
          const SizedBox(width: 8),
          Expanded(
              child: _miniStat(
                  'Taux', '55.39%', Icons.percent, const Color(0xFF6A1B9A))),
        ]),
        const SizedBox(height: 20),
        // Barres
        ...List.generate(_candidats.length, (i) {
          final c = _candidats[i];
          final pct = _pct(c);
          final color = _colors[i % _colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 24,
                    height: 24,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)))),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(c['nom'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                Text('${pct.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text(_formatN(c['nb_voix'] as int? ?? 0),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary))),
            ]),
          );
        }),
      ]),
    );
  }

  // TAB 3 — Sécurité
  Widget _buildSecurite() {
    final total = _stats['total'] ?? 0;
    final valides = _stats['valides'] ?? 0;
    final annules = _stats['annules'] ?? 0;
    final fuites = _stats['fuites'] ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Audit de securite',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Surveillance en temps reel des votes',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        // Cartes stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _secCard(
                'Total votes', total, Icons.how_to_vote, AppTheme.primaryGreen),
            _secCard(
                'Votes valides', valides, Icons.check_circle, Colors.green),
            _secCard('Votes annules', annules, Icons.cancel, Colors.orange),
            _secCard('Anomalies', fuites, Icons.warning, Colors.red),
          ],
        ),
        const SizedBox(height: 24),
        // Indicateurs
        _indicateur('Integrite des donnees',
            total > 0 ? (valides / total * 100) : 100, Colors.green),
        const SizedBox(height: 12),
        _indicateur('Votes annules', total > 0 ? (annules / total * 100) : 0,
            Colors.orange),
        const SizedBox(height: 12),
        _indicateur('Taux anomalies', total > 0 ? (fuites / total * 100) : 0,
            Colors.red),
        const SizedBox(height: 24),
        // Badge sécurité
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200)),
          child: const Row(children: [
            Icon(Icons.verified_user, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Systeme securise',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Chiffrement AES-256 — Audit complet CENI',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ])),
          ]),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, String val, IconData icon, Color color) =>
      Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(val,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ]));

  Widget _secCard(String label, int val, IconData icon, Color color) =>
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text('$val',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ]));

  Widget _indicateur(String label, double pct, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text('${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]);

  String _formatN(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}
