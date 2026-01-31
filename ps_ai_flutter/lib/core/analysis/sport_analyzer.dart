import '../../models/analysis_data.dart';

/// Abstract base class for all sport analyzers.
abstract class SportAnalyzer {
  /// Analyzes the input stream and emits feedback.
  /// This allows for stateful analysis (e.g., detecting a sequence of movements).
  Stream<FeedbackOutput> analyze(Stream<AnalysisInput> input);

  void dispose() {}
}
