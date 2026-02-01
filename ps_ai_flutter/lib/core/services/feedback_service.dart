import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ps_ai_flutter/core/services/tracking_repository.dart';
import '../providers/capture_provider.dart';
import '../../models/analysis_data.dart';
import '../../models/tracking_data.dart';
import '../analysis/sport_analyzer.dart';
import '../analysis/basketball_analyzer.dart';
import '../analysis/pose_comparison_analyzer.dart';

// Re-export specific feedback types for consumers
export '../../models/analysis_data.dart';

class FeedbackService {
  final TrackingRepository _trackingRepository;

  final StreamController<AnalysisInput> _inputController =
      StreamController<AnalysisInput>.broadcast();
  SportAnalyzer? _currentAnalyzer;
  String? _currentSportType; // Store for saving
  StreamSubscription? _analyzerSubscription;

  // Main output stream
  final StreamController<FeedbackOutput> _outputController =
      StreamController<FeedbackOutput>.broadcast();
  Stream<FeedbackOutput> get feedbackStream => _outputController.stream;

  FeedbackService(this._trackingRepository) {
    // defer default config or remove it?
    // setAnalyzerConfig('basketball', 'shooting', Colors.orange); // Default
  }

  void setAnalyzerConfig(
    String sportType,
    String exerciseType,
    Color baseColor, {
    TrackingSession? referenceSession,
  }) {
    _currentSportType = sportType;
    _analyzerSubscription?.cancel();
    _currentAnalyzer?.dispose();

    // Factory logic
    if (sportType == 'basketball') {
      _currentAnalyzer = BasketballShootingAnalyzer();
    } else if (sportType == 'gym') {
      _currentAnalyzer = PoseComparisonAnalyzer(
        exerciseType: exerciseType,
        baseColor: baseColor,
        referenceSession: referenceSession,
      );
    } else {
      // Fallback to generic comparison analyzer
      _currentAnalyzer = PoseComparisonAnalyzer(
        exerciseType: exerciseType,
        baseColor: baseColor,
        referenceSession: referenceSession,
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
    if (captureState.status != CaptureStatus.recording &&
        captureState.status != CaptureStatus.streaming) {
      return;
    }

    // Convert CaptureState to AnalysisInput
    final input = LiveAnalysisInput(
      poses: captureState.poses,
      objects: captureState.objects,
      session:
          captureState.currentSession ??
          TrackingSession(
            // Dummy session for streaming analysis
            sessionId: 'preview',
            profileId: 'preview',
            activePlayerId: 'preview',
            sportType: 'unknown',
            exerciseType: 'unknown',
            startTime: DateTime.now(),
          ),
    );

    _inputController.add(input);
  }

  Future<void> finishSession(String profileId) async {
    if (_currentAnalyzer == null || _currentSportType == null) return;

    final summary = _currentAnalyzer!.currentSummary;
    if (summary != null) {
      await _trackingRepository.saveAnalysisResult(
        profileId,
        _currentSportType!,
        summary.exerciseType,
        summary.toJson(),
      );
    }
  }

  void dispose() {
    _analyzerSubscription?.cancel();
    _currentAnalyzer?.dispose();
    _inputController.close();
    _outputController.close();
  }
}
