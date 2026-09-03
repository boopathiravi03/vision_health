import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/patient_service.dart';

class NearbyPhcScreen extends StatefulWidget {
  final String patientId;
  final String initialLocation;

  const NearbyPhcScreen({
    super.key,
    this.patientId = '',
    this.initialLocation = '',
  });

  @override
  State<NearbyPhcScreen> createState() => _NearbyPhcScreenState();
}

class _NearbyPhcScreenState extends State<NearbyPhcScreen> {
  late final TextEditingController _locationController;

  final PatientService _patientService = PatientService();
  final MapController _mapController = MapController();

  LatLng? _userLocation;

  List<_PhcPlace> _phcs = [];

  bool _loading = true;
  bool _searching = false;
  bool _locationPermissionDenied = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _locationController = TextEditingController(
      text: widget.initialLocation,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    await _prefillLocation();

    if (!mounted) return;

    await _getCurrentLocation();

    if (!mounted) return;

    if (_userLocation != null) {
      await _searchNearbyPhcs(_userLocation!);
    } else if (_locationController.text.trim().isNotEmpty) {
      await _searchLocationText();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _prefillLocation() async {
    if (widget.initialLocation.trim().isNotEmpty) {
      return;
    }

    if (widget.patientId.isEmpty) {
      return;
    }

    try {
      final patient = await _patientService.getPatient(
        widget.patientId,
      );

      final village = patient?['village']
          ?.toString()
          .trim();

      if (village != null && village.isNotEmpty) {
        _locationController.text = village;
      }
    } catch (_) {
      // Location can still be entered manually.
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _locationPermissionDenied = true;
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _userLocation = LatLng(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      // Manual village/PIN search remains available.
    }
  }

  Future<void> _searchLocationText() async {
    final location =
        _locationController.text.trim();

    if (location.isEmpty) {
      _showMessage(
        'Enter your village, town, or PIN code.',
      );
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final coordinates =
          await _geocode(location);

      if (coordinates == null) {
        throw Exception(
          'Location could not be found.',
        );
      }

      _userLocation = coordinates;

      await _searchNearbyPhcs(coordinates);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searching = false;
        _loading = false;
        _error =
            'Unable to find this location. Try a village, town, district, or PIN code.';
      });
    }
  }

  Future<LatLng?> _geocode(
    String location,
  ) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': location,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'in',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'VissionHealth/1.0 healthcare-app',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data =
        jsonDecode(response.body);

    if (data is! List || data.isEmpty) {
      return null;
    }

    final item = data.first;

    return LatLng(
      double.parse(item['lat'].toString()),
      double.parse(item['lon'].toString()),
    );
  }

