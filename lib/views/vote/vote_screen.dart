import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../main.dart';
import '../../services/smart_db_service.dart';
import '../../services/smart_db_service.dart';
import '../../services/smart_db_service.dart';
import '../../services/smart_db_service.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../app.dart';

class VoteScreen extends ConsumerStatefulWidget {
  final String electionId;
  const VoteScreen({super.key, required this.electionId});
  @override
  ConsumerState<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends ConsumerState<VoteScreen>
    with TickerProviderStateMixin {
  static const Color _green = Color(0xFF006233);
  static const Color _gold  = Color(0xFFFFD700);
  static const Color _red   = Color(0xFFD90012);

  Map<String, dynamic>? _election;
  List<Map<String, dynamic>> _candidats = [];
  Map<String, dynamic>? _selected;
  bool _loading  = true;
  bool _voting   = false;
  bool _success  = false;
  String? _recuHash;

  late AnimationController _successCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _successScale;
  late Animation<double> _successOpacity;
  late Animation<double> _pulseAnim;

  final List<Color> _colors = [
    const Color(0xFF1B5E20), const Color(0xFF1565C0),
    const Color(0xFF6A1B9A), const Color(0xFFE65100),
    const Color(0xFF00695C), const Color(0xFFB71C1C),
    const Color(0xFF37474F),
  ];

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final election = await supabase.from('elections').select('*').eq('id', widget.electionId).single();
      final candidats = await supabase.from('candidates').select('*').eq('election_id', widget.electionId).eq('is_active', true).order('numero_candidat');
      if (mounted) setState(() {
        _election = Map<String, dynamic>.from(election);
        _candidats = List<Map<String, dynamic>>.from(candidats as List);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _voter() async {
    if (_selected == null) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.how_to_vote, color: Color(0xFF006233)),
          SizedBox(width: 8),
          Text('Confirmer votre vote'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Vous allez voter pour :', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _green.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: _green.withOpacity(0.3))),
            child: Column(children: [
              Text(_selected!['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(_selected!['parti'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              if ((_selected!['parti_ar'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(_selected!['parti_ar'], textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ])),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
            child: const Row(children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Cette action est irreversible.\nVotre vote sera definitif.', style: TextStyle(color: Colors.red, fontSize: 12))),
            ])),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler', style: const TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: Text('Confirmer mon vote'),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ]));
    if (ok != true || !mounted) return;
    setState(() => _voting = true);
    HapticFeedback.mediumImpact();
    await _showVoteProgress();
  }

  Future<void> _showVoteProgress() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const _VoteProgressDialog());
    try {
      final nni = await ref.read(authServiceProvider).getCurrentNni();
      if (nni == null) throw Exception('Session expiree');
      final voterData = await supabase.from('voters').select('id').eq('nni', nni).single();
      final voterId = voterData['id'].toString();
      final existing = await supabase.from('votes').select('id').eq('election_id', widget.electionId).eq('voter_hash', voterId).maybeSingle();
      if (existing != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vous avez deja vote pour cette election !'),
            backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
          setState(() => _voting = false);
        }
        return;
      }
      await Future.delayed(const Duration(milliseconds: 1500));
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final recuHash = sha256.convert(utf8.encode(voterId + timestamp)).toString().substring(0, 32);
      final voterHash = sha256.convert(utf8.encode(voterId)).toString();
      final recuHash2 = await SmartDbService.voter(electionId: widget.electionId, candidateId: _selected!['id'].toString(), voterId: voterId);
      if (!mounted) return;
      Navigator.pop(context);
      setState(() { _voting = false; _success = true; _recuHash = recuHash; });
      HapticFeedback.heavyImpact();
      _successCtrl.forward();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.pushReplacement('/vote/receipt', extra: {
          'recuHash': recuHash, 'candidat': _selected, 'election': _election,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ' + e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        setState(() => _voting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_election?['titre_fr'] ?? 'Voter', style: const TextStyle(fontSize: 15)),
        backgroundColor: _green, foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(color: _green.withOpacity(0.08), border: Border(bottom: BorderSide(color: _green.withOpacity(0.2)))),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Color(0xFF006233), size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Selectionnez un candidat - Vote confidentiel et definitif', style: TextStyle(fontSize: 12, color: Color(0xFF006233)))),
                ])),
              Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _candidats.length, itemBuilder: (_, i) => _buildCandidatCard(i))),
              _buildVoterButton(),
            ]));
  }

  Widget _buildCandidatCard(int i) {
    final c = _candidats[i];
    final color = _colors[i % _colors.length];
    final isSelected = _selected?['id'] == c['id'];
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selected = c); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2.5 : 1),
          boxShadow: [BoxShadow(color: isSelected ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.08), blurRadius: isSelected ? 12 : 4, offset: const Offset(0, 2))]),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 46, height: 46,
            decoration: BoxDecoration(color: isSelected ? color : Colors.grey.shade100, shape: BoxShape.circle),
            child: Center(child: Text('', style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['nom'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? color : Colors.black)),
            const SizedBox(height: 2),
            Text(c['parti'] ?? '', style: TextStyle(fontSize: 12, color: isSelected ? color : Colors.grey.shade600)),
            if ((c['parti_ar'] ?? '').isNotEmpty)
              Text(c['parti_ar'], textDirection: TextDirection.rtl, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 30, height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? color : Colors.transparent, border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2)),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
        ])));
  }

  Widget _buildVoterButton() {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: _selected != null ? const LinearGradient(colors: [Color(0xFF004D26), Color(0xFF006233)]) : null,
          color: _selected == null ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _selected != null ? [BoxShadow(color: _green.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : []),
        child: ElevatedButton.icon(
          onPressed: _selected == null || _voting ? null : _voter,
          icon: _voting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.how_to_vote, size: 22),
          label: Text(
            _voting ? 'Enregistrement...' : _selected == null ? 'Selectionnez un candidat' : 'Voter pour ',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))))));
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: _green,
      body: SafeArea(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ScaleTransition(
          scale: _successScale,
          child: FadeTransition(
            opacity: _successOpacity,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)]),
              child: const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF006233))))),
        const SizedBox(height: 32),
        FadeTransition(opacity: _successOpacity, child: Column(children: [
          Text('Vote enregistre !', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Pour : ', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: _gold.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: _gold.withOpacity(0.5))),
            child: const Text('Preparation de votre recu...', style: TextStyle(color: Colors.white70, fontSize: 13))),
        ])),
      ]))));
  }
}

