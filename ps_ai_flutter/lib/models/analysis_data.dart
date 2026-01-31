import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'tracking_data.dart';

/// Sealed class representing the input data for analysis.
/// This allows for different input structures depending on requirements.
sealed class AnalysisInput {
  final DateTime timestamp;
  final TrackingSession session;
  const AnalysisInput(this.timestamp, this.session);
}

/// Standard input containing live capture data and the current session context.
class LiveAnalysisInput extends AnalysisInput {
  final List<Pose> poses;
  final List<DetectedObject> objects;

  LiveAnalysisInput({
    required this.poses,
    required this.objects,
    required TrackingSession session,
  }) : super(DateTime.now(), session);
}

/// Sealed class representing the output feedback from analysis.
sealed class FeedbackOutput {
  final double score; // 0.0 to 1.0
  final Color indicatorColor;
  final String message;
  final String? animationEvent;

  const FeedbackOutput({
    required this.score,
    required this.indicatorColor,
    required this.message,
    this.animationEvent,
  });
}

/// General feedback subclass for standard usage.
class GeneralFeedback extends FeedbackOutput {
  const GeneralFeedback({
    required super.score,
    required super.indicatorColor,
    required super.message,
    super.animationEvent,
  });
}

/// Specialized feedback for Basketball Shooting.
/// Can contain extra metrics like arc angle, release time, etc.
class BasketballShootingFeedback extends FeedbackOutput {
  final double? releaseAngle;
  final double? shotArc;

  const BasketballShootingFeedback({
    required super.score,
    required super.indicatorColor,
    required super.message,
    super.animationEvent,
    this.releaseAngle,
    this.shotArc,
  });
}

/// Specialized feedback for Gym Exercises (Squats, Curls, etc.)
class GymFeedback extends FeedbackOutput {
  final String exerciseType;
  final int? reps;
  final String? phase; // e.g. "Descending", "Ascending"

  const GymFeedback({
    required super.score,
    required super.indicatorColor,
    required super.message,
    super.animationEvent,
    required this.exerciseType,
    this.reps,
    this.phase,
  });
}
