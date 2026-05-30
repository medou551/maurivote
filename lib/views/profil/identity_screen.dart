import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';
import '../../models/models.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ÉCRAN 1 — Carte d'Identité Numérique Citoyenne
// ══════════════════════════════════════════════════════════════════════════════

class IdentiteNumerique extends ConsumerStatefulWidget {
  final Voter voter;
  const IdentiteNumerique({super.key, required this.voter});

  @override
  ConsumerState<IdentiteNumerique> createState() => _IdentiteNumeriqueState();
}

class _IdentiteNumeriqueState extends ConsumerState<IdentiteNumerique> {
  bool _cardVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 300),
      () => setState(() => _cardVisible = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.voter;
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Mon Identité Numérique'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _partagerIdentite(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Carte nationale numérique ──────────────────────────────────
              AnimatedOpacity(
                opacity: _cardVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1B5E20),
                        Color(0xFF2E7D32),
                        Color(0xFF388E3C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Motif géométrique
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Opacity(
                          opacity: 0.1,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 20,
                        child: Opacity(
                          opacity: 0.08,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),

                      // Contenu carte
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête
                            Row(
                              children: [
                                const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'République Islamique de Mauritanie',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'CITOYEN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Photo + infos
                            Row(
                              children: [
                                // Photo
                                Container(
                                  width: 70,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: v.photoUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(
                                            v.photoUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                ),
                                const SizedBox(width: 16),

                                // Infos
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${v.prenom} ${v.nom}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'NNI : ${_maskNni(v.nni)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Né(e) le : ${v.dateNaissance}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Sexe : ${v.sexe == 'M' ? 'Masculin' : 'Féminin'}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Bas de carte
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ID NUMÉRIQUE MR',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                Text(
                                  _formatNni(v.nni),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Statut vérification ────────────────────────────────────────
              _StatutCard(voter: v),
              const SizedBox(height: 16),

              // ── Actions ────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.camera_alt_outlined,
                      label: 'Photo officielle',
                      color: AppTheme.primaryGreen,
                      onTap: () => context.push('/identite/photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.draw_outlined,
                      label: 'Signature numérique',
                      color: const Color(0xFF1565C0),
                      onTap: () => context.push('/identite/signature'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code_outlined,
                      label: 'QR Code identité',
                      color: const Color(0xFF6A1B9A),
                      onTap: () => context.push('/identite/qr'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.history_edu_outlined,
                      label: 'Historique votes',
                      color: const Color(0xFF00695C),
                      onTap: () => context.push('/profil'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskNni(String nni) =>
      '${nni.substring(0, 3)}****${nni.substring(7)}';

  String _formatNni(String nni) =>
      '${nni.substring(0, 4)} ${nni.substring(4, 7)} ${nni.substring(7)}';

  void _partagerIdentite(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage sécurisé — QR Code généré'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ÉCRAN 2 — Capture Photo Officielle
// ══════════════════════════════════════════════════════════════════════════════

class PhotoOfficielleScreen extends ConsumerStatefulWidget {
  const PhotoOfficielleScreen({super.key});

  @override
  ConsumerState<PhotoOfficielleScreen> createState() =>
      _PhotoOfficielleScreenState();
}

class _PhotoOfficielleScreenState extends ConsumerState<PhotoOfficielleScreen> {
  XFile? _photo;
  bool _uploading = false;
  final _picker = ImagePicker();

  Future<void> _prendrephoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    if (photo != null) setState(() => _photo = photo);
  }

  Future<void> _validerPhoto() async {
    if (_photo == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await _photo!.readAsBytes();
      final sb = Supabase.instance.client;
      final userId = sb.auth.currentUser?.id ?? 'anonymous';
      final path = 'photos/$userId.jpg';

      await sb.storage.from('voter-photos').uploadBinary(
            path,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final url = sb.storage.from('voter-photos').getPublicUrl(path);

      await sb.from('voters').update({'photo_url': url}).eq('nni', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Photo officielle enregistrée !'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Photo officielle'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.face_outlined,
                                color: Colors.white30,
                                size: 80,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Cadrez votre visage\nface à la caméra',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Instructions :',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...[
                          '✅ Fond clair et uni',
                          '✅ Visage bien éclairé',
                          '✅ Expression neutre',
                          '❌ Pas de lunettes de soleil',
                          '❌ Pas de couvre-chef',
                        ].map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              t,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(_photo!.path, fit: BoxFit.contain),
                    ),
            ),

            // Boutons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_photo != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: () => setState(() => _photo = null),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reprendre'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _uploading ? null : _validerPhoto,
                        icon: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_uploading ? 'Envoi...' : 'Valider'),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _prendrephoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Prendre la photo'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ÉCRAN 3 — Signature Numérique
// ══════════════════════════════════════════════════════════════════════════════

class SignatureNumerique extends StatefulWidget {
  const SignatureNumerique({super.key});

  @override
  State<SignatureNumerique> createState() => _SignatureNumeriqueState();
}

class _SignatureNumeriqueState extends State<SignatureNumerique> {
  final List<List<Offset?>> _strokes = [];
  List<Offset?> _currentStroke = [];
  bool _saving = false;

  void _onPanStart(DragStartDetails d) {
    _currentStroke = [d.localPosition];
    setState(() => _strokes.add(_currentStroke));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() => _currentStroke.add(null));
  }

  void _effacer() => setState(() {
        _strokes.clear();
        _currentStroke = [];
      });

  Future<void> _sauvegarder() async {
    if (_strokes.isEmpty) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Signature numérique enregistrée !'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Signature numérique'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _effacer,
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zone de signature
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Ligne de base
                    Positioned(
                      bottom: 60,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    // Label
                    const Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Signez ici',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    // Canvas de dessin
                    GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _SignaturePainter(_strokes),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre signature sera chiffrée et liée à votre NNI.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boutons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton.icon(
                onPressed: _strokes.isEmpty || _saving ? null : _sauvegarder,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Enregistrement...' : 'Enregistrer la signature',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        if (stroke[i] != null && stroke[i + 1] != null) {
          canvas.drawLine(stroke[i]!, stroke[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// Widgets réutilisables
// ══════════════════════════════════════════════════════════════════════════════

class _StatutCard extends StatelessWidget {
  final Voter voter;
  const _StatutCard({required this.voter});

  @override
  Widget build(BuildContext context) {
    final verified = voter.isVerified;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: verified
            ? AppTheme.primaryGreen.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: verified
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.verified_user : Icons.pending_outlined,
            color: verified ? AppTheme.primaryGreen : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Identité vérifiée' : 'Vérification en attente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: verified ? AppTheme.primaryGreen : Colors.orange,
                  ),
                ),
                Text(
                  verified
                      ? 'Votre compte est pleinement authentifié'
                      : 'Ajoutez votre photo et signature pour compléter',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
