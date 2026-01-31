import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import 'sport_analyzer.dart';

class BasketballShootingAnalyzer extends SportAnalyzer {
  final StreamController<FeedbackOutput> _outputController =
      StreamController<FeedbackOutput>.broadcast();
  StreamSubscription? _inputSubscription;

  @override
  Stream<FeedbackOutput> analyze(Stream<AnalysisInput> input) {
    _inputSubscription = input.listen((data) {
      if (data is LiveAnalysisInput) {
        _analyzeFrame(data);
      }
    });

    return _outputController.stream;
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

    double score = confidence;
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
    super.dispose();
  }
}
