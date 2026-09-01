class VisionResult {
  final bool imageQualityGood;
  final String observation;
  final List<String> visibleIndicators;
  final String urgency;
  final String recommendation;
  final String disclaimer;

  VisionResult({
    required this.imageQualityGood,
    required this.observation,
    required this.visibleIndicators,
    required this.urgency,
    required this.recommendation,
    required this.disclaimer,
  });

  factory VisionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return VisionResult(
      imageQualityGood:
          json['image_quality_good'] ?? false,
      observation:
          json['observation'] ?? '',
      visibleIndicators:
          List<String>.from(
        json['visible_indicators'] ?? [],
      ),
      urgency:
          json['urgency'] ?? 'Unknown',
      recommendation:
          json['recommendation'] ?? '',
      disclaimer:
          json['disclaimer'] ?? '',
    );
  }
}
