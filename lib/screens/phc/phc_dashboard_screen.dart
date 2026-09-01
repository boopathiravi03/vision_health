import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'community_health_screen.dart';
import 'phc_alerts_screen.dart';
import 'qr_scanner_screen.dart';

class PhcDashboardScreen extends StatefulWidget {
  const PhcDashboardScreen({
    super.key,
  });

  @override
  State<PhcDashboardScreen> createState() =>
      _PhcDashboardScreenState();
}

class _PhcDashboardScreenState
    extends State<PhcDashboardScreen> {
  final DatabaseReference _patientsRef =
      FirebaseDatabase.instance.ref('patients');

  List<Map<String, dynamic>> patients = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final snapshot =
          await _patientsRef.get();

      if (!snapshot.exists) {
        setState(() {
          patients = [];
          loading = false;
        });
        return;
      }

      final data =
          Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final result = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        if (value is Map) {
          result.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(
              value,
            ),
          });
        }
      });

      setState(() {
        patients = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load patients: $e',
          ),
        ),
      );
    }
  }

  int get urgentCount {
    return patients.where((patient) {
      final risk =
          patient['riskLevel']
              ?.toString()
              .toLowerCase();

      return risk == 'high' ||
          risk == 'urgent' ||
          risk == 'critical';
    }).length;
  }

  int get followUpCount {
    return patients.where((patient) {
      final risk =
          patient['riskLevel']
              ?.toString()
              .toLowerCase();

      return risk == 'medium' ||
          risk == 'follow-up' ||
          risk == 'followup';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text(
          'PHC Dashboard',
        ),

        actions: [
          IconButton(
            tooltip: 'PHC Alerts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const PhcAlertsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_active,
            ),
          ),
          IconButton(
            onPressed: _loadPatients,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadPatients,

              child: ListView(
                padding:
                    const EdgeInsets.all(16),

                children: [
                  _welcomeCard(),

                  const SizedBox(height: 18),

                _statistics(),

                const SizedBox(height: 18),

                _communityHealthCard(context),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const QrScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.qr_code_scanner,
                    ),
                    label: const Text(
                      'SCAN HEALTH PASSPORT',
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                    'Priority Cases',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (patients.isEmpty)
                    _emptyState()
                  else
                    ...patients.map(
                      (patient) =>
                          _patientCard(
                        patient,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(22),

        gradient: const LinearGradient(
          colors: [
            Color(0xFF087F73),
            Color(0xFF0C9B8C),
          ],
        ),
      ),

      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.local_hospital,
            color: Colors.white,
            size: 34,
          ),

          SizedBox(height: 12),

          Text(
            'Welcome, PHC Team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Monitor rural patients and prioritize cases requiring attention.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statistics() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Patients',
            patients.length.toString(),
            Icons.people,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            'Urgent',
            urgentCount.toString(),
            Icons.warning_amber,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            'Follow-up',
            followUpCount.toString(),
            Icons.event_repeat,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 10,
      ),

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
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF087F73),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(
    Map<String, dynamic> patient,
  ) {
    final name =
        patient['name']?.toString() ??
            'Unknown Patient';

    final village =
        patient['village']?.toString() ??
            'Village not available';

    final risk =
        patient['riskLevel']?.toString() ??
            'Unknown';

    final age =
        patient['age']?.toString() ??
            '--';

    final isUrgent =
        risk.toLowerCase() == 'high' ||
        risk.toLowerCase() == 'urgent' ||
        risk.toLowerCase() == 'critical';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: const BorderSide(
          color:
              Color(0xFFE0E9E6),
        ),
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.all(14),

        leading: CircleAvatar(
          radius: 25,

          backgroundColor:
              isUrgent
                  ? Colors.red
                      .withValues(alpha: .12)
                  : const Color(
                      0xFFE8F6F3,
                    ),

          child: Icon(
            isUrgent
                ? Icons.priority_high
                : Icons.person,
            color: isUrgent
                ? Colors.red
                : const Color(
                    0xFF087F73,
                  ),
          ),
        ),

        title: Text(
          name,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 5,
          ),

          child: Text(
            '$age years • $village',
          ),
        ),

        trailing: _riskBadge(risk),

        onTap: () {
          _showPatientDetails(
            patient,
          );
        },
      ),
    );
  }

  Widget _riskBadge(String risk) {
    final lower =
        risk.toLowerCase();

    final urgent =
        lower == 'high' ||
        lower == 'urgent' ||
        lower == 'critical';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: urgent
            ? Colors.red.withValues(alpha: .1)
            : const Color(0xFFE8F6F3),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        risk.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
          color: urgent
              ? Colors.red
              : const Color(
                  0xFF087F73,
                ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding:
          const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 50,
            color: Colors.grey,
          ),

          SizedBox(height: 10),

          Text(
            'No patient records yet',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Patients registered by ASHA workers will appear here.',
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

  void _showPatientDetails(
    Map<String, dynamic> patient,
  ) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (_) {
        return Padding(
          padding:
              const EdgeInsets.all(22),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Patient Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              _detailRow(
                'Name',
                patient['name'],
              ),

              _detailRow(
                'Age',
                patient['age'],
              ),

              _detailRow(
                'Gender',
                patient['gender'],
              ),

              _detailRow(
                'Village',
                patient['village'],
              ),

              _detailRow(
                'Risk',
                patient['riskLevel'],
              ),

              _detailRow(
                'Symptoms',
                patient['symptoms'],
              ),

              if (patient[
                      'aiRecommendation'] !=
                  null)
                _detailRow(
                  'AI Recommendation',
                  patient[
                      'aiRecommendation'],
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    'CLOSE',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    dynamic value,
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
          SizedBox(
            width: 125,

            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value?.toString() ??
                  'Not available',

              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityHealthCard(
    BuildContext context,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: const BorderSide(
          color:
              Color(0xFFE0E9E6),
        ),
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.all(16),

        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F3),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color:
                Color(0xFF087F73),
          ),
        ),

        title: const Text(
          'Community Health Intelligence',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle: const Text(
          'Village-level health patterns, symptoms, and insights',
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const CommunityHealthScreen(),
            ),
          );
        },
      ),
    );
  }
}
