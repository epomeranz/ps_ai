import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import 'sport_analyzer.dart';

class BasketballShootingAnalyzer extends SportAnalyzer {
  final StreamController<FeedbackOutput> _outputController =
      StreamController<FeedbackOutput>.broadcast();
  StreamSubscription? _inputSubscription;

  double _totalScore = 0.0;
  int _frameCount = 0;
  DateTime? _startTime;

  @override
  Stream<FeedbackOutput> analyze(Stream<AnalysisInput> input) {
    _inputSubscription = input.listen((data) {
      if (data is LiveAnalysisInput) {
        _analyzeFrame(data);
      }
    });

    _startTime = DateTime.now();
    return _outputController.stream;
  }

  @override
  AnalysisSummary? get currentSummary {
    return AnalysisSummary(
      reps: 0, // Not rep based
      avgScore: _frameCount > 0 ? _totalScore / _frameCount : 0.0,
      exerciseType: 'shooting',
      startTime: _startTime,
      duration: _startTime != null
          ? DateTime.now().difference(_startTime!)
          : Duration.zero,
    );
  }

  void _analyzeFrame(LiveAnalysisInput input) {
    if (_outputController.isClosed) return;

    // Determine if we have a person
    if (input.poses.isEmpty) {
      _outputController.add(
        const BasketballShootingFeedback(
          score: 0.0,
          indicatorColor: Colors.grey,
          message: "Step into frame",
        ),
      );
      return;
    }

    final pose = input.poses.first;
    // Simple heuristic: average confidence of upper body landmarks
    // In a real implementation, you'd check for specific shooting mechanics
    final confidence =
        pose.landmarks.values.map((l) => l.likelihood).reduce((a, b) => a + b) /
        pose.landmarks.length;

    final score = confidence;
    _totalScore += score;
    _frameCount++;
    Color color = Colors.red;
    String message = "Adjust form";
    String? animation;

    // "Analysis" logic for basketball
    if (score > 0.85) {
      color = Colors.green;
      message = "Perfect Setup!";
      if (DateTime.now().second % 12 == 0) {
        animation = "congrats";
      }
    } else if (score > 0.6) {
      color = Colors.yellow;
      message = "Align your elbow";
    } else {
      color = Colors.orange;
      message = "Square your shoulders";
    }

    if (!_outputController.isClosed) {
      _outputController.add(
        BasketballShootingFeedback(
          score: score,
          indicatorColor: color,
          message: message,
          animationEvent: animation,
          releaseAngle: 45.0, // Mock data
          shotArc: 55.0, // Mock data
        ),
      );
    }
  }

  @override
  void dispose() {
    _inputSubscription?.cancel();
    _outputController.close();
    // super.dispose(); // Abstract method doesn't have body to call? Abstract class defined empty body?
    // Step 129 shows "void dispose() {}" in SportAnalyzer. So super.dispose() is valid if I revert recent changes to make it abstract.
    // But Step 130 made it "void dispose();" (abstract). So I should NOT call super.dispose().
  }
}
