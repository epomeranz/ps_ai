import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/capture_provider.dart';
import '../../models/analysis_data.dart';
import '../analysis/sport_analyzer.dart';
import '../analysis/basketball_analyzer.dart';
import '../analysis/squat_analyzer.dart';

// Re-export specific feedback types for consumers
export '../../models/analysis_data.dart';

class FeedbackService {
  final StreamController<AnalysisInput> _inputController =
      StreamController<AnalysisInput>.broadcast();
  SportAnalyzer? _currentAnalyzer;
  StreamSubscription? _analyzerSubscription;

  // Main output stream
  final StreamController<FeedbackOutput> _outputController =
      StreamController<FeedbackOutput>.broadcast();
  Stream<FeedbackOutput> get feedbackStream => _outputController.stream;

  FeedbackService() {
    setAnalyzerConfig('basketball', 'shooting', Colors.orange); // Default
  }

  void setAnalyzerConfig(
    String sportType,
    String exerciseType,
    Color baseColor,
  ) {
    _analyzerSubscription?.cancel();
    _currentAnalyzer?.dispose();

    // Factory logic
    if (sportType == 'basketball') {
      _currentAnalyzer = BasketballShootingAnalyzer();
    } else if (sportType == 'gym') {
      _currentAnalyzer = SquatAnalyzer(
        exerciseType: exerciseType,
        baseColor: baseColor,
      );
    } else {
      // Fallback to generic squat/gym analyzer if unknown, or maybe a truly generic one
      // For now, assuming gym/squat as fallback for this context
      _currentAnalyzer = SquatAnalyzer(
        exerciseType: exerciseType,
        baseColor: baseColor,
      );
    }

    // Connect pipelines
    if (_currentAnalyzer != null) {
      _analyzerSubscription = _currentAnalyzer!
          .analyze(_inputController.stream)
          .listen((output) {
            _outputController.add(output);
          });
    }
  }

  void analyzeFrame(CaptureState captureState) {
    if (captureState.status != CaptureStatus.recording) return;

    // Convert CaptureState to AnalysisInput
    final input = LiveAnalysisInput(
      poses: captureState.poses,
      objects: captureState.objects,
      session: captureState.currentSession!,
    );

    _inputController.add(input);
  }

  void dispose() {
    _analyzerSubscription?.cancel();
    _currentAnalyzer?.dispose();
    _inputController.close();
    _outputController.close();
  }
}
