import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PhcAlertsScreen extends StatefulWidget {
  const PhcAlertsScreen({
    super.key,
  });

  @override
  State<PhcAlertsScreen> createState() =>
      _PhcAlertsScreenState();
}

class _PhcAlertsScreenState
    extends State<PhcAlertsScreen> {
  final DatabaseReference _alertsRef =
      FirebaseDatabase.instance.ref('alerts');

  List<Map<String, dynamic>> alerts = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final snapshot =
          await _alertsRef.get();

      if (!snapshot.exists) {
        setState(() {
          alerts = [];
          loading = false;
        });
        return;
      }

      final raw =
          Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final result =
          <Map<String, dynamic>>[];

      raw.forEach((key, value) {
        if (value is Map) {
          result.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(
              value,
            ),
          });
        }
      });

      result.sort((a, b) {
        final aTime =
            a['createdAt'] ?? 0;

        final bTime =
            b['createdAt'] ?? 0;

        return bTime.compareTo(aTime);
      });

      setState(() {
        alerts = result;
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
            'Unable to load alerts: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markAsRead(
    String alertId,
  ) async {
    await _alertsRef
        .child(alertId)
        .update({
      'status': 'read',
    });

    await _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text(
          'PHC Alerts',
        ),

        actions: [
          IconButton(
            onPressed: _loadAlerts,
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
          : alerts.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadAlerts,

                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(16),

                    itemCount:
                        alerts.length,

                    itemBuilder:
                        (context, index) {
                      return _alertCard(
                        alerts[index],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _alertCard(
    Map<String, dynamic> alert,
  ) {
    final risk =
        alert['riskLevel']
                ?.toString()
                .toUpperCase() ??
            'HIGH';

    final patientName =
        alert['patientName']
                ?.toString() ??
            'Unknown Patient';

    final symptoms =
        alert['symptoms']
                ?.toString() ??
            'Not available';

    final village =
        alert['village']
                ?.toString() ??
            'Unknown village';

    final recommendation =
        alert['recommendation']
                ?.toString() ??
            'Seek medical evaluation.';

    final status =
        alert['status']
                ?.toString() ??
            'unread';

    final unread =
        status == 'unread';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),

        side: BorderSide(
          color: unread
              ? Colors.red
                  .withValues(alpha: .35)
              : const Color(
                  0xFFE0E9E6,
                ),
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                    10,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.red
                        .withValues(alpha: .1),

                    shape:
                        BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.warning_amber,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        'URGENT CASE',
                        style:
                            const TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        patientName,
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                _riskBadge(risk),
              ],
            ),

            const SizedBox(height: 16),

            _infoRow(
              Icons.location_on_outlined,
              village,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.medical_information_outlined,
              symptoms,
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(13),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFFFF7E6),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Icon(
                    Icons.health_and_safety,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      recommendation,
                      style:
                          const TextStyle(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (unread)
              SizedBox(
                width: double.infinity,

                child: FilledButton.icon(
                  onPressed: () {
                    _markAsRead(
                      alert['id'],
                    );
                  },

                  icon: const Icon(
                    Icons.check,
                  ),

                  label: const Text(
                    'MARK AS REVIEWED',
                  ),
                ),
              )
            else
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                  ),

                  SizedBox(width: 6),

                  Text(
                    'Reviewed by PHC',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _riskBadge(
    String risk,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.red.withValues(alpha: .1),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        risk,
        style:
            const TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 19,
          color:
              const Color(0xFF087F73),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.notifications_none,
              size: 65,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            const Text(
              'No PHC alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'High-risk cases generated by Vission Health will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
