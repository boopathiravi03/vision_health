import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CommunityHealthScreen extends StatefulWidget {
  const CommunityHealthScreen({
    super.key,
  });

  @override
  State<CommunityHealthScreen> createState() =>
      _CommunityHealthScreenState();
}

class _CommunityHealthScreenState
    extends State<CommunityHealthScreen> {
  final DatabaseReference _patientsRef =
      FirebaseDatabase.instance.ref('patients');

  List<Map<String, dynamic>> patients = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      setState(() {
        patients = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  int get totalPatients =>
      patients.length;

  int get highRiskPatients {
    return patients.where((patient) {
      final risk =
          patient['riskLevel']
              ?.toString()
              .toLowerCase();

      return risk == 'high' ||
          risk == 'urgent' ||
          risk == 'critical' ||
          risk == 'emergency';
    }).length;
  }

  int get followUpPatients {
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

  int get schemePatients {
    return patients.where((patient) {
      final recommendation =
          patient['aiRecommendation']
              ?.toString();

      return recommendation != null &&
          recommendation.isNotEmpty;
    }).length;
  }

  Map<String, int> get symptomCounts {
    final counts =
        <String, int>{};

    for (final patient in patients) {
      final symptoms =
          patient['symptoms']
              ?.toString()
              .toLowerCase();

      if (symptoms == null ||
          symptoms.isEmpty) {
        continue;
      }

      final keywords = [
        'fever',
        'cough',
        'cold',
        'respiratory',
        'skin',
        'pain',
        'weakness',
        'headache',
        'stomach',
        'diabetes',
        'blood pressure',
      ];

      for (final keyword in keywords) {
        if (symptoms.contains(keyword)) {
          counts[keyword] =
              (counts[keyword] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  Map<String, int> get villageCounts {
    final counts =
        <String, int>{};

    for (final patient in patients) {
      final village =
          patient['village']
              ?.toString();

      if (village == null ||
          village.isEmpty) {
        continue;
      }

      counts[village] =
          (counts[village] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text(
          'Community Health',
        ),

        actions: [
          IconButton(
            onPressed: _loadData,
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
              onRefresh: _loadData,

              child: ListView(
                padding:
                    const EdgeInsets.all(16),

                children: [
                  _headerCard(),

                  const SizedBox(height: 18),

                  _statistics(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Common Health Issues',
                  ),

                  const SizedBox(height: 10),

                  _symptomsCard(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Village Distribution',
                  ),

                  const SizedBox(height: 10),

                  _villageCard(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Health Insights',
                  ),

                  const SizedBox(height: 10),

                  _insightsCard(),
                ],
              ),
            ),
    );
  }

  Widget _headerCard() {
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
            Icons.analytics_outlined,
            color: Colors.white,
            size: 35,
          ),

          SizedBox(height: 12),

          Text(
            'Village Health Intelligence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Understand emerging health patterns and prioritize community-level action.',
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
    return GridView.count(
      crossAxisCount: 2,

      crossAxisSpacing: 10,

      mainAxisSpacing: 10,

      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      childAspectRatio: 1.55,

      children: [
        _statCard(
          'Total Patients',
          totalPatients.toString(),
          Icons.people,
        ),

        _statCard(
          'High Risk',
          highRiskPatients.toString(),
          Icons.warning_amber,
        ),

        _statCard(
          'Follow-ups',
          followUpPatients.toString(),
          Icons.event_repeat,
        ),

        _statCard(
          'Benefit Opportunities',
          schemePatients.toString(),
          Icons.account_balance,
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
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color:
                  const Color(0xFFE8F6F3),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              icon,
              color:
                  const Color(0xFF087F73),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight:
            FontWeight.bold,
      ),
    );
  }

  Widget _symptomsCard() {
    final counts =
        symptomCounts.entries.toList();

    counts.sort(
      (a, b) =>
          b.value.compareTo(a.value),
    );

    if (counts.isEmpty) {
      return _emptyCard(
        'Not enough symptom data yet.',
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        children: counts
            .take(6)
            .map(
              (item) =>
                  _progressRow(
                item.key,
                item.value,
                totalPatients,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _progressRow(
    String label,
    int count,
    int total,
  ) {
    final percentage =
        total == 0
            ? 0.0
            : count / total;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _capitalize(label),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '$count cases',
                style:
                    const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),

            child:
                LinearProgressIndicator(
              value: percentage
                  .clamp(0.0, 1.0),

              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _villageCard() {
    final counts =
        villageCounts.entries.toList();

    counts.sort(
      (a, b) =>
          b.value.compareTo(a.value),
    );

    if (counts.isEmpty) {
      return _emptyCard(
        'No village information available.',
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        children: counts
            .take(8)
            .map(
              (item) => ListTile(
                contentPadding:
                    EdgeInsets.zero,

                leading: CircleAvatar(
                  backgroundColor:
                      const Color(
                    0xFFE8F6F3,
                  ),

                  child: const Icon(
                    Icons.location_on,
                    color:
                        Color(0xFF087F73),
                  ),
                ),

                title: Text(
                  item.key,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                trailing: Text(
                  '${item.value}',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _insightsCard() {
    final insights =
        <String>[];

    if (highRiskPatients > 0) {
      insights.add(
        '$highRiskPatients patient(s) require priority clinical review.',
      );
    }

    if (followUpPatients > 0) {
      insights.add(
        '$followUpPatients patient(s) need follow-up.',
      );
    }

    if (schemePatients > 0) {
      insights.add(
        '$schemePatients patient(s) have benefit/recommendation information.',
      );
    }

    final symptoms =
        symptomCounts.entries.toList();

    symptoms.sort(
      (a, b) =>
          b.value.compareTo(a.value),
    );

    if (symptoms.isNotEmpty) {
      insights.add(
        '${_capitalize(symptoms.first.key)} is the most frequently detected symptom in the current dataset.',
      );
    }

    if (insights.isEmpty) {
      insights.add(
        'More patient records are required to generate community insights.',
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        children: insights
            .map(
              (text) => Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color:
                          Color(0xFF087F73),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        text,
                        style:
                            const TextStyle(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _emptyCard(
    String text,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }

  String _capitalize(
    String value,
  ) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() +
        value.substring(1);
  }
}