  Future<void> _searchNearbyPhcs(
    LatLng location,
  ) async {
    if (mounted) {
      setState(() {
        _searching = true;
        _loading = false;
        _error = null;
      });
    }

    try {
      final lat = location.latitude;
      final lon = location.longitude;

      const radius = 10000;

      final query = '''
[out:json][timeout:20];
(
  node["amenity"="clinic"](around:$radius,$lat,$lon);
  way["amenity"="clinic"](around:$radius,$lat,$lon);
  relation["amenity"="clinic"](around:$radius,$lat,$lon);

  node["amenity"="hospital"](around:$radius,$lat,$lon);
  way["amenity"="hospital"](around:$radius,$lat,$lon);
  relation["amenity"="hospital"](around:$radius,$lat,$lon);
);
out center tags;
''';

      final uri = Uri.https(
        'overpass-api.de',
        '/api/interpreter',
        {'data': query},
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'VissionHealth/1.0 healthcare-app',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Hospital service unavailable',
        );
      }

      final data =
          jsonDecode(response.body);

      final elements =
          data['elements'] as List? ?? [];

      final places = <_PhcPlace>[];

      for (final element in elements) {
        final tags =
            element['tags'] as Map? ?? {};

        final elementLat =
            element['lat'] ??
            element['center']?['lat'];

        final elementLon =
            element['lon'] ??
            element['center']?['lon'];

        if (elementLat == null ||
            elementLon == null) {
          continue;
        }

        final name =
            tags['name']?.toString();

        if (name == null ||
            name.trim().isEmpty) {
          continue;
        }

        final place = _PhcPlace(
          name: name,
          location: LatLng(
            double.parse(
              elementLat.toString(),
            ),
            double.parse(
              elementLon.toString(),
            ),
          ),
          type:
              tags['amenity'] == 'hospital'
                  ? 'Hospital'
                  : 'Clinic / PHC',
          address:
              _buildAddress(tags),
        );

        places.add(place);
      }

      places.sort(
        (a, b) =>
            _distance(location, a.location)
                .compareTo(
              _distance(location, b.location),
            ),
      );

      if (!mounted) return;

      setState(() {
        _phcs = places.take(15).toList();
        _searching = false;
        _loading = false;
      });

      _mapController.move(
        location,
        13,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _phcs = [];
        _searching = false;
        _loading = false;
        _error =
            'Hospital information could not be loaded. '
            'Please try again or verify nearby facilities with your PHC.';
      });
    }
  }

  String _buildAddress(
    Map tags,
  ) {
    final parts = <String>[];

    for (final key in [
      'addr:housenumber',
      'addr:street',
      'addr:village',
      'addr:town',
      'addr:city',
    ]) {
      final value =
          tags[key]?.toString().trim();

      if (value != null &&
          value.isNotEmpty) {
        parts.add(value);
      }
    }

    return parts.join(', ');
  }

  double _distance(
    LatLng a,
    LatLng b,
  ) {
    const earthRadius = 6371000.0;

    final lat1 =
        a.latitude * math.pi / 180;

    final lat2 =
        b.latitude * math.pi / 180;

    final deltaLat =
        (b.latitude - a.latitude) *
            math.pi /
            180;

    final deltaLon =
        (b.longitude - a.longitude) *
            math.pi /
            180;

    final h =
        math.sin(deltaLat / 2) *
                math.sin(deltaLat / 2) +
            math.cos(lat1) *
                math.cos(lat2) *
                math.sin(deltaLon / 2) *
                math.sin(deltaLon / 2);

    final c =
        2 * math.atan2(
          math.sqrt(h),
          math.sqrt(1 - h),
        );

    return earthRadius * c;
  }

  String _formatDistance(
    double meters,
  ) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _openDirections(
    _PhcPlace place,
  ) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=fossgis_osrm_car'
      '&route=${_userLocation?.latitude},'
      '${_userLocation?.longitude};'
      '${place.location.latitude},'
      '${place.location.longitude}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text(
          'Nearby PHC & Hospitals',
        ),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _searchBar(),

                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _map(),
                      ),

                      Expanded(
                        flex: 4,
                        child: _hospitalList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:
                  _locationController,
              textCapitalization:
                  TextCapitalization.words,
              decoration:
                  InputDecoration(
                labelText:
                    'Village, town, or PIN',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                ),
                suffixIcon:
                    _locationPermissionDenied
                        ? const Icon(
                            Icons.location_off,
                          )
                        : null,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              onSubmitted: (_) =>
                  _searchLocationText(),
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            height: 52,
            width: 52,
            child: FilledButton(
              onPressed: _searching
                  ? null
                  : _searchLocationText,
              child: _searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.search,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _map() {
    final center =
        _userLocation ??
        const LatLng(
          11.1271,
          78.6569,
        );

    final markers = <Marker>[];

    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.my_location,
            size: 38,
            color: Color(0xFF087F73),
          ),
        ),
      );
    }

    for (final phc in _phcs) {
      markers.add(
        Marker(
          point: phc.location,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () {
              _showPlaceSheet(phc);
            },
            child: const Icon(
              Icons.location_on,
              size: 42,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
          minZoom: 5,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.vissionhealth.app',
          ),

          MarkerLayer(
            markers: markers,
          ),

          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hospitalList() {
    if (_error != null) {
      return _messagePanel(
        icon: Icons.info_outline,
        message: _error!,
      );
    }

    if (_phcs.isEmpty) {
      return _messagePanel(
        icon: Icons.local_hospital_outlined,
        message:
            'No nearby healthcare facilities were found. '
            'Try another village, town, or PIN code.',
      );
    }

    return Container(
      color: const Color(0xFFF5F9F8),
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _phcs.length,
        itemBuilder: (
          context,
          index,
        ) {
          final phc = _phcs[index];

          final distance =
              _userLocation == null
                  ? null
                  : _distance(
                      _userLocation!,
                      phc.location,
                    );

          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 10,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border:
                  Border.all(
                color:
                    const Color(
                  0xFFE0E9E6,
                ),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(
                12,
              ),

              leading: Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE8F6F3,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color:
                      Color(0xFF087F73),
                ),
              ),

              title: Text(
                phc.name,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  Text(
                    phc.type,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF087F73),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  if (distance != null)
                    Text(
                      _formatDistance(
                        distance,
                      ),
                    ),

                  if (phc.address
                      .isNotEmpty)
                    Text(
                      phc.address,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: () =>
                        _openDirections(
                      phc,
                    ),
                    icon: const Icon(
                      Icons.directions,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'GET DIRECTIONS',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _messagePanel({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F9F8),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 46,
            color: const Color(0xFF087F73),
          ),

          const SizedBox(height: 12),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          if (_userLocation != null)
            OutlinedButton.icon(
              onPressed: () {
                _searchNearbyPhcs(
                  _userLocation!,
                );
              },
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('TRY AGAIN'),
            ),
        ],
      ),
    );
  }

  void _showPlaceSheet(
    _PhcPlace place,
  ) {
    final distance =
        _userLocation == null
            ? null
            : _distance(
                _userLocation!,
                place.location,
              );

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  place.type,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF087F73),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                if (distance != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 4,
                    ),
                    child: Text(
                      _formatDistance(
                        distance,
                      ),
                    ),
                  ),

                if (place.address
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 8,
                    ),
                    child: Text(
                      place.address,
                    ),
                  ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                      _openDirections(
                        place,
                      );
                    },
                    icon: const Icon(
                      Icons.directions,
                    ),
                    label:
                        const Text(
                      'GET DIRECTIONS',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhcPlace {
  final String name;
  final LatLng location;
  final String type;
  final String address;

  const _PhcPlace({
    required this.name,
    required this.location,
    required this.type,
    required this.address,
  });
}
