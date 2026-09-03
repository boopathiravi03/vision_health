import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeHospitalMapScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final String patientLocation;

  const SchemeHospitalMapScreen({
    super.key,
    required this.scheme,
    this.patientLocation = 'Chennai',
  });

  @override
  State<SchemeHospitalMapScreen> createState() =>
      _SchemeHospitalMapScreenState();
}

class _SchemeHospitalMapScreenState
    extends State<SchemeHospitalMapScreen> {
  final MapController _mapController = MapController();

  bool _showFacilities = true;

  // Chennai demo location.
  LatLng _patientLocation = const LatLng(
    13.0827,
    80.2707,
  );

  late List<_DemoHospital> _hospitals;

  @override
  void initState() {
    super.initState();

    _hospitals = _demoHospitals();
  }

  List<_DemoHospital> _demoHospitals() {
    return [
      const _DemoHospital(
        name: 'Demo Government Hospital',
        type: 'Government Hospital',
        address: 'Chennai Central Area',
        location: LatLng(
          13.0827,
          80.2707,
        ),
        schemeSupported: true,
      ),
      const _DemoHospital(
        name: 'Demo Primary Health Centre',
        type: 'PHC',
        address: 'Anna Nagar, Chennai',
        location: LatLng(
          13.0850,
          80.2101,
        ),
        schemeSupported: true,
      ),
      const _DemoHospital(
        name: 'Demo District Hospital',
        type: 'District Hospital',
        address: 'Egmore, Chennai',
        location: LatLng(
          13.0732,
          80.2609,
        ),
        schemeSupported: true,
      ),
      const _DemoHospital(
        name: 'Demo Community Health Centre',
        type: 'Community Health Centre',
        address: 'Guindy, Chennai',
        location: LatLng(
          13.0067,
          80.2206,
        ),
        schemeSupported: true,
      ),
    ];
  }

  String get schemeName {
    return widget.scheme['name']?.toString() ??
        'Selected Government Scheme';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Hospitals & Registration',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          _topSchemeCard(),

          Expanded(
            child: _showFacilities
                ? _mapAndList()
                : _mapOnly(),
          ),
        ],
      ),
    );
  }

  Widget _topSchemeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        18,
      ),
      color: const Color(0xFFE1F3EF),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF087F73),
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Scheme',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schemeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapAndList() {
    return Column(
      children: [
        SizedBox(
          height: 310,
          child: _map(),
        ),

        Expanded(
          child: _hospitalList(),
        ),
      ],
    );
  }

  Widget _mapOnly() {
    return _map();
  }

  Widget _map() {
    final markers = <Marker>[
      Marker(
        point: _patientLocation,
        width: 60,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            color: Color(0xFF087F73),
            size: 34,
          ),
        ),
      ),
    ];

    for (final hospital in _hospitals) {
      markers.add(
        Marker(
          point: hospital.location,
          width: 54,
          height: 60,
          child: GestureDetector(
            onTap: () {
              _showHospitalDetails(hospital);
            },
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hospital.schemeSupported
                        ? const Color(0xFF087F73)
                        : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _patientLocation,
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
        ),

        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              _mapButton(
                icon: Icons.my_location,
                onPressed: () {
                  _mapController.move(
                    _patientLocation,
                    14,
                  );
                },
              ),
              const SizedBox(height: 10),
              _mapButton(
                icon: Icons.add,
                onPressed: () {
                  _mapController.move(
                    _patientLocation,
                    15,
                  );
                },
              ),
              const SizedBox(height: 6),
              _mapButton(
                icon: Icons.remove,
                onPressed: () {
                  _mapController.move(
                    _patientLocation,
                    10,
                  );
                },
              ),
            ],
          ),
        ),

        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Color(0xFF087F73),
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Patient location',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            color: const Color(0xFF087F73),
          ),
        ),
      ),
    );
  }

  Widget _hospitalList() {
    return Container(
      color: const Color(0xFFF5F9F8),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          24,
        ),
        itemCount: _hospitals.length,
        itemBuilder: (context, index) {
          final hospital = _hospitals[index];

          final distance = _distance(
            _patientLocation,
            hospital.location,
          );

          return Container(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE0E9E6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                          color: const Color(0xFFE1F3EF),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Color(0xFF087F73),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hospital.type,
                              style: const TextStyle(
                                color: Color(0xFF087F73),
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    hospital.address,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _formatDistance(distance),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showHospitalDetails(
                              hospital,
                            );
                          },
                          icon: const Icon(
                            Icons.info_outline,
                            size: 18,
                          ),
                          label: const Text(
                            'DETAILS',
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            _openDirections(
                              hospital,
                            );
                          },
                          icon: const Icon(
                            Icons.directions,
                            size: 18,
                          ),
                          label: const Text(
                            'DIRECTIONS',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF087F73),
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
      ),
    );
  }

  void _showHospitalDetails(
    _DemoHospital hospital,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  hospital.type,
                  style: const TextStyle(
                    color: Color(0xFF087F73),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  hospital.address,
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6F3),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: Color(0xFF087F73),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo facility for Vission Health presentation. Verify actual scheme participation before visiting.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openDirections(hospital);
                    },
                    icon: const Icon(
                      Icons.directions,
                    ),
                    label: const Text(
                      'GET DIRECTIONS',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF087F73),
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

  Future<void> _openDirections(
    _DemoHospital hospital,
  ) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=fossgis_osrm_car'
      '&route=${_patientLocation.latitude},'
      '${_patientLocation.longitude};'
      '${hospital.location.latitude},'
      '${hospital.location.longitude}',
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open directions.',
          ),
        ),
      );
    }
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

  String _formatDistance(
    double meters,
  ) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}

class _DemoHospital {
  final String name;
  final String type;
  final String address;
  final LatLng location;
  final bool schemeSupported;

  const _DemoHospital({
    required this.name,
    required this.type,
    required this.address,
    required this.location,
    required this.schemeSupported,
  });
}
