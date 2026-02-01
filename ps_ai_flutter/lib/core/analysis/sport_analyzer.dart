import '../../models/analysis_data.dart';

/// Abstract base class for all sport analyzers.
abstract class SportAnalyzer {
  /// Analyzes the input stream and emits feedback.
  /// This allows for stateful analysis (e.g., detecting a sequence of movements).
  Stream<FeedbackOutput> analyze(Stream<AnalysisInput> input);

  AnalysisSummary? get currentSummary; // Returns current stats like reps

  void dispose();
}

class AnalysisSummary {
  final int reps;
  final double avgScore;
  final String exerciseType;
  final DateTime? startTime;
  final Duration? duration;

  AnalysisSummary({
    this.reps = 0,
    this.avgScore = 0.0,
    required this.exerciseType,
    this.startTime,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'avgScore': avgScore,
    'exerciseType': exerciseType,
    'startTime': startTime?.toIso8601String(),
    'durationMs': duration?.inMilliseconds,
  };
}
