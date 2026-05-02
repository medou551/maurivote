import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/app_theme.dart';

class VoteReceiptScreen extends ConsumerWidget {
  final String? recuHash;
  const VoteReceiptScreen({super.key, this.recuHash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recuHash == null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            const Text('Reçu invalide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Retour')),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 16),

            // ── Animation de succès ──────────────────────────────────────
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                color: AppTheme.lightGreen, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 64, color: AppTheme.primaryGreen),
            )
                .animate()
                .scale(begin: const Offset(0, 0), end: const Offset(1, 1),
                    duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            const Text('Vote enregistré !',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen))
                .animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),
            const Text(
              'Votre vote a été chiffré et enregistré de manière sécurisée.\n'
              'Conservez ce reçu pour vérifier votre participation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 32),

            // ── QR Code ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                    blurRadius: 20, offset: const Offset(0, 6))],
                border: Border.all(color: AppTheme.lightGreen, width: 2),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.qr_code_2, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text('Code de vérification',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                          color: AppTheme.primaryGreen)),
                ]),
                const SizedBox(height: 16),
                QrImageView(
                  data: 'maurivote://verify/$recuHash',
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: AppTheme.primaryGreen),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 16),
                // Hash tronqué
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${recuHash!.substring(0, 16)}...${recuHash!.substring(recuHash!.length - 8)}',
                    style: const TextStyle(fontFamily: 'Courier New', fontSize: 13,
                        color: AppTheme.textSecondary, letterSpacing: 1),
                  ),
                ),
              ]),
            ).animate().fadeIn(delay: 700.ms).scale(
                begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

            const SizedBox(height: 24),

            // ── Info anonymat ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGreen),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.primaryGreen, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Votre anonymat est préservé',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                              color: AppTheme.primaryGreen)),
                      SizedBox(height: 4),
                      Text(
                        'Ce QR Code confirme que vous avez voté, '
                        'sans révéler votre choix. Seul vous pouvez vérifier '
                        'votre participation en scannant ce code.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ]),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 900.ms),

            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: recuHash!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hash copié !'),
                          behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Share.share(
                    'Mon reçu de vote MauriVote :\n\n$recuHash\n\n'
                    'Vérifiez sur : https://maurivote.mr/verify',
                    subject: 'Reçu MauriVote',
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Partager'),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour à l\'accueil'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 32),

            // ── Horodatage ────────────────────────────────────────────────
            Text(
              'Vote enregistré le ${_formatNow()}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Commission Électorale Nationale Indépendante\nRépublique Islamique de Mauritanie',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatNow() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2,'0')}/${n.month.toString().padLeft(2,'0')}/${n.year} '
        'à ${n.hour.toString().padLeft(2,'0')}h${n.minute.toString().padLeft(2,'0')}';
  }
}
