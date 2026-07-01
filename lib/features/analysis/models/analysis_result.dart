class AnalysisResult {
  const AnalysisResult({
    required this.summary,
    required this.riskLevel,
    required this.labelwiseScore,
  });

  final String summary;
  final String riskLevel;
  final int labelwiseScore;
}
