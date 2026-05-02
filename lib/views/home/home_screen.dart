import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/elections_viewmodel.dart';
import '../../widgets/election_card.dart';
import '../../widgets/connectivity_banner.dart';

/// Écran Accueil — Liste des élections avec filtres
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electionsAsync = ref.watch(electionsProvider);
    final filter = ref.watch(electionFilterProvider);
    final voter  = ref.watch(currentVoterProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── Bannière mode offline ─────────────────────────────────────
            const ConnectivityBanner(),

            // ── En-tête ────────────────────────────────────────────────────
            _Header(voterName: voter?.prenom ?? ''),

            // ── Filtres ────────────────────────────────────────────────────
            _FilterBar(
              current: filter,
              onChanged: (f) =>
                  ref.read(electionFilterProvider.notifier).state = f,
            ),

            // ── Liste des élections ────────────────────────────────────────
            Expanded(
              child: electionsAsync.when(
                loading: () => _buildShimmer(),
                error: (err, _) => _buildError(context, ref, err),
                data: (_) {
                  final filtered =
                      ref.watch(filteredElectionsProvider(filter));
                  return filtered.when(
                    loading: () => _buildShimmer(),
                    error: (e, _) => _buildError(context, ref, e),
                    data: (elections) {
                      if (elections.isEmpty) return _buildEmpty(filter);
                      return RefreshIndicator(
                        color: AppTheme.primaryGreen,
                        onRefresh: () =>
                            ref.refresh(electionsProvider.future),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: elections.length,
                          itemBuilder: (ctx, i) => ElectionCard(
                            election: elections[i],
                            onTap: () => context.push(
                                '/election/${elections[i].id}'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext ctx, WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_outlined, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text('Impossible de charger les élections',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Vérifiez votre connexion réseau',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(electionsProvider.future),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty(ElectionFilter filter) {
    final messages = {
      ElectionFilter.active:   ('Aucune élection en cours', Icons.how_to_vote_outlined),
      ElectionFilter.upcoming: ('Aucune élection planifiée', Icons.event_outlined),
      ElectionFilter.past:     ('Aucune élection terminée', Icons.history_outlined),
      ElectionFilter.all:      ('Aucune élection disponible', Icons.ballot_outlined),
    };
    final (msg, icon) = messages[filter]!;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(fontSize: 16,
            color: AppTheme.textSecondary)),
      ]),
    );
  }
}

// ── Widget En-tête ────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String voterName;
  const _Header({required this.voterName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                voterName.isNotEmpty ? 'Bonjour, $voterName 👋' : 'MauriVote',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 2),
              const Text('Élections de la République Islamique de Mauritanie',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          const Icon(Icons.how_to_vote, color: Colors.white, size: 32),
        ],
      ),
    );
  }
}

// ── Widget Filtres ────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final ElectionFilter current;
  final ValueChanged<ElectionFilter> onChanged;
  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: ElectionFilter.values.map((f) {
          final labels = {
            ElectionFilter.all:      'Toutes',
            ElectionFilter.active:   'En cours',
            ElectionFilter.upcoming: 'À venir',
            ElectionFilter.past:     'Terminées',
          };
          final isSelected = f == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[f]!),
              selected: isSelected,
              onSelected: (_) => onChanged(f),
              selectedColor: AppTheme.lightGreen,
              checkmarkColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
