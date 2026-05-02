import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/elections_viewmodel.dart';

/// Interface Administration CENI — Sprint 3 J19
/// Accès restreint au rôle ceni_admin
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _State();
}

class _State extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        title: const Text('Administration CENI',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(electionsProvider)),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await ref.read(authStateProvider.notifier).signOut();
            if (mounted) context.go('/login');
          }),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.primaryGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Général'),
            Tab(icon: Icon(Icons.ballot_outlined, size: 18), text: 'Élections'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Électeurs'),
            Tab(icon: Icon(Icons.security_outlined, size: 18), text: 'Sécurité'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _OverviewTab(),
        _ElectionsTab(),
        _VotersTab(),
        _SecurityTab(),
      ]),
    );
  }
}

// ── VUE GÉNÉRALE ──────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electAsync = ref.watch(electionsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats
        Row(children: [
          Expanded(child: _StatCard('Électeurs inscrits', '1.9M', Icons.people_outline, Colors.blue)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard('Bureaux', '3 847', Icons.location_on_outlined, Colors.orange)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard('Wilayas', '15', Icons.map_outlined, const Color(0xFF4A148C))),
          const SizedBox(width: 10),
          Expanded(child: _StatCard('Communes', '221', Icons.location_city_outlined, Colors.teal)),
        ]),
        const SizedBox(height: 20),
        // Élections actives
        const Text('Élections en cours', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        electAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Erreur: $e'),
          data: (elections) {
            final active = elections.where((e) => e.isActive).toList();
            if (active.isEmpty) return const _EmptyCard('Aucune élection en cours');
            return Column(children: active.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200)),
              child: Row(children: [
                const Icon(Icons.circle, color: Colors.green, size: 10),
                const SizedBox(width: 8),
                Expanded(child: Text(e.titreFr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Text('Tour ${e.tourActuel}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            )).toList());
          },
        ),
        const SizedBox(height: 20),
        // Actions rapides
        const Text('Actions rapides', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _QuickAction(Icons.add_circle_outline, 'Créer élection', const Color(0xFF4A148C)),
          _QuickAction(Icons.campaign_outlined, 'Notifier', Colors.orange),
          _QuickAction(Icons.download_outlined, 'Exporter', Colors.teal),
          _QuickAction(Icons.analytics_outlined, 'Rapport', Colors.blue),
        ]),
      ]),
    );
  }
}

// ── ÉLECTIONS ────────────────────────────────────────────────────────────────
class _ElectionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electAsync = ref.watch(electionsProvider);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add), label: const Text('Créer une élection'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A148C)),
        ),
      ),
      Expanded(child: electAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (elections) => elections.isEmpty
            ? const _EmptyCard('Aucune élection')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: elections.length,
                itemBuilder: (_, i) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.ballot_outlined, color: Color(0xFF4A148C)),
                    title: Text(elections[i].titreFr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${elections[i].typeLabel} · Tour ${elections[i].tourActuel}/${elections[i].nbTours}'),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(value: 'open', child: Text('Ouvrir le vote')),
                        PopupMenuItem(value: 'close', child: Text('Fermer le vote')),
                        PopupMenuItem(value: 'results', child: Text('Valider résultats')),
                      ],
                      onSelected: (_) {},
                    ),
                  ),
                ),
              ),
      )),
    ]);
  }

  void _showCreateDialog(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('Créer une élection'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const TextField(decoration: InputDecoration(labelText: 'Titre (FR)', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        const TextField(decoration: InputDecoration(labelText: 'العنوان (AR)', border: OutlineInputBorder()),
            textDirection: TextDirection.rtl),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(onPressed: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('Élection créée'), behavior: SnackBarBehavior.floating));
        }, child: const Text('Créer')),
      ],
    ),
  );
}

// ── ÉLECTEURS ────────────────────────────────────────────────────────────────
class _VotersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16), children: [
    const TextField(decoration: InputDecoration(labelText: 'Rechercher par NNI',
        prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
        keyboardType: TextInputType.number, maxLength: 10),
    const SizedBox(height: 16),
    ...[
      ('Total inscrits', '1 939 341', Colors.blue),
      ('Vérifiés biométrie', '1 284 521 (66.2%)', Colors.green),
      ('Comptes suspendus', '234', Colors.red),
      ('Diaspora inscrits', '29 371', Colors.orange),
    ].map((e) => ListTile(dense: true,
        leading: Icon(Icons.circle, color: e.$3, size: 10),
        title: Text(e.$1, style: const TextStyle(fontSize: 13)),
        trailing: Text(e.$2, style: TextStyle(fontWeight: FontWeight.bold,
            color: e.$3, fontSize: 13)))),
    const SizedBox(height: 12),
    ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_file),
        label: const Text('Importer liste RAVEL (CSV)'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue)),
  ]);
}

// ── SÉCURITÉ ─────────────────────────────────────────────────────────────────
class _SecurityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16), children: [
    const Text('Journal d\'audit (24h)',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    ...[
      ('login', 'Connexion réussie', '10:23', true),
      ('vote', 'Vote soumis et chiffré', '10:24', true),
      ('vote_fail', 'Double vote BLOQUÉ', '10:24', false),
      ('rls_violation', 'Tentative /votes refusée', '10:31', false),
      ('otp_verified', 'OTP vérifié', '10:45', true),
    ].map((e) => ListTile(
        dense: true,
        leading: CircleAvatar(radius: 14,
            backgroundColor: (e.$4 ? Colors.green : Colors.red).withOpacity(0.1),
            child: Icon(e.$4 ? Icons.check : Icons.warning_amber, size: 14,
                color: e.$4 ? Colors.green : Colors.red)),
        title: Text(e.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(e.$2, style: const TextStyle(fontSize: 11)),
        trailing: Text(e.$3, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)))),
    const SizedBox(height: 16),
    const Text('Alertes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    _alertCard('⚠️ 2 tentatives double vote bloquées ce matin', Colors.orange),
    _alertCard('✅ Aucune violation critique — Score A-', Colors.green),
    _alertCard('🔐 Certificate Pinning : ACTIF', Colors.blue),
    _alertCard('🔒 RLS sur toutes les tables : ACTIF', Colors.blue),
  ]);

  Widget _alertCard(String msg, Color c) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.3))),
    child: Text(msg, style: TextStyle(fontSize: 13, color: c)),
  );
}

// ── WIDGETS UTILITAIRES ───────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {},
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard(this.message);
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Icon(Icons.inbox_outlined, size: 40, color: AppTheme.textSecondary),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
      ]),
    ),
  );
}
