import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/capture_provider.dart';

class FeedbackState {
  final double score; // 0.0 to 1.0
  final Color indicatorColor;
  final String message;
  final String? animationEvent; // e.g., "congrats", "heart"

  const FeedbackState({
    required this.score,
    required this.indicatorColor,
    required this.message,
    this.animationEvent,
  });

  factory FeedbackState.initial() {
    return const FeedbackState(
      score: 0.0,
      indicatorColor: Colors.grey,
      message: 'Get ready...',
    );
  }
}

class FeedbackService {
  final StreamController<FeedbackState> _controller =
      StreamController<FeedbackState>.broadcast();

  Stream<FeedbackState> get feedbackStream => _controller.stream;

  void analyzeFrame(CaptureState captureState) {
    if (captureState.status != CaptureStatus.recording) {
      // Emit idle state if needed, or just return
      return;
    }

    // Simplified analysis logic for demo purposes
    // In a real app, this would involve complex ML heuristics

    double score = 0.0;
    Color color = Colors.red;
    String message = "Keep going!";
    String? animation;

    if (captureState.poses.isNotEmpty) {
      // Mock logic: calculate score based on pose visibility confidence
      final pose = captureState.poses.first;
      final confidence =
          pose.landmarks.values
              .map((l) => l.likelihood)
              .reduce((a, b) => a + b) /
          pose.landmarks.length;

      score = confidence;

      if (score > 0.8) {
        color = Colors.green;
        message = "Excellent form!";
        if (DateTime.now().second % 10 == 0) {
          // Occasional animation
          animation = "congrats";
        }
      } else if (score > 0.5) {
        color = Colors.yellow;
        message = "Good, keep stabilizing.";
      } else {
        color = Colors.red;
        message = "Adjust your position.";
      }
    } else {
      message = "No person detected.";
    }

    _controller.add(
      FeedbackState(
        score: score,
        indicatorColor: color,
        message: message,
        animationEvent: animation,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}
