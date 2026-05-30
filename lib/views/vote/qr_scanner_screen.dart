import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../main.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  static const Color _green = Color(0xFF006233);
  static const Color _gold  = Color(0xFFFFD700);
  
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _verifierHash(String hash) async {
    if (_scanned) return;
    setState(() { _scanned = true; _loading = true; });
    _ctrl.stop();
    try {
      final vote = await supabase
          .from('votes')
          .select('recu_hash, is_valid, timestamp_vote, elections(titre_fr), candidates(nom)')
          .eq('recu_hash', hash)
          .maybeSingle();
      if (mounted) setState(() {
        _loading = false;
        _result = vote != null ? Map<String, dynamic>.from(vote) : null;
        _error = vote == null ? 'Recu introuvable — code invalide ou falsifie' : null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Erreur: ' + e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Verifier Recu de Vote'),
        backgroundColor: _green, foregroundColor: Colors.white,
        actions: [
          if (_scanned) IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() { _scanned = false; _result = null; _error = null; _ctrl.start(); }))
        ]),
      body: _scanned ? _buildResult() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(children: [
      MobileScanner(
        controller: _ctrl,
        onDetect: (capture) {
          final barcode = capture.barcodes.firstOrNull;
          if (barcode?.rawValue != null) _verifierHash(barcode!.rawValue!);
        }),
      Center(child: Container(
        width: 250, height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: _gold, width: 3),
          borderRadius: BorderRadius.circular(12)))),
      Positioned(bottom: 40, left: 0, right: 0,
        child: const Text('Pointez vers le QR Code du recu de vote',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 14))),
    ]);
  }

  Widget _buildResult() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006233)));
    if (_error != null) return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cancel, color: Colors.red, size: 80),
        const SizedBox(height: 20),
        const Text('RECU INVALIDE', style: TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() { _scanned = false; _error = null; _ctrl.start(); }),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
          child: const Text('Scanner a nouveau')),
      ])));

    final vote = _result!;
    final election = vote['elections'];
    final candidate = vote['candidates'];
    final date = (vote['timestamp_vote'] ?? '').toString();
    final dateStr = date.length >= 10 ? date.substring(0, 10) : '';
    final isValid = vote['is_valid'] == true;

    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isValid ? Icons.verified : Icons.warning,
          color: isValid ? Colors.green : Colors.orange, size: 80),
        const SizedBox(height: 16),
        Text(isValid ? 'RECU VALIDE' : 'RECU ANNULE',
          style: TextStyle(
            color: isValid ? Colors.green : Colors.orange,
            fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isValid ? Colors.green : Colors.orange)),
          child: Column(children: [
            _infoRow('Election', election?['titre_fr'] ?? '-'),
            _infoRow('Candidat', candidate?['nom'] ?? 'Confidentiel'),
            _infoRow('Date', dateStr),
            _infoRow('Statut', isValid ? 'Vote comptabilise' : 'Vote annule'),
            _infoRow('Hash', (vote['recu_hash'] ?? '').toString().substring(0, 16) + '...'),
          ])),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () => setState(() { _scanned = false; _result = null; _ctrl.start(); }),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scanner un autre recu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48))),
      ])));
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label + ' : ', style: const TextStyle(color: Colors.white60, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
    ]));
}