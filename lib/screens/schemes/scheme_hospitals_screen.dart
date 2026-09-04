import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeHospitalsScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> patient;

  const SchemeHospitalsScreen({
    super.key,
    required this.scheme,
    required this.patient,
  });

  @override
  State<SchemeHospitalsScreen> createState() =>
      _SchemeHospitalsScreenState();
}

class _SchemeHospitalsScreenState
    extends State<SchemeHospitalsScreen> {
  static const Color teal = Color(0xFF087F73);

  // Chennai fallback for demo.
  static const LatLng demoLocation = LatLng(
    13.0827,
    80.2707,
  );

  final MapController _mapController = MapController();

  final TextEditingController _locationController =
      TextEditingController();

  LatLng _patientLocation = demoLocation;

  List<_Hospital> _hospitals = [];

  bool _loadingLocation = true;
  bool _loadingHospitals = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _preparePatientLocation();
  }

  // ------------------------------------------------------------
  // PATIENT LOCATION
  // ------------------------------------------------------------

  Future<void> _preparePatientLocation() async {
    final locationText = _patientLocationText();

    _locationController.text = locationText;

    if (locationText.trim().isEmpty) {
      await _useDemoLocation();
      return;
    }

    try {
      final coordinates =
          await _geocodeLocation(locationText);

      if (coordinates == null) {
        await _useDemoLocation();
        return;
      }

      if (!mounted) return;

      setState(() {
        _patientLocation = coordinates;
        _loadingLocation = false;
      });

      _mapController.move(
        coordinates,
        13,
      );

      await _searchHospitals(coordinates);
    } catch (_) {
      await _useDemoLocation();
    }
  }

  String _patientLocationText() {
    final village = _readPatientValue([
      'village',
      'town',
      'city',
      'location',
    ]);

    final district = _readPatientValue([
      'district',
    ]);

    final state = _readPatientValue([
      'state',
    ]);

    final parts = <String>[];

    if (village.isNotEmpty) {
      parts.add(village);
    }

    if (district.isNotEmpty &&
        district.toLowerCase() != village.toLowerCase()) {
      parts.add(district);
    }

    if (state.isNotEmpty) {
      parts.add(state);
    }

    if (parts.isEmpty) {
      return 'Chennai, Tamil Nadu, India';
    }

    return '${parts.join(', ')}, India';
  }

  String _readPatientValue(List<String> keys) {
    for (final key in keys) {
      final value = widget.patient[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  Future<void> _useDemoLocation() async {
    if (!mounted) return;

    setState(() {
      _patientLocation = demoLocation;
      _loadingLocation = false;
    });

    _locationController.text =
        'Chennai, Tamil Nadu, India';

    _mapController.move(
      demoLocation,
      12.5,
    );

    await _searchHospitals(demoLocation);
  }

  // ------------------------------------------------------------
  // NOMINATIM GEOCODING
  // ------------------------------------------------------------

  Future<LatLng?> _geocodeLocation(
    String query,
  ) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'in',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent':
            'VissionHealth/1.0 (healthcare demo application)',
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

    final first =
        Map<String, dynamic>.from(
      data.first as Map,
    );

    final lat =
        double.tryParse(
      first['lat']?.toString() ?? '',
    );

    final lon =
        double.tryParse(
      first['lon']?.toString() ?? '',
    );

    if (lat == null || lon == null) {
      return null;
    }

    return LatLng(lat, lon);
  }

  // ------------------------------------------------------------
  // HOSPITAL SEARCH
  // ------------------------------------------------------------

  Future<void> _searchHospitals(
    LatLng center,
  ) async {
    if (!mounted) return;

    setState(() {
      _loadingHospitals = true;
      _error = null;
    });

    try {
      final query = '''
[out:json][timeout:20];

(
  nwr["amenity"="hospital"]
    (around:10000,${center.latitude},${center.longitude});

  nwr["amenity"="clinic"]
    (around:10000,${center.latitude},${center.longitude});

  nwr["healthcare"="hospital"]
    (around:10000,${center.latitude},${center.longitude});

  nwr["healthcare"="clinic"]
    (around:10000,${center.latitude},${center.longitude});

  nwr["healthcare"="centre"]
    (around:10000,${center.latitude},${center.longitude});
);

out center tags;
''';

      final response = await http.post(
        Uri.parse(
          'https://overpass-api.de/api/interpreter',
        ),
        headers: const {
          'Content-Type':
              'application/x-www-form-urlencoded',
          'User-Agent':
              'VissionHealth/1.0 (healthcare demo application)',
        },
        body: {
          'data': query,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Hospital service unavailable',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'Invalid hospital response',
        );
      }

      final elements =
          decoded['elements'] as List? ?? [];

      final hospitals = <_Hospital>[];

      for (final element in elements) {
        if (element is! Map) continue;

        final data =
            Map<String, dynamic>.from(element);

        final tags =
            Map<String, dynamic>.from(
          data['tags'] as Map? ?? {},
        );

        final centerData =
            data['center'] as Map?;

        final latValue =
            data['lat'] ??
            centerData?['lat'];

        final lonValue =
            data['lon'] ??
            centerData?['lon'];

        final lat =
            double.tryParse(
          latValue?.toString() ?? '',
        );

        final lon =
            double.tryParse(
          lonValue?.toString() ?? '',
        );

        if (lat == null || lon == null) {
          continue;
        }

        final name =
            tags['name']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? tags['name'].toString().trim()
            : 'Nearby Healthcare Facility';

        final type =
            tags['amenity'] == 'hospital' ||
                    tags['healthcare'] == 'hospital'
                ? 'Hospital'
                : 'Clinic / Health Centre';

        final address =
            _buildAddress(tags);

        final phone =
            tags['phone']?.toString() ??
                tags['contact:phone']?.toString() ??
                '';

        hospitals.add(
          _Hospital(
            name: name,
            location: LatLng(
              lat,
              lon,
            ),
            type: type,
            address: address,
            phone: phone,
          ),
        );
      }

      hospitals.sort(
        (a, b) =>
            _distance(
              center,
              a.location,
            ).compareTo(
              _distance(
                center,
                b.location,
              ),
            ),
      );

      if (!mounted) return;

      setState(() {
        _hospitals =
            hospitals.take(15).toList();

        _loadingHospitals = false;

        if (_hospitals.isEmpty) {
          _error =
              'No mapped healthcare facilities were found nearby.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingHospitals = false;

        // Important:
        // Keep the map working even when Overpass
        // is temporarily unavailable.
        _hospitals =
            _demoHospitals(center);

        _error =
            'Live hospital data is temporarily unavailable. '
            'Showing demo facilities for the map.';
      });
    }
  }

  // ------------------------------------------------------------
  // DEMO HOSPITALS
  // ------------------------------------------------------------

  List<_Hospital> _demoHospitals(
    LatLng center,
  ) {
    return [
      _Hospital(
        name: 'Government General Hospital',
        location: LatLng(
          center.latitude + 0.012,
          center.longitude + 0.010,
        ),
        type: 'Government Hospital',
        address: 'Demo facility near patient location',
        phone: '',
      ),
      _Hospital(
        name: 'Primary Health Centre',
        location: LatLng(
          center.latitude - 0.010,
          center.longitude + 0.008,
        ),
        type: 'PHC',
        address: 'Demo PHC near patient location',
        phone: '',
      ),
      _Hospital(
        name: 'Community Health Centre',
        location: LatLng(
          center.latitude + 0.006,
          center.longitude - 0.014,
        ),
        type: 'Community Health Centre',
        address: 'Demo healthcare centre',
        phone: '',
      ),
      _Hospital(
        name: 'Apollo Hospital',
        location: LatLng(
          center.latitude - 0.014,
          center.longitude - 0.008,
        ),
        type: 'Hospital',
        address: 'Demo hospital location',
        phone: '',
      ),
    ];
  }

  String _buildAddress(
    Map<String, dynamic> tags,
  ) {
    final parts = <String>[];

    const keys = [
      'addr:housenumber',
      'addr:street',
      'addr:suburb',
      'addr:village',
      'addr:town',
      'addr:city',
      'addr:district',
      'addr:state',
    ];

    for (final key in keys) {
      final value =
          tags[key]?.toString().trim();

      if (value != null &&
          value.isNotEmpty) {
        parts.add(value);
      }
    }

    return parts.join(', ');
  }

  // ------------------------------------------------------------
  // DISTANCE
  // ------------------------------------------------------------

  double _distance(
    LatLng a,
    LatLng b,
  ) {
    const earthRadius = 6371.0;

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
        2 *
            math.atan2(
              math.sqrt(h),
              math.sqrt(1 - h),
            );

    return earthRadius * c;
  }

  String _distanceText(
    LatLng location,
  ) {
    final km =
        _distance(
          _patientLocation,
          location,
        );

    if (km < 1) {
      return '${(km * 1000).round()} m away';
    }

    return '${km.toStringAsFixed(1)} km away';
  }

  // ------------------------------------------------------------
  // MANUAL LOCATION SEARCH
  // ------------------------------------------------------------

  Future<void> _searchManualLocation() async {
    final text =
        _locationController.text.trim();

    if (text.isEmpty) {
      _showMessage(
        'Enter the patient village, town or PIN code.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loadingLocation = true;
      _error = null;
    });

    try {
      final coordinates =
          await _geocodeLocation(
        '$text, India',
      );

      if (coordinates == null) {
        setState(() {
          _loadingLocation = false;
          _error =
              'Location could not be found. Try the village, town or PIN code.';
        });
        return;
      }

      setState(() {
        _patientLocation =
            coordinates;
        _loadingLocation = false;
      });

      _mapController.move(
        coordinates,
        13,
      );

      await _searchHospitals(
        coordinates,
      );
    } catch (_) {
      setState(() {
        _loadingLocation = false;
        _error =
            'Unable to search this location.';
      });
    }
  }

  // ------------------------------------------------------------
  // DIRECTIONS
  // ------------------------------------------------------------

  Future<void> _openDirections(
    _Hospital hospital,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_patientLocation.latitude},'
      '${_patientLocation.longitude}'
      '&destination=${hospital.location.latitude},'
      '${hospital.location.longitude}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final schemeName =
        widget.scheme['name']
                ?.toString() ??
            'Government Health Scheme';

    final patientName =
        _readPatientValue([
      'name',
      'patientName',
    ]);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text(
          'Hospitals & Registration',
        ),
      ),
      body: Column(
        children: [
          _locationSearch(),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _mapSection(),

                _schemeHeader(
                  schemeName,
                  patientName,
                ),

                _hospitalSection(
                  schemeName,
                ),

                _registrationSection(),

                _warning(),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationSearch() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10,
      ),
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
                    'Patient village / town / PIN',
                prefixIcon:
                    const Icon(
                  Icons.location_on_outlined,
                  color: teal,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              onSubmitted: (_) =>
                  _searchManualLocation(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            height: 52,
            child: FilledButton(
              onPressed:
                  _loadingLocation ||
                          _loadingHospitals
                      ? null
                      : _searchManualLocation,
              style:
                  FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: teal,
              ),
              child:
                  _loadingLocation ||
                          _loadingHospitals
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

  Widget _mapSection() {
    final markers = <Marker>[
      Marker(
        point: _patientLocation,
        width: 54,
        height: 54,
        child: Container(
          decoration:
              BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 27,
          ),
        ),
      ),
    ];

    for (final hospital
        in _hospitals) {
      markers.add(
        Marker(
          point:
              hospital.location,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () =>
                _showHospital(
              hospital,
            ),
            child: Container(
              decoration:
                  BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: teal,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_hospital,
                color: teal,
                size: 27,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          FlutterMap(
            mapController:
                _mapController,
            options:
                MapOptions(
              initialCenter:
                  _patientLocation,
              initialZoom: 12.5,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions:
                  const InteractionOptions(
                flags:
                    InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/'
                    '{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.vission_health',
              ),

              MarkerLayer(
                markers: markers,
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () =>
                        launchUrl(
                      Uri.parse(
                        'https://www.openstreetmap.org/copyright',
                      ),
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
              heroTag:
                  'patient-location-map',
              backgroundColor:
                  Colors.white,
              foregroundColor: teal,
              onPressed: () {
                _mapController.move(
                  _patientLocation,
                  13,
                );
              },
              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),

          if (_loadingLocation ||
              _loadingHospitals)
            const Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Finding patient location and nearby hospitals...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _schemeHeader(
    String schemeName,
    String patientName,
  ) {
    return Padding(
      padding:
          const EdgeInsets.all(16),
      child: Container(
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              const Color(0xFFE4F5F2),
          borderRadius:
              BorderRadius.circular(
            22,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance,
              size: 42,
              color: teal,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              schemeName,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              patientName.isEmpty
                  ? 'Find a nearby healthcare facility and understand what to do next.'
                  : 'Patient: $patientName\nFind a nearby healthcare facility and understand what to do next.',
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hospitalSection(
    String schemeName,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Nearby Hospitals',
            style: TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              padding:
                  const EdgeInsets.all(
                13,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFFFF8E1),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                _error!,
                style:
                    const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          if (_hospitals.isEmpty &&
              !_loadingHospitals)
            _emptyHospitalCard()
          else
            ..._hospitals.map(
              (hospital) =>
                  _hospitalCard(
                hospital,
                schemeName,
              ),
            ),
        ],
      ),
    );
  }

  Widget _hospitalCard(
    _Hospital hospital,
    String schemeName,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE8F6F3,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: teal,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      hospital.type,
                      style:
                          const TextStyle(
                        color: teal,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      _distanceText(
                        hospital.location,
                      ),
                      style:
                          const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    if (hospital
                        .address
                        .isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 4,
                        ),
                        child: Text(
                          hospital.address,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed: () =>
                      _showHospital(
                    hospital,
                  ),
                  child:
                      const Text(
                    'DETAILS',
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _openDirections(
                    hospital,
                  ),
                  icon:
                      const Icon(
                    Icons.directions,
                    size: 18,
                  ),
                  label:
                      const Text(
                    'DIRECTIONS',
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyHospitalCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.local_hospital_outlined,
            size: 48,
            color: teal,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No nearby hospitals found',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 6,
          ),
          Text(
            'Try another village, town or PIN code.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HOSPITAL DETAILS
  // ------------------------------------------------------------

  void _showHospital(
    _Hospital hospital,
  ) {
    final schemeName =
        widget.scheme['name']
                ?.toString() ??
            'Selected scheme';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
          Colors.white,
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Color(0xFFE8F6F3),
                      child: Icon(
                        Icons.local_hospital,
                        color: teal,
                        size: 30,
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Text(
                        hospital.name,
                        style:
                            const TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  hospital.type,
                  style:
                      const TextStyle(
                    color: teal,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  _distanceText(
                    hospital.location,
                  ),
                ),

                if (hospital
                    .address
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 8,
                    ),
                    child: Text(
                      hospital.address,
                    ),
                  ),

                const SizedBox(
                  height: 20,
                ),

                _detailSection(
                  'How to use the scheme',
                  [
                    'Carry the required documents.',
                    'Ask the hospital help desk to verify your scheme eligibility.',
                    'Confirm that the facility is currently authorised for the selected scheme.',
                    'Complete registration or approval before treatment where required.',
                  ],
                ),

                _detailSection(
                  'Documents to keep ready',
                  _schemeDocuments(),
                ),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFFFF8E1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(
                    'Important: This map shows nearby healthcare facilities. '
                    '$schemeName eligibility and hospital empanelment must be verified with the official authority or hospital.',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                SizedBox(
                  width: double.infinity,
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
                      'GET DIRECTIONS',
                    ),
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          teal,
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

  List<String> _schemeDocuments() {
    final documents =
        widget.scheme['documents'];

    if (documents is List &&
        documents.isNotEmpty) {
      return documents
          .map(
            (e) => e.toString(),
          )
          .toList();
    }

    if (documents is String &&
        documents.trim().isNotEmpty) {
      return [
        documents.trim(),
      ];
    }

    return const [
      'Government ID',
      'Address/family eligibility documents',
      'Income/category certificate if applicable',
      'Health/scheme card if available',
      'Relevant medical records',
    ];
  }

  Widget _detailSection(
    String title,
    List<String> items,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          ...items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 7,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: teal,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style:
                          const TextStyle(
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // REGISTRATION
  // ------------------------------------------------------------

  Widget _registrationSection() {
    return Padding(
      padding:
          const EdgeInsets.all(16),
      child: Container(
        padding:
            const EdgeInsets.all(20),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color:
                const Color(0xFFE0E9E6),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.app_registration,
                  color: teal,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'How to register',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            _step(
              '1',
              'Select a nearby healthcare facility from the map.',
            ),
            _step(
              '2',
              'Carry your required identity and eligibility documents.',
            ),
            _step(
              '3',
              'Ask the hospital help desk to verify the selected scheme.',
            ),
            _step(
              '4',
              'Complete registration or scheme verification.',
            ),
            _step(
              '5',
              'Keep the acknowledgement, card or reference number safely.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(
    String number,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: teal,
            child: Text(
              number,
              style:
                  const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warning() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFFFF8E1),
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child: const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                'Nearby does not mean scheme-approved. '
                'Always confirm hospital empanelment, eligibility and current scheme rules before treatment.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}

// ------------------------------------------------------------
// HOSPITAL MODEL
// ------------------------------------------------------------

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
