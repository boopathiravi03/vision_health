import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeHospitalMapScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;

  const SchemeHospitalMapScreen({
    super.key,
    required this.scheme,
  });

  @override
  State<SchemeHospitalMapScreen> createState() =>
      _SchemeHospitalMapScreenState();
}

class _SchemeHospitalMapScreenState extends State<SchemeHospitalMapScreen> {
  static const _teal = Color(0xFF087F73);
  static const _defaultCenter = LatLng(13.0827, 80.2707); // Chennai fallback.

  LatLng _userLocation = _defaultCenter;
  bool _locationLoading = true;
  bool _hospitalLoading = true;
  String? _message;
  List<_Hospital> _hospitals = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadLocationAndHospitals();
  }

  Future<void> _loadLocationAndHospitals() async {
    try {
      final location = await _getUserLocation();
      if (mounted) {
        setState(() {
          _userLocation = location;
          _locationLoading = false;
        });
      }
      await _loadHospitals(location);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationLoading = false;
          _message = 'Location permission was not available. Showing hospitals around Chennai.';
        });
      }
      await _loadHospitals(_defaultCenter);
    }
  }

  Future<LatLng> _getUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _defaultCenter;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _defaultCenter;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _loadHospitals(LatLng center) async {
    setState(() => _hospitalLoading = true);

    try {
      final query = '''
[out:json][timeout:15];
nwr["amenity"="hospital"](around:8000,${center.latitude},${center.longitude});
out center tags;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      );

      if (response.statusCode != 200) {
        throw Exception('Hospital map service unavailable');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (json['elements'] as List<dynamic>? ?? []);

      final hospitals = <_Hospital>[];
      for (final item in elements) {
        final data = Map<String, dynamic>.from(item as Map);
        final tags = Map<String, dynamic>.from(
          data['tags'] as Map? ?? const {},
        );
        final lat = (data['lat'] ?? data['center']?['lat']);
        final lon = (data['lon'] ?? data['center']?['lon']);
        if (lat is num && lon is num) {
          hospitals.add(
            _Hospital(
              name: tags['name']?.toString().trim().isNotEmpty == true
                  ? tags['name'].toString()
                  : 'Nearby Hospital',
              location: LatLng(lat.toDouble(), lon.toDouble()),
              address: tags['addr:street']?.toString() ?? '',
              phone: tags['phone']?.toString() ?? '',
            ),
          );
        }
      }

      hospitals.sort(
        (a, b) => _distance(center, a.location)
            .compareTo(_distance(center, b.location)),
      );

      if (mounted) {
        setState(() {
          _hospitals = hospitals.take(12).toList();
          _hospitalLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hospitalLoading = false;
          _message = 'Could not load live hospital data. Please verify hospitals with the PHC.';
        });
      }
    }
  }

  double _distance(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Kilometer, a, b);
  }

  String _distanceText(LatLng point) {
    final km = _distance(_userLocation, point);
    return km < 1 ? '${(km * 1000).round()} m away' : '${km.toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    final schemeName =
        widget.scheme['name']?.toString() ?? 'Health Insurance Scheme';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Hospitals & Registration'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 330,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _userLocation,
                    initialZoom: 12.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.vission_health',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 34,
                          ),
                        ),
                        ..._hospitals.map(
                          (hospital) => Marker(
                            point: hospital.location,
                            width: 46,
                            height: 46,
                            child: GestureDetector(
                              onTap: () => _showHospital(hospital, schemeName),
                              child: const Icon(
                                Icons.location_on,
                                color: _teal,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => launchUrl(
                            Uri.parse('https://www.openstreetmap.org/copyright'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    foregroundColor: _teal,
                    onPressed: () {
                      _mapController.move(_userLocation, 13);
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
                if (_locationLoading || _hospitalLoading)
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Finding nearby hospitals...'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_message != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _message!,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          Expanded(
            child: _hospitalLoading
                ? const Center(child: CircularProgressIndicator())
                : _hospitals.isEmpty
                    ? _emptyHospitals()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _hospitals.length,
                        itemBuilder: (_, index) {
                          final hospital = _hospitals[index];
                          return _hospitalCard(hospital, schemeName);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalCard(_Hospital hospital, String schemeName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0E9E6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showHospital(hospital, schemeName),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: _teal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _distanceText(hospital.location),
                      style: const TextStyle(color: _teal),
                    ),
                    if (hospital.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hospital.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHospitals() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_hospital_outlined, size: 54, color: _teal),
            const SizedBox(height: 12),
            const Text(
              'No nearby hospitals found',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check with your PHC or search the map manually.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showHospital(_Hospital hospital, String schemeName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE8F6F3),
                    child: Icon(Icons.local_hospital, color: _teal, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      hospital.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_distanceText(hospital.location)} • $schemeName',
                style: const TextStyle(color: _teal),
              ),
              if (hospital.address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(hospital.address),
              ],
              const SizedBox(height: 20),
              _section(
                'How to register',
                const [
                  'Check your eligibility and carry the required documents.',
                  'Visit the hospital scheme/help desk or the official government portal.',
                  'Ask the staff to verify your scheme eligibility before treatment.',
                  'Complete verification/registration and keep the acknowledgement or scheme ID.',
                ],
              ),
              _section(
                'What you can expect',
                const [
                  'The hospital can confirm whether it is currently authorised for the scheme.',
                  'Covered services depend on the official scheme rules and your eligibility.',
                  'The hospital will explain any documents, approvals or charges before treatment.',
                  'For emergencies, seek immediate medical care and verify scheme formalities as soon as possible.',
                ],
              ),
              _section(
                'Documents to keep ready',
                _documents(),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Important: Vission Health only provides guidance. Hospital empanelment, eligibility, coverage and current rules must be confirmed with the official scheme authority or hospital.',
                  style: TextStyle(fontSize: 12, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openDirections(hospital),
                  icon: const Icon(Icons.directions),
                  label: const Text('GET DIRECTIONS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _documents() {
    final docs = widget.scheme['documents'];
    if (docs is List && docs.isNotEmpty) {
      return docs.map((e) => e.toString()).toList();
    }
    return const [
      'Government identity document',
      'Address proof',
      'Income/category certificate if required',
      'Existing health/scheme card if available',
      'Relevant medical records',
    ];
  }

  Widget _section(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 18, color: _teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(_Hospital hospital) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.location.latitude},${hospital.location.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Hospital {
  final String name;
  final LatLng location;
  final String address;
  final String phone;

  const _Hospital({
    required this.name,
    required this.location,
    this.address = '',
    this.phone = '',
  });
}
