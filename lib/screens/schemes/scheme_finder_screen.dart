import 'package:flutter/material.dart';

import '../../services/scheme_service.dart';

class SchemeFinderScreen extends StatefulWidget {
  final int age;
  final String gender;
  final String situation;

  const SchemeFinderScreen({
    super.key,
    this.age = 0,
    this.gender = '',
    this.situation = '',
  });

  @override
  State<SchemeFinderScreen> createState() =>
      _SchemeFinderScreenState();
}

class _SchemeFinderScreenState
    extends State<SchemeFinderScreen> {
  bool loading = true;
  String? error;
  List<dynamic> schemes = [];

  @override
  void initState() {
    super.initState();
    findSchemes();
  }

  Future<void> findSchemes() async {
    try {
      final result =
          await SchemeService.findSchemes(
        age: widget.age,
        gender: widget.gender,
        situation: widget.situation,
      );

      if (!mounted) return;

      setState(() {
        schemes = result['schemes'] is List
            ? result['schemes']
            : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text(
          'Government Scheme Finder',
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? _error()
              : _results(),
    );
  }

  Widget _error() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to find schemes.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                setState(() {
                  loading = true;
                  error = null;
                });
                findSchemes();
              },
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),

          const SizedBox(height: 16),

          if (schemes.isEmpty)
            _empty()
          else
            ...schemes.map(
              (scheme) => _schemeCard(
                Map<String, dynamic>.from(
                  scheme,
                ),
              ),
            ),

          const SizedBox(height: 12),

          _disclaimer(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.account_balance,
            size: 42,
            color: Color(0xFF087F73),
          ),
          SizedBox(height: 10),
          Text(
            'Government Health Schemes',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Preliminary scheme information based on the patient details.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _schemeCard(
    Map<String, dynamic> scheme,
  ) {
    final documents =
        scheme['documents'] is List
            ? (scheme['documents'] as List)
                .map((e) => e.toString())
                .toList()
            : <String>[];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scheme['name']?.toString() ??
                'Government Scheme',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _item(
            'Description',
            scheme['description'],
          ),

          _item(
            'Why it may apply',
            scheme['why_eligible'],
          ),

          if (documents.isNotEmpty)
            _item(
              'Documents',
              documents.join(', '),
            ),

          _item(
            'Where to apply',
            scheme['where_to_apply'],
          ),

          _item(
            'Next action',
            scheme['action'],
          ),
        ],
      ),
    );
  }

  Widget _item(
    String title,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString().isNotEmpty == true
                ? value.toString()
                : 'Not specified',
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'No scheme information was returned. '
        'Manual verification is recommended.',
        style: TextStyle(
          height: 1.5,
        ),
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '⚠️ Scheme eligibility is not confirmed by AI. '
        'Verify eligibility and current requirements with the official government source or PHC.',
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
