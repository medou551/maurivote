path = r'lib/services/offline_service.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

# Ajouter methode preloadElections
if 'preloadElections' not in c:
    addition = '''
  // Precharger elections pour mode offline
  Future<void> preloadElections(List<Map<String, dynamic>> elections) async {
    final box = Hive.box(AppConstants.boxElections);
    for (final e in elections) {
      await box.put(e['id'], e);
    }
    debugPrint('OfflineService: \ elections mises en cache');
  }

  // Recuperer elections depuis cache
  List<Map<String, dynamic>> getCachedElections() {
    final box = Hive.box(AppConstants.boxElections);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // Verifier connectivite
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
'''
    c = c.rstrip() + addition
    print('preloadElections ajoute')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
