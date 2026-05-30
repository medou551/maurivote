import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../services/smart_db_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/mauritania_flag.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../app.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _elections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SmartDbService.getElections();
      if (mounted)
        setState(() {
          _elections = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voter = ref.watch(currentVoterProvider).value;
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(voter),
          _buildBanner(),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _elections.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _elections.length,
                            itemBuilder: (_, i) => _buildCard(_elections[i]),
                          ))),
        ]),
      ),
    );
  }

  Widget _buildHeader(voter) {
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
            color: Color(0xFF006233),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        child: Row(children: [
          // Drapeau mauritanien mini
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFF006233),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFFFD700), width: 1.5)),
              child: const Center(
                  child: Text('☽★',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFFFFD700))))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('MauriVote',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(voter != null ? ref.watch(localeProvider).languageCode == 'ar' ? 'مرحباً' : 'Bienvenue' : ref.watch(localeProvider).languageCode == 'ar' ? 'التصويت الإلكتروني' : 'Vote Electronique',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ]));
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      color: const Color(0xFFF5F5F5),
      child: const Row(children: [
        Icon(Icons.verified_outlined, color: AppTheme.primaryGreen, size: 16),
        SizedBox(width: 8),
        Expanded(
            child: Text('Commission Electorale Nationale Independante',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> e) {
    final statut = e['statut'] ?? '';
    final isOpen = statut == 'en_cours';
    final isDone = statut == 'terminee';
    final color = isOpen
        ? AppTheme.primaryGreen
        : isDone
            ? Colors.grey
            : Colors.orange;
    final label = isOpen
        ? 'En cours'
        : isDone
            ? 'Terminee'
            : 'Planifiee';
    final date = (e['date_ouverture'] ?? '').toString();
    final dateStr = date.length >= 10 ? date.substring(0, 10) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = e['id'].toString();
          context.push('/election/$id');
        },
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: const Icon(Icons.how_to_vote,
                      color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(e['titre_fr'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if ((e['titre_ar'] ?? '').isNotEmpty)
                      Text(e['titre_ar'] ?? '',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(20)),
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.ballot_outlined,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(e['type_election'] ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: isOpen
                ? ElevatedButton.icon(
                    onPressed: () {
                      final id = e['id'].toString();
                      context.push('/vote/$id');
                    },
                    icon: const Icon(Icons.how_to_vote),
                    label: Text(ref.watch(localeProvider).languageCode == 'ar' ? 'صوّت الآن' : 'Voter maintenant'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white))
                : OutlinedButton.icon(
                    onPressed: () {
                      final id = e['id'].toString();
                      context.push('/resultats/$id');
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: Text(ref.watch(localeProvider).languageCode == 'ar' ? 'عرض النتائج' : 'Voir les resultats'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen))),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.ballot_outlined,
            size: 64, color: AppTheme.primaryGreen),
        const SizedBox(height: 16),
        const Text('Aucune election disponible',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser')),
      ]));
}
