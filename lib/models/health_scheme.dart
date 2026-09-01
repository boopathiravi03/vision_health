class HealthScheme {
  final String id;
  final String name;
  final String description;
  final String eligibility;
  final List<String> documents;
  final List<String> steps;
  final String category;

  const HealthScheme({
    required this.id,
    required this.name,
    required this.description,
    required this.eligibility,
    required this.documents,
    required this.steps,
    required this.category,
  });
}
