import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../main.dart';
import '../../utils/app_theme.dart';

class VoteReceiptScreen extends ConsumerStatefulWidget {
  final String? recuHash;
  const VoteReceiptScreen({super.key, this.recuHash});
  @override
  ConsumerState<VoteReceiptScreen> createState() => _VoteReceiptScreenState();
}

class _VoteReceiptScreenState extends ConsumerState<VoteReceiptScreen>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF006233);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _red = Color(0xFFD90012);

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Map<String, dynamic>? _candidat;
  Map<String, dynamic>? _election;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      // Trouver le vote par recu_hash
      if (widget.recuHash != null) {
        final voteData = await supabase
            .from('votes')
            .select('*, candidates(*), elections(*)')
            .eq('recu_hash', widget.recuHash!)
            .maybeSingle();

        if (voteData != null) {
          _candidat = voteData['candidates'] != null
              ? Map<String, dynamic>.from(voteData['candidates'])
              : null;
          _election = voteData['elections'] != null
              ? Map<String, dynamic>.from(voteData['elections'])
              : null;
        }
      }

      // Stats résultats pour contribution
      if (_election != null) {
        final candidats = await supabase
            .from('candidates')
            .select('nb_voix')
            .eq('election_id', _election!['id'])
            .eq('is_active', true);

        final totalVoix = (candidats as List)
            .fold<int>(0, (sum, c) => sum + (c['nb_voix'] as int? ?? 0));

        final candVoix = _candidat?['nb_voix'] as int? ?? 0;
        final pct = totalVoix > 0 ? candVoix / totalVoix * 100 : 0.0;

        setState(() {
          _stats = {
            'total_voix': totalVoix,
            'candidat_voix': candVoix,
            'pourcentage': pct,
          };
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _formatDate() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '$d/$m/${now.year} à $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final hash =
        widget.recuHash ?? 'MAURIVOTE-${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: _green,
      appBar: AppBar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text('Reçu de Vote', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home, color: Colors.white, size: 18),
                label: const Text('Accueil',
                    style: TextStyle(color: Colors.white))),
          ]),
      body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                  child: Column(children: [
                // Header succès
                Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(children: [
                      Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 3)
                              ]),
                          child: const Icon(Icons.check_circle_rounded,
                              size: 48, color: Color(0xFF006233))),
                      const SizedBox(height: 16),
                      const Text('Vote Enregistré !',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Votre vote a été comptabilisé avec succès',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                              color: _gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _gold.withOpacity(0.4))),
                          child: Text(_formatDate(),
                              style:
                                  const TextStyle(color: _gold, fontSize: 12))),
                    ])),

                // Carte reçu
                Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8))
                        ]),
                    child: Column(children: [
                      // Bandeau vert/rouge drapeau
                      Container(
                          height: 6,
                          decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24)),
                              gradient: LinearGradient(colors: [
                                Color(0xFFD90012),
                                Color(0xFF006233),
                                Color(0xFFD90012)
                              ]))),

                      Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(children: [
                            // Candidat voté
                            if (_candidat != null) ...[
                              const Text('Candidat choisi',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: _green.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: _green.withOpacity(0.2))),
                                  child: Row(children: [
                                    Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                            color: _green,
                                            shape: BoxShape.circle),
                                        child: Center(
                                            child: Text(
                                                '${_candidat!['numero_candidat'] ?? ''}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(_candidat!['nom'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          Text(_candidat!['parti'] ?? '',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12)),
                                        ])),
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF006233), size: 24),
                                  ])),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                            ],

                            // QR Code
                            const Text('Code de vérification',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text(
                                'Conservez ce QR Code — Il prouve votre participation',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 11),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(12)),
                                child: QrImageView(
                                    data: 'MAURIVOTE:$hash',
                                    version: QrVersions.auto,
                                    size: 160,
                                    backgroundColor: Colors.white)),
                            const SizedBox(height: 12),

                            // Hash
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.grey.shade200)),
                                child: Row(children: [
                                  Expanded(
                                      child: Text(
                                          hash.length > 30
                                              ? hash.substring(0, 30) + '...'
                                              : hash,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                              color: Colors.grey))),
                                  GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                            ClipboardData(text: hash));
                                        HapticFeedback.lightImpact();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text('Hash copié !'),
                                                backgroundColor:
                                                    Color(0xFF006233),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                duration:
                                                    Duration(seconds: 2)));
                                      },
                                      child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                              color: _green.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: const Icon(Icons.copy,
                                              size: 16,
                                              color: Color(0xFF006233)))),
                                ])),

                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Stats contribution
                            if (!_loading && _stats.isNotEmpty) ...[
                              const Text('Contribution élection',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: _statBox(
                                        'Total voix',
                                        _formatN(_stats['total_voix'] ?? 0),
                                        Icons.how_to_vote,
                                        _green)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _statBox(
                                        'Voix candidat',
                                        _formatN(_stats['candidat_voix'] ?? 0),
                                        Icons.person,
                                        const Color(0xFF1565C0))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _statBox(
                                        'Position',
                                        '${(_stats['pourcentage'] as double? ?? 0.0).toStringAsFixed(1)}%',
                                        Icons.percent,
                                        const Color(0xFF6A1B9A))),
                              ]),
                              const SizedBox(height: 16),
                            ],

                            // Infos vote
                            _infoRow(Icons.calendar_today_outlined, 'Date',
                                _formatDate()),
                            _infoRow(Icons.verified_outlined, 'Statut',
                                'Vote valide ✓'),
                            _infoRow(
                                Icons.lock_outlined, 'Chiffrement', 'AES-256'),
                            _infoRow(
                                Icons.how_to_vote_outlined,
                                'Election',
                                _election?['titre_fr'] ??
                                    'Présidentielle 2024'),

                            const SizedBox(height: 16),

                            // Avertissement confidentialité
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.orange.shade200)),
                                child: const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.security,
                                          color: Colors.orange, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                          child: Text(
                                              'Votre vote est confidentiel. Ce reçu prouve votre participation sans révéler votre choix.',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange))),
                                    ])),

                            // Bandeau bas drapeau
                            const SizedBox(height: 16),
                            Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                  Color(0xFFD90012),
                                  Color(0xFF006233),
                                  Color(0xFFD90012)
                                ]))),
                          ])),
                    ])),

                const SizedBox(height: 20),

                // Boutons action
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      ElevatedButton.icon(
                          onPressed: () => context
                              .go('/resultats/${_election?['id'] ?? ''}'),
                          icon: const Icon(Icons.bar_chart),
                          label: const Text('Voir les résultats complets'),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: Colors.white,
                              foregroundColor: _green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)))),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Retour à l\'accueil'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)))),
                    ])),

                const SizedBox(height: 20),

                // CENI badge
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.verified, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  const Text('CENI — République Islamique de Mauritanie',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
                const SizedBox(height: 24),
              ])))),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) =>
      Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center),
          ]));

  Widget _infoRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ]));

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
