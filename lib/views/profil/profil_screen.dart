import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../viewmodels/auth_viewmodel.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROFIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voterAsync = ref.watch(currentVoterProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Déconnexion',
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: voterAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => _buildError(context, ref),
        data: (voter) => voter == null
            ? _buildError(context, ref)
            : _ProfilBody(voter: voter),
      ),
    );
  }

  Widget _buildShimmer() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade50,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const CircleAvatar(radius: 48, backgroundColor: Colors.white),
        const SizedBox(height: 16),
        ...List.generate(5, (_) => Container(
          height: 60, margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        )),
      ]),
    ),
  );

  Widget _buildError(BuildContext ctx, WidgetRef ref) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
      const SizedBox(height: 12),
      const Text('Impossible de charger le profil'),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => ref.invalidate(currentVoterProvider),
        child: const Text('Réessayer'),
      ),
    ]),
  );

  Future<void> _confirmSignOut(BuildContext ctx, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter de MauriVote ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      await ref.read(authStateProvider.notifier).signOut();
      if (ctx.mounted) ctx.go('/login');
    }
  }
}

class _ProfilBody extends StatelessWidget {
  final Voter voter;
  const _ProfilBody({required this.voter});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // ── Avatar ────────────────────────────────────────────────────────
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.lightGreen,
          child: Text(voter.prenom[0].toUpperCase(),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen)),
        ),
        const SizedBox(height: 12),
        Text(voter.nomComplet,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(voter.nniMasque,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary,
                letterSpacing: 2)),
        const SizedBox(height: 4),
        // Badge vérifié
        if (voter.isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified, size: 14, color: AppTheme.primaryGreen),
              SizedBox(width: 4),
              Text('Électeur vérifié', style: TextStyle(fontSize: 12,
                  color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
            ]),
          ),
        const SizedBox(height: 24),

        // ── Informations personnelles ──────────────────────────────────────
        _Section(
          title: 'Informations personnelles',
          children: [
            _InfoTile(Icons.badge_outlined, 'NNI', voter.nniMasque),
            _InfoTile(Icons.cake_outlined, 'Date de naissance',
                _formatDate(voter.dateNaissance)),
            _InfoTile(Icons.person_outline, 'Sexe',
                voter.sexe == 'M' ? 'Masculin' : 'Féminin'),
            _InfoTile(Icons.phone_outlined, 'Téléphone',
                _maskPhone(voter.telephone)),
          ],
        ),
        const SizedBox(height: 16),

        // ── Informations électorales ────────────────────────────────────────
        _Section(
          title: 'Informations électorales',
          children: [
            _InfoTile(Icons.location_city_outlined, 'Commune', 'Tevragh-Zeina'),
            _InfoTile(Icons.map_outlined, 'Wilaya', 'Nouakchott Ouest'),
            _ActionTile(
              icon: Icons.place_outlined,
              label: 'Mon bureau de vote',
              value: 'Voir sur la carte',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const BureauVoteScreen())),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Paramètres ─────────────────────────────────────────────────────
        _Section(
          title: 'Paramètres',
          children: [
            _ActionTile(
              icon: Icons.language_outlined,
              label: 'Langue',
              value: 'Français',
              onTap: () {/* Sprint 3 */},
            ),
            _ActionTile(
              icon: Icons.help_outline,
              label: 'Aide & Contact CENI',
              value: AppConstants.ceniPhone,
              onTap: () => launchUrl(Uri.parse('tel:${AppConstants.ceniPhone}')),
            ),
            _ActionTile(
              icon: Icons.open_in_new_outlined,
              label: 'Site CENI',
              value: 'myceni.org',
              onTap: () => launchUrl(Uri.parse(AppConstants.ceniWebsite)),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── Version ────────────────────────────────────────────────────────
        const Text('MauriVote v1.0.0 — © 2026 CENI Mauritanie',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  String _maskPhone(String p) =>
      p.length > 6 ? '${p.substring(0, p.length - 4)}****' : p;
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: children),
      ),
    ],
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
    title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    dense: true,
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
      required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
    title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
        color: AppTheme.primaryGreen)),
    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
    onTap: onTap,
    dense: true,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// BUREAU VOTE SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class BureauVoteScreen extends StatelessWidget {
  const BureauVoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Bureau de Vote'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Placeholder carte (Google Maps — Sprint 2 J12)
          Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.map_outlined, size: 64, color: AppTheme.textSecondary),
                SizedBox(height: 8),
                Text('Carte Google Maps', style: TextStyle(color: AppTheme.textSecondary)),
                Text('(Intégration Sprint 2 — J12)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ),
          ),

          // Infos bureau
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Votre bureau de vote assigné',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 8)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('École Tevragh-Zeina A',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Rue des Ambassades, Tevragh-Zeina',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    const Text('Horaires : 07h00 — 19h00',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Accessible PMR',
                          style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://maps.google.com/?q=18.0735,-15.9582')),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Itinéraire Google Maps'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
