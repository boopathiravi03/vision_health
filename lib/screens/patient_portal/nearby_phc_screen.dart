import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPhcScreen extends StatefulWidget {
  final String initialLocation;

  const NearbyPhcScreen({super.key, this.initialLocation = ''});

  @override
  State<NearbyPhcScreen> createState() => _NearbyPhcScreenState();
}

class _NearbyPhcScreenState extends State<NearbyPhcScreen> {
  late final TextEditingController _locationController;
  bool _openingMaps = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialLocation);
  }

  Future<void> _findPhcs() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your village, town, or PIN code.')),
      );
      return;
    }

    setState(() => _openingMaps = true);
    final query = Uri.encodeComponent('Primary Health Centre near $location');
    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      final opened = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open maps on this device.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingMaps = false);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(title: const Text('Find Nearby PHC')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 46,
                    color: Color(0xFF087F73),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Find a Primary Health Centre',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search maps for nearby PHCs, addresses, directions and opening details.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Village, town, or PIN code',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _findPhcs(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openingMaps ? null : _findPhcs,
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  _openingMaps ? 'OPENING MAPS...' : 'SEARCH NEARBY PHCS',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Confirm the facility’s services and hours before travelling. For an emergency, seek urgent local help.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
