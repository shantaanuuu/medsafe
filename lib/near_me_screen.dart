import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_service.dart';

class NearMeScreen extends ConsumerStatefulWidget {
  const NearMeScreen({super.key});
  @override
  ConsumerState<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends ConsumerState<NearMeScreen> {
  Position? position;
  List<NearbyPlace> places = [];
  bool loading = true;
  String? error;
  String category = 'hospital';
  int radius = 5000;
  final cats = const {
    'hospital': 'Hospitals',
    'clinic': 'Clinics',
    'pharmacy': 'Medical',
    'nursing_home': 'Nursing',
    'vet': 'Vet',
  };
  @override
  void initState() {
    super.initState();
    locate();
  }

  Future<void> locate() async {
    setState(() => loading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Turn on device location.');
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied)
        p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever)
        throw Exception('Location permission is required.');
      position = await Geolocator.getCurrentPosition();
      await search();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> search() async {
    if (position == null) return;
    setState(() => loading = true);
    try {
      places = await ref
          .read(apiServiceProvider)
          .nearbyHealthcare(
            latitude: position!.latitude,
            longitude: position!.longitude,
            category: category,
            radius: radius,
          );
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> directions(NearbyPlace p) => launchUrl(
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${position!.latitude},${position!.longitude}&destination=${p.latitude},${p.longitude}&destination_place_id=${p.id}&travelmode=driving',
    ),
    mode: LaunchMode.externalApplication,
  );
  @override
  Widget build(BuildContext context) {
    final pos = position;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Near me',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.my_location), onPressed: locate),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: cats.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: category == e.key,
                        onSelected: (_) {
                          setState(() => category = e.key);
                          search();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 16),
              const Text(
                'Radius',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: radius,
                items: const [
                  DropdownMenuItem(value: 2000, child: Text('2 km')),
                  DropdownMenuItem(value: 5000, child: Text('5 km')),
                  DropdownMenuItem(value: 10000, child: Text('10 km')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => radius = v);
                    search();
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          Expanded(
            child: pos == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error ?? 'Finding your location...'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: locate,
                          child: const Text('Enable location'),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(pos.latitude, pos.longitude),
                          zoom: 13.5,
                        ),
                        myLocationEnabled: true,
                        zoomControlsEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('me'),
                            position: LatLng(pos.latitude, pos.longitude),
                          ),
                          ...places.map(
                            (p) => Marker(
                              markerId: MarkerId(p.id),
                              position: LatLng(p.latitude, p.longitude),
                              infoWindow: InfoWindow(
                                title: p.name,
                                snippet: p.address,
                              ),
                              onTap: () => showPlace(p),
                            ),
                          ),
                        },
                      ),
                      if (loading)
                        const Center(child: CircularProgressIndicator()),
                      if (error != null)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Card(
                            color: const Color(0xfffff7ed),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(error!),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          SizedBox(
            height: 165,
            child: places.isEmpty && !loading
                ? const Center(child: Text('No matches. Try a larger radius.'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(10),
                    itemCount: places.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => placeCard(places[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget placeCard(NearbyPlace p) => SizedBox(
    width: 280,
    child: Card(
      child: InkWell(
        onTap: () => showPlace(p),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                p.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => directions(p),
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void showPlace(NearbyPlace p) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.name,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(p.address),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => directions(p),
                  icon: const Icon(Icons.directions),
                  label: const Text('Get directions'),
                ),
              ),
              if (p.phone != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: p.phone)),
                  icon: const Icon(Icons.call),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
