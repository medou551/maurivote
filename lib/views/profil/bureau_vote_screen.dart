import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../utils/app_theme.dart';

class BureauVoteScreen extends ConsumerStatefulWidget {
  const BureauVoteScreen({super.key});
  @override
  ConsumerState<BureauVoteScreen> createState() => _BureauVoteScreenState();
}

class _BureauVoteScreenState extends ConsumerState<BureauVoteScreen> {
  static const Color _green = Color(0xFF006233);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _red = Color(0xFFD90012);

  GoogleMapController? _mapController;
  Position? _position;
  Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedBureau;
  List<Map<String, dynamic>> _bureaux = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _selectedWilaya = 'Tous';
  List<String> _wilayas = ['Tous'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadBureaux(), _getLocation()]);
    _buildMarkers();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadBureaux() async {
    try {
      final data = await supabase
          .from('bureaux_vote')
          .select('*, communes(nom_fr), wilayas(nom_fr)')
          .eq('is_actif', true)
          .order('code_bureau');
      if (mounted) {
        _bureaux = List<Map<String, dynamic>>.from(data as List);
        _filtered = _bureaux;
        final ws = _bureaux
            .map((b) => (b['wilayas']?['nom_fr'] ?? '') as String)
            .toSet()
            .toList()
          ..sort();
        _wilayas = ['Tous', ...ws];
      }
    } catch (e) {
      debugPrint('Erreur chargement bureaux: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}
  }

  void _buildMarkers() {
    _markers = _filtered.map((b) {
      final lat = double.tryParse(b['latitude']?.toString() ?? '0') ?? 0;
      final lng = double.tryParse(b['longitude']?.toString() ?? '0') ?? 0;
      final commune = b['communes']?['nom_fr'] ?? '';
      final wilaya = b['wilayas']?['nom_fr'] ?? '';
      return Marker(
          markerId: MarkerId(b['id']),
          position: LatLng(lat, lng),
          infoWindow:
              InfoWindow(title: b['nom'], snippet: '$commune — $wilaya'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => setState(() => _selectedBureau = b));
    }).toSet();

    if (_position != null) {
      _markers.add(Marker(
          markerId: const MarkerId('me'),
          position: LatLng(_position!.latitude, _position!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Ma position')));
    }
  }

  void _filterWilaya(String w) {
    setState(() {
      _selectedWilaya = w;
      _selectedBureau = null;
      _filtered = w == 'Tous'
          ? _bureaux
          : _bureaux
              .where((b) => (b['wilayas']?['nom_fr'] ?? '') == w)
              .toList();
    });
    _buildMarkers();
    if (_filtered.isNotEmpty) {
      final f = _filtered.first;
      final lat = double.tryParse(f['latitude']?.toString() ?? '0') ?? 0;
      final lng = double.tryParse(f['longitude']?.toString() ?? '0') ?? 0;
      _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), w == 'Tous' ? 5.5 : 11));
    }
  }

  double? _dist(Map<String, dynamic> b) {
    if (_position == null) return null;
    final lat = double.tryParse(b['latitude']?.toString() ?? '0') ?? 0;
    final lng = double.tryParse(b['longitude']?.toString() ?? '0') ?? 0;
    return Geolocator.distanceBetween(
            _position!.latitude, _position!.longitude, lat, lng) /
        1000;
  }

  Future<void> _navigate(Map<String, dynamic> b) async {
    final lat = b['latitude'];
    final lng = b['longitude'];
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF004D26), _green],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: SafeArea(
            child: Column(children: [
          Container(
              height: 4,
              decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_red, Color(0xFFFF1A2E), _red]))),

          // Header
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 16))),
                const SizedBox(width: 12),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Bureaux de Vote',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Mauritanie — CENI',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withOpacity(0.4))),
                    child: Text('${_filtered.length} bureaux',
                        style: const TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
              ])),

          // Filtre wilayas
          SizedBox(
              height: 40,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _wilayas.length,
                  itemBuilder: (_, i) {
                    final w = _wilayas[i];
                    final sel = w == _selectedWilaya;
                    return GestureDetector(
                        onTap: () => _filterWilaya(w),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: sel
                                    ? _gold
                                    : Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel ? _gold : Colors.white30)),
                            child: Text(w,
                                style: TextStyle(
                                    color: sel
                                        ? const Color(0xFF004D26)
                                        : Colors.white,
                                    fontSize: 11,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal))));
                  })),
          const SizedBox(height: 8),

          // Carte
          Expanded(
              child: Stack(children: [
            _loading
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : GoogleMap(
                    onMapCreated: (c) {
                      _mapController = c;
                      c.animateCamera(CameraUpdate.newLatLngZoom(
                          const LatLng(18.0858, -15.9785), 5.5));
                    },
                    initialCameraPosition: const CameraPosition(
                        target: LatLng(18.0858, -15.9785), zoom: 5.5),
                    markers: _markers,
                    myLocationEnabled: _position != null,
                    myLocationButtonEnabled: false,
                    onTap: (_) => setState(() => _selectedBureau = null)),

            // Panel bureau sélectionné
            if (_selectedBureau != null)
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24))),
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 16),
                        Row(children: [
                          Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: _green.withOpacity(0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.how_to_vote,
                                  color: _green, size: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(_selectedBureau!['nom'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(
                                    _selectedBureau!['communes']?['nom_fr'] ??
                                        '',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13)),
                                Text(
                                    _selectedBureau!['wilayas']?['nom_fr'] ??
                                        '',
                                    style: TextStyle(
                                        color: _green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ])),
                          IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () =>
                                  setState(() => _selectedBureau = null)),
                        ]),
                        const Divider(height: 20),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(_selectedBureau!['adresse'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary))),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.people_outlined,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text('${_selectedBureau!['capacite'] ?? 0} electeurs',
                              style: const TextStyle(fontSize: 13)),
                          const Spacer(),
                          if (_dist(_selectedBureau!) != null)
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: _green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                    '${_dist(_selectedBureau!)!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        color: _green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12))),
                          const SizedBox(width: 8),
                          if (_selectedBureau!['is_accessible'] == true)
                            const Icon(Icons.accessible,
                                color: Colors.blue, size: 20),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: () {
                                    final lat = double.tryParse(
                                            _selectedBureau!['latitude']
                                                    ?.toString() ??
                                                '0') ??
                                        0;
                                    final lng = double.tryParse(
                                            _selectedBureau!['longitude']
                                                    ?.toString() ??
                                                '0') ??
                                        0;
                                    _mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            LatLng(lat, lng), 15));
                                  },
                                  icon: const Icon(Icons.center_focus_strong,
                                      size: 16),
                                  label: const Text('Centrer'),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: _green,
                                      side: const BorderSide(color: _green)))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: ElevatedButton.icon(
                                  onPressed: () => _navigate(_selectedBureau!),
                                  icon: const Icon(Icons.navigation, size: 16),
                                  label: const Text('Y aller'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: _green,
                                      foregroundColor: Colors.white))),
                        ]),
                      ]))),

            // FAB liste
            if (_selectedBureau == null)
              Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                      onPressed: _showListe,
                      backgroundColor: _green,
                      icon: const Icon(Icons.list, color: Colors.white),
                      label: const Text('Liste',
                          style: TextStyle(color: Colors.white)))),

            // Ma position
            if (_position != null)
              Positioned(
                  bottom: _selectedBureau != null ? 220 : 80,
                  right: 16,
                  child: FloatingActionButton.small(
                      onPressed: () => _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                              LatLng(_position!.latitude, _position!.longitude),
                              13)),
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.my_location, color: _green))),
          ])),

          Container(
              height: 4,
              decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_red, Color(0xFFFF1A2E), _red]))),
        ])),
      ),
    );
  }

  void _showListe() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (_, ctrl) => Column(children: [
                  Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Text('Bureaux de vote',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: _green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('${_filtered.length}',
                                style: const TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.bold))),
                      ])),
                  const Divider(height: 1),
                  Expanded(
                      child: ListView.builder(
                          controller: ctrl,
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final b = _filtered[i];
                            final dist = _dist(b);
                            return ListTile(
                                leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                        color: _green.withOpacity(0.1),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.how_to_vote,
                                        color: _green, size: 20)),
                                title: Text(b['nom'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                subtitle: Text(
                                    '${b['communes']?['nom_fr'] ?? ''} — ${b['wilayas']?['nom_fr'] ?? ''}',
                                    style: const TextStyle(fontSize: 11)),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (b['is_accessible'] == true)
                                        const Icon(Icons.accessible,
                                            color: Colors.blue, size: 16),
                                      const SizedBox(width: 4),
                                      if (dist != null)
                                        Text('${dist.toStringAsFixed(1)}km',
                                            style: const TextStyle(
                                                color: _green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12)),
                                    ]),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() => _selectedBureau = b);
                                  final lat = double.tryParse(
                                          b['latitude']?.toString() ?? '0') ??
                                      0;
                                  final lng = double.tryParse(
                                          b['longitude']?.toString() ?? '0') ??
                                      0;
                                  _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                          LatLng(lat, lng), 14));
                                });
                          })),
                ])));
  }
}
