import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/analysis_data.dart';
import 'sport_analyzer.dart';

class SquatAnalyzer extends SportAnalyzer {
  final StreamController<FeedbackOutput> _outputController =
      StreamController<FeedbackOutput>.broadcast();
  StreamSubscription? _inputSubscription;

  final String exerciseType;
  final Color baseColor;
  DateTime? _startTime;
  bool _instructionShown = false;

  SquatAnalyzer({
    required this.exerciseType,
    required this.baseColor,
  }) {
    _startTime = DateTime.now();
  }

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

    // Initial Instruction Phase
    if (!_instructionShown) {
      final elapsed = DateTime.now().difference(_startTime!);
      if (elapsed.inSeconds < 3) {
        _outputController.add(
          GymFeedback(
            score: 0.0,
            indicatorColor: baseColor,
            message: "Face the camera", // Generic instruction
            exerciseType: exerciseType,
            phase: "Setup",
          ),
        );
        return;
      } else {
        _instructionShown = true;
      }
    }

    // Determine if we have a person
    if (input.poses.isEmpty) {
      _outputController.add(
        GymFeedback(
          score: 0.0,
          indicatorColor: Colors.grey,
          message: "Step into frame",
          exerciseType: exerciseType,
        ),
      );
      return;
    }

    // final pose = input.poses.first;
    // Simple heuristic for now: detect if standing
    // In future: normalization, hip/knee angles, DTW

    // Mock analysis logic
    double score = 0.8;
    String message = "Good form";
    String phase = "Standing";

    // TODO: Implement real squat analysis (State Machine + DTW)

    if (!_outputController.isClosed) {
      _outputController.add(
        GymFeedback(
          score: score,
          indicatorColor: baseColor,
          message: message,
          exerciseType: exerciseType,
          phase: phase,
          reps: 0, // TODO: Implement rep counter
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
