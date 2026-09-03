import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/patient_service.dart';

class SchemeHospitalMapScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final String patientId;

  const SchemeHospitalMapScreen({
    super.key,
    required this.scheme,
    this.patientId = '',
  });

  @override
  State<SchemeHospitalMapScreen> createState() =>
      _SchemeHospitalMapScreenState();
}

class _SchemeHospitalMapScreenState
    extends State<SchemeHospitalMapScreen> {
  final MapController _mapController = MapController();
  final PatientService _patientService = PatientService();

  LatLng? _patientLocation;
  String _patientLocationName = '';

  List<_Hospital> _hospitals = [];

  bool _loading = true;
  bool _searching = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientAndHospitals();
  }

  Future<void> _loadPatientAndHospitals() async {
    try {
      String locationText = '';

      if (widget.patientId.isNotEmpty) {
        final patient =
            await _patientService.getPatient(widget.patientId);

        if (patient != null) {
          final village =
              patient['village']?.toString().trim() ?? '';

          final town =
              patient['town']?.toString().trim() ?? '';

          final district =
              patient['district']?.toString().trim() ?? '';

          final state =
              patient['state']?.toString().trim() ?? '';

          final parts = <String>[];

          if (village.isNotEmpty) parts.add(village);
          if (town.isNotEmpty) parts.add(town);
          if (district.isNotEmpty) parts.add(district);
          if (state.isNotEmpty) parts.add(state);

          locationText = parts.join(', ');
        }
      }

      // Demo fallback.
      if (locationText.isEmpty) {
        locationText = 'Chennai, Tamil Nadu, India';
      }

      _patientLocationName = locationText;

      final location = await _geocode(locationText);

      if (location == null) {
        throw Exception('Patient location could not be found.');
      }

      _patientLocation = location;

      await _searchHospitals(location);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _searching = false;
        _error =
            'Unable to load nearby hospitals. '
            'Please check the patient location and try again.';
      });
    }
  }

  Future<LatLng?> _geocode(String location) async {
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

    final data = jsonDecode(response.body);

    if (data is! List || data.isEmpty) {
      return null;
    }

    final item = data.first;

    return LatLng(
      double.parse(item['lat'].toString()),
      double.parse(item['lon'].toString()),
    );
  }

  Future<void> _searchHospitals(
    LatLng location,
  ) async {
    if (mounted) {
      setState(() {
        _searching = true;
        _error = null;
      });
    }

    try {
      const radius = 15000;

      final lat = location.latitude;
      final lon = location.longitude;

      final query = '''
[out:json][timeout:25];

(
  node["amenity"="hospital"](around:$radius,$lat,$lon);
  way["amenity"="hospital"](around:$radius,$lat,$lon);
  relation["amenity"="hospital"](around:$radius,$lat,$lon);

  node["amenity"="clinic"](around:$radius,$lat,$lon);
  way["amenity"="clinic"](around:$radius,$lat,$lon);
  relation["amenity"="clinic"](around:$radius,$lat,$lon);

  node["healthcare"="hospital"](around:$radius,$lat,$lon);
  way["healthcare"="hospital"](around:$radius,$lat,$lon);
  relation["healthcare"="hospital"](around:$radius,$lat,$lon);
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
        throw Exception('Hospital search failed.');
      }

      final data = jsonDecode(response.body);

      final elements =
          data['elements'] as List? ?? [];

      final hospitals = <_Hospital>[];

      final seen = <String>{};

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
            tags['name']?.toString().trim();

        if (name == null || name.isEmpty) {
          continue;
        }

        final key =
            '$name-$elementLat-$elementLon';

        if (seen.contains(key)) {
          continue;
        }

        seen.add(key);

        final amenity =
            tags['amenity']?.toString() ?? '';

        final healthcare =
            tags['healthcare']?.toString() ?? '';

        final type =
            amenity == 'hospital' ||
                    healthcare == 'hospital'
                ? 'Hospital'
                : 'Clinic / PHC';

        hospitals.add(
          _Hospital(
            name: name,
            location: LatLng(
              double.parse(
                elementLat.toString(),
              ),
              double.parse(
                elementLon.toString(),
              ),
            ),
            type: type,
            address: _buildAddress(tags),
            phone:
                tags['phone']?.toString() ??
                    tags['contact:phone']?.toString() ??
                    '',
          ),
        );
      }

      hospitals.sort(
        (a, b) => _distance(
          location,
          a.location,
        ).compareTo(
          _distance(
            location,
            b.location,
          ),
        ),
      );

      if (!mounted) return;

      setState(() {
        _hospitals =
            hospitals.take(15).toList();

        _loading = false;
        _searching = false;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted ||
            _patientLocation == null) {
          return;
        }

        _mapController.move(
          _patientLocation!,
          12.5,
        );
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hospitals = [];
        _loading = false;
        _searching = false;
        _error =
            'Nearby hospital information could not be loaded.';
      });
    }
  }

  String _buildAddress(Map tags) {
    final parts = <String>[];

    for (final key in [
      'addr:housenumber',
      'addr:street',
      'addr:village',
      'addr:town',
      'addr:city',
      'addr:district',
    ]) {
      final value =
          tags[key]?.toString().trim();

      if (value != null && value.isNotEmpty) {
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

    final c = 2 *
        math.atan2(
          math.sqrt(h),
          math.sqrt(1 - h),
        );

    return earthRadius * c;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _openDirections(
    _Hospital hospital,
  ) async {
    if (_patientLocation == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=fossgis_osrm_car'
      '&route=${_patientLocation!.latitude},'
      '${_patientLocation!.longitude};'
      '${hospital.location.latitude},'
      '${hospital.location.longitude}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _callHospital(
    String phone,
  ) async {
    if (phone.isEmpty) {
      _showMessage(
        'Phone number is not available.',
      );
      return;
    }

    final uri = Uri.parse(
      'tel:${phone.replaceAll(' ', '')}',
    );

    if (!await launchUrl(uri)) {
      _showMessage(
        'Unable to open phone dialer.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schemeName =
        widget.scheme['name']?.toString() ??
            'Government Health Scheme';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text(
          'Scheme Hospitals',
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _schemeHeader(schemeName),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 330,
                          child: _map(),
                        ),
                        _hospitalSection(),
                        _howToUseScheme(),
                        _importantNotice(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _schemeHeader(String schemeName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE8F6F3),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color:
                      Color(0xFF087F73),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  schemeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Healthcare facilities near $_patientLocationName',
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _map() {
    final center =
        _patientLocation ??
            const LatLng(
              13.0827,
              80.2707,
            );

    final markers = <Marker>[];

    if (_patientLocation != null) {
      markers.add(
        Marker(
          point: _patientLocation!,
          width: 55,
          height: 55,
          child: const Icon(
            Icons.person_pin_circle,
            size: 48,
            color:
                Color(0xFF087F73),
          ),
        ),
      );
    }

    for (final hospital in _hospitals) {
      markers.add(
        Marker(
          point: hospital.location,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () =>
                _showHospitalSheet(hospital),
            child: Icon(
              hospital.type == 'Hospital'
                  ? Icons.local_hospital
                  : Icons.medical_services,
              size: 40,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.5,
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
    );
  }

  Widget _hospitalSection() {
    if (_error != null) {
      return _messageCard(
        Icons.info_outline,
        _error!,
      );
    }

    if (_hospitals.isEmpty) {
      return _messageCard(
        Icons.local_hospital_outlined,
        'No nearby hospitals were found in OpenStreetMap. '
        'Try again or verify participating facilities with the PHC.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nearby Healthcare Facilities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              if (_searching)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._hospitals.map(
            (hospital) =>
                _hospitalCard(hospital),
          ),
        ],
      ),
    );
  }

  Widget _hospitalCard(
    _Hospital hospital,
  ) {
    final distance =
        _patientLocation == null
            ? null
            : _distance(
                _patientLocation!,
                hospital.location,
              );

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE8F6F3),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  hospital.type ==
                          'Hospital'
                      ? Icons.local_hospital
                      : Icons.medical_services,
                  color:
                      const Color(0xFF087F73),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hospital.type,
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
                  ],
                ),
              ),
            ],
          ),
          if (hospital.address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              hospital.address,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showHospitalSheet(
                    hospital,
                  ),
                  icon: const Icon(
                    Icons.info_outline,
                  ),
                  label:
                      const Text('DETAILS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _openDirections(
                    hospital,
                  ),
                  icon: const Icon(
                    Icons.directions,
                  ),
                  label:
                      const Text('DIRECTIONS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _howToUseScheme() {
    final documents =
        widget.scheme['documents'] is List
            ? (widget.scheme['documents']
                    as List)
                .map((e) => e.toString())
                .toList()
            : <String>[];

    final action =
        widget.scheme['action']?.toString() ??
            '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'How to use this scheme',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _step(
            '1',
            'Confirm eligibility',
            'Ask the ASHA worker or PHC to confirm that you qualify.',
          ),
          _step(
            '2',
            'Choose a facility',
            'Select a nearby hospital from the map and list above.',
          ),
          _step(
            '3',
            'Carry documents',
            documents.isEmpty
                ? 'Carry your required government ID and scheme documents.'
                : documents.join(', '),
          ),
          _step(
            '4',
            'Ask about scheme registration',
            action.isEmpty
                ? 'Tell the hospital registration desk that you want to use the government scheme.'
                : action,
          ),
          _step(
            '5',
            'Confirm before treatment',
            'Ask the hospital whether the required treatment is covered before proceeding.',
          ),
        ],
      ),
    );
  }

  Widget _step(
    String number,
    String title,
    String description,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor:
                const Color(0xFFE8F6F3),
            child: Text(
              number,
              style: const TextStyle(
                color:
                    Color(0xFF087F73),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style:
                      const TextStyle(
                    color:
                        Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _importantNotice() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF8E1),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Important: OpenStreetMap shows healthcare locations. '
              'It does not confirm that a hospital accepts this government scheme. '
              'Always confirm scheme participation with the hospital, PHC or official government source.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard(
    IconData icon,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 42,
              color:
                  const Color(0xFF087F73),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHospitalSheet(
    _Hospital hospital,
  ) {
    final distance =
        _patientLocation == null
            ? null
            : _distance(
                _patientLocation!,
                hospital.location,
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
                  hospital.name,
                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hospital.type,
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
                      top: 5,
                    ),
                    child: Text(
                      _formatDistance(
                        distance,
                      ),
                    ),
                  ),
                if (hospital
                    .address
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 10,
                    ),
                    child: Text(
                      hospital.address,
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (hospital.phone
                        .isNotEmpty)
                      Expanded(
                        child:
                            OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(
                              context,
                            );
                            _callHospital(
                              hospital.phone,
                            );
                          },
                          icon:
                              const Icon(
                            Icons.phone,
                          ),
                          label:
                              const Text(
                            'CALL',
                          ),
                        ),
                      ),
                    if (hospital.phone
                        .isNotEmpty)
                      const SizedBox(
                        width: 10,
                      ),
                    Expanded(
                      child:
                          FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                          _openDirections(
                            hospital,
                          );
                        },
                        icon:
                            const Icon(
                          Icons.directions,
                        ),
                        label:
                            const Text(
                          'DIRECTIONS',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Hospital {
  final String name;
  final LatLng location;
  final String type;
  final String address;
  final String phone;

  const _Hospital({
    required this.name,
    required this.location,
    required this.type,
    required this.address,
    required this.phone,
  });
}
