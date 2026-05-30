import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../utils/app_theme.dart';

class ResultatsScreen extends ConsumerStatefulWidget {
  final String? electionId;
  const ResultatsScreen({super.key, this.electionId});
  @override
  ConsumerState<ResultatsScreen> createState() => _ResultatsScreenState();
}

class _ResultatsScreenState extends ConsumerState<ResultatsScreen> {
  Map<String, dynamic>? _election;
  List<Map<String, dynamic>> _candidats = [];
  bool _loading = true;
  int _touchedIndex = -1;

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
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final electionId = widget.electionId;
      Map<String, dynamic> election;
      if (electionId != null) {
        final data = await supabase
            .from('elections')
            .select('*')
            .eq('id', electionId)
            .single();
        election = Map<String, dynamic>.from(data);
      } else {
        final data = await supabase
            .from('elections')
            .select('*')
            .order('created_at', ascending: false)
            .limit(1)
            .single();
        election = Map<String, dynamic>.from(data);
      }
      final candidatsData = await supabase
          .from('candidates')
          .select('*')
          .eq('election_id', election['id'])
          .eq('is_active', true)
          .order('nb_voix', ascending: false);
      if (mounted)
        setState(() {
          _election = election;
          _candidats = List<Map<String, dynamic>>.from(candidatsData as List);
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalVoix =>
      _candidats.fold(0, (sum, c) => sum + (c['nb_voix'] as int? ?? 0));

  double _pourcentage(Map<String, dynamic> c) {
    final total = _totalVoix;
    if (total == 0) return 0;
    return (c['nb_voix'] as int? ?? 0) / total * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(_election?['titre_fr'] ?? 'Resultats',
            style: const TextStyle(fontSize: 16)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _candidats.isEmpty
              ? const Center(child: Text('Aucun resultat disponible'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _buildStats(),
                    const SizedBox(height: 24),
                    _buildPieChart(),
                    const SizedBox(height: 24),
                    _buildBarres(),
                    const SizedBox(height: 24),
                    _buildTableau(),
                  ])),
    );
  }

  Widget _buildStats() {
    final total = _totalVoix;
    final gagnant = _candidats.isNotEmpty
        ? _candidats
            .reduce((a, b) => (a['nb_voix'] ?? 0) > (b['nb_voix'] ?? 0) ? a : b)
        : null;
    return Row(children: [
      Expanded(
          child: _statCard('Total votes', _formatNombre(total),
              Icons.how_to_vote, AppTheme.primaryGreen)),
      const SizedBox(width: 12),
      Expanded(
          child: _statCard('Candidats', '${_candidats.length}', Icons.person,
              const Color(0xFF1565C0))),
      const SizedBox(width: 12),
      Expanded(
          child: _statCard(
              'Vainqueur',
              gagnant != null
                  ? _pourcentage(gagnant).toStringAsFixed(1) + '%'
                  : '-',
              Icons.emoji_events,
              const Color(0xFFFFB300))),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ]));

  Widget _buildPieChart() {
    return Column(children: [
      const Text('Repartition des votes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(touchCallback: (_, pieTouchResponse) {
                setState(() {
                  if (pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: List.generate(_candidats.length, (i) {
                final isTouched = i == _touchedIndex;
                final pct = _pourcentage(_candidats[i]);
                final color = _colors[i % _colors.length];
                return PieChartSectionData(
                  color: color,
                  value: pct,
                  title: pct > 5 ? '${pct.toStringAsFixed(1)}%' : '',
                  radius: isTouched ? 80 : 70,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }),
            ),
          )),
      const SizedBox(height: 12),
      Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(_candidats.length, (i) {
            final c = _candidats[i];
            final color = _colors[i % _colors.length];
            final nom = (c['nom'] ?? '').toString();
            final nomCourt =
                nom.length > 20 ? nom.substring(0, 20) + '...' : nom;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(nomCourt, style: const TextStyle(fontSize: 11)),
            ]);
          })),
    ]);
  }

  Widget _buildBarres() {
    return Column(children: [
      const Text('Resultats par candidat',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...List.generate(_candidats.length, (i) {
        final c = _candidats[i];
        final pct = _pourcentage(c);
        final color = _colors[i % _colors.length];
        final nom = (c['nom'] ?? '').toString();
        final isGagnant = i == 0 &&
            _candidats.length > 1 &&
            (c['nb_voix'] ?? 0) > (_candidats[1]['nb_voix'] ?? 0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 28,
                  height: 28,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Center(
                      child: Text('${c['numero_candidat'] ?? i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)))),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(nom,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13),
                      overflow: TextOverflow.ellipsis)),
              if (isGagnant)
                const Icon(Icons.emoji_events,
                    color: Color(0xFFFFB300), size: 18),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
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
                child: Text(_formatNombre(c['nb_voix'] as int? ?? 0),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary))),
          ]),
        );
      }),
    ]);
  }

  Widget _buildTableau() {
    return Column(children: [
      const Text('Tableau des resultats',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
        columnWidths: const {
          0: FlexColumnWidth(0.5),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppTheme.primaryGreen),
            children: ['N�', 'Candidat', 'Parti', '%']
                .map((h) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(h,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                        textAlign: TextAlign.center)))
                .toList(),
          ),
          ...List.generate(_candidats.length, (i) {
            final c = _candidats[i];
            final pct = _pourcentage(c);
            final bgColor = i == 0 ? const Color(0xFFE8F5E9) : Colors.white;
            return TableRow(
              decoration: BoxDecoration(color: bgColor),
              children: [
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${c['numero_candidat'] ?? i + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12))),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(c['nom'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500))),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(c['parti'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary))),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${pct.toStringAsFixed(2)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _colors[i % _colors.length]))),
              ],
            );
          }),
        ],
      ),
      const SizedBox(height: 8),
      Text('Total: ${_formatNombre(_totalVoix)} voix � Taux: 55.39%',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]);
  }

  String _formatNombre(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