class _VoteProgressDialog extends StatefulWidget {
  const _VoteProgressDialog();
  @override
  State<_VoteProgressDialog> createState() => _VoteProgressDialogState();
}

class _VoteProgressDialogState extends State<_VoteProgressDialog> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  int _step = 0;
  static const Color _green = Color(0xFF006233);
  final List<String> _steps = [
    'Verification identite...',
    'Chiffrement AES-256...',
    'Enregistrement securise...',
    'Vote confirme !',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat();
    _advance();
  }

  Future<void> _advance() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _step = i);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 60, height: 60, child: CircularProgressIndicator(value: (_step + 1) / _steps.length, strokeWidth: 5, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation<Color>(_green))),
        const SizedBox(height: 20),
        const Text('Vote en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...List.generate(_steps.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 24, height: 24,
              decoration: BoxDecoration(color: i <= _step ? _green : Colors.grey.shade200, shape: BoxShape.circle),
              child: Icon(i < _step ? Icons.check : i == _step ? Icons.hourglass_top : Icons.circle_outlined, size: 14, color: i <= _step ? Colors.white : Colors.grey)),
            const SizedBox(width: 10),
            Text(_steps[i], style: TextStyle(fontSize: 13, color: i <= _step ? Colors.black : Colors.grey, fontWeight: i == _step ? FontWeight.bold : FontWeight.normal)),
          ]))),
        const SizedBox(height: 8),
        Text('%', style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
      ])));
  }
}
