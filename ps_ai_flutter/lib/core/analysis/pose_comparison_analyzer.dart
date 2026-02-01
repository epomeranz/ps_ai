import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../models/analysis_data.dart';
import '../../models/tracking_data.dart';
import '../utils/pose_utils.dart';
import 'sport_analyzer.dart';

enum AnalysisState {
  resting,
  descending,
  peak,
  ascending,
}

/// A generic analyzer that compares live performance against a recorded reference.
class PoseComparisonAnalyzer extends SportAnalyzer {
  final TrackingSession? referenceSession;
  final String exerciseType;
  final Color baseColor;

  // State Machine
  AnalysisState _currentState = AnalysisState.resting;
  int _reps = 0;
  final List<double> _scores = [];
  DateTime? _startTime;

  // Audio Throttling
  DateTime _lastSpokenTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _audioInterval = const Duration(seconds: 3);

  // Thresholds (Default values, can be overridden or loaded from metadata)
  final double _descentThresholdAngle = 160.0; // Knee angle to start descent
  final double _peakThresholdAngle = 90.0; // Target depth
  final double _ascentThresholdAngle = 160.0; // Knee angle to finish rep

  final StreamController<FeedbackOutput> _outputController =
      StreamController<FeedbackOutput>.broadcast();
  StreamSubscription? _inputSubscription;

  PoseComparisonAnalyzer({
    required this.exerciseType,
    required this.baseColor,
    this.referenceSession,
  });

  @override
  Stream<FeedbackOutput> analyze(Stream<AnalysisInput> input) {
    _startTime = DateTime.now(); // Start time for the session
    _inputSubscription = input.listen((data) {
      if (data is LiveAnalysisInput) {
        _analyzeFrame(data);
      }
    });
    return _outputController.stream;
  }

  @override
  AnalysisSummary get currentSummary {
    final double averageScore = _scores.isEmpty
        ? 0.0
        : _scores.reduce((a, b) => a + b) / _scores.length;
    final Duration totalDuration = _startTime == null
        ? Duration.zero
        : DateTime.now().difference(_startTime!);

    return AnalysisSummary(
      exerciseType: exerciseType,
      reps: _reps,
      avgScore: averageScore,
      duration: totalDuration,
      startTime: _startTime,
    );
  }

  void _analyzeFrame(LiveAnalysisInput input) {
    if (_outputController.isClosed) return;

    if (input.poses.isEmpty) {
      _emitFeedback(0.0, "Step into frame", Colors.grey);
      return;
    }

    final rawPose = input.poses.first;

    // 1. Normalize the current pose
    final normalizedLandmarks = PoseUtils.normalizePose(rawPose);

    // 2. State Machine Logic (Simplistic Squat Logic for now,
    //    can be made generic if we pass in a StateDeterminer strategy)
    //    Using average knee angle.
    final leftKneeAngle = _getAngle(
      rawPose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    );
    final rightKneeAngle = _getAngle(
      rawPose,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

    _updateState(avgKneeAngle);

    // 3. Compare with Reference
    double matchScore = 1.0;
    String feedbackMsg = "Good form";
    Color visualColor = baseColor;

    if (referenceSession != null && referenceSession!.frames.isNotEmpty) {
      // Find the closest matching frame in reference based on current progress/state
      // For simplicity in this iteration: find the frame with closest knee angle in similar state
      // OR just compare against the "Ideal" trajectory using Euclidean distance if we can map time.

      // Let's us a simple Nearest Neighbor search in the reference session
      // based on the primary driving joint (Knee Angle here).
      final bestMatchDistance = _compareWithReference(normalizedLandmarks);

      // Convert distance to score (0.0 to 1.0)
      // Heuristic: dist=0 -> score=1.0, dist>0.5 -> score=0.0
      matchScore = (1.0 - (bestMatchDistance * 2)).clamp(0.0, 1.0);

      _scores.add(matchScore);

      if (matchScore < 0.7) {
        feedbackMsg = "Adjust form";
        visualColor = Colors.orange;
      }
      if (matchScore < 0.4) {
        feedbackMsg = "Wrong form";
        visualColor = Colors.red;
      }
    }

    // Audio Logic
    String? audioMsg;
    if (matchScore < 0.7) {
      final now = DateTime.now();
      if (now.difference(_lastSpokenTime) > _audioInterval) {
        audioMsg =
            feedbackMsg; // Speak the visual message or a specific correction
        _lastSpokenTime = now;
      }
    }

    _emitFeedback(
      matchScore,
      feedbackMsg,
      visualColor,
      phase: _currentState.name,
      audioMsg: audioMsg,
    );
  }

  void _updateState(double kneeAngle) {
    // Simple state transitions
    switch (_currentState) {
      case AnalysisState.resting:
        if (kneeAngle < _descentThresholdAngle) {
          _currentState = AnalysisState.descending;
        }
        break;
      case AnalysisState.descending:
        if (kneeAngle <= _peakThresholdAngle) {
          _currentState = AnalysisState.peak;
        } else if (kneeAngle > _descentThresholdAngle) {
          // Aborted rep
          _currentState = AnalysisState.resting;
        }
        break;
      case AnalysisState.peak:
        if (kneeAngle > _peakThresholdAngle + 15) {
          // Hysteresis
          _currentState = AnalysisState.ascending;
        }
        break;
      case AnalysisState.ascending:
        if (kneeAngle > _ascentThresholdAngle) {
          _reps++;
          _currentState = AnalysisState.resting;
        }
        break;
    }
  }

  double _compareWithReference(Map<int, List<double>> currentNormalizedPose) {
    // Simple exhaustive search for the closest pose in the reference set.
    // This is computationally expensive (O(N)), but N (frames in one rep) is small (~100).
    // In future, optimize by searching only frames within the current 'State' bucket.

    double minDistance = double.infinity;

    for (var frame in referenceSession!.frames) {
      // Assuming reference frames have one person with normalized landmarks
      if (frame.people.isEmpty) continue;

      final refPerson = frame.people.first;
      final dist = PoseUtils.calculateEuclideanDistance(
        currentNormalizedPose,
        refPerson.landmarks,
      );

      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  double _getAngle(
    Pose pose,
    PoseLandmarkType a,
    PoseLandmarkType b,
    PoseLandmarkType c,
  ) {
    final la = pose.landmarks[a];
    final lb = pose.landmarks[b];
    final lc = pose.landmarks[c];
    if (la == null || lb == null || lc == null) return 180.0;
    return PoseUtils.calculateAngle(la, lb, lc);
  }

  void _emitFeedback(
    double score,
    String message,
    Color color, {
    String? phase,
    String? audioMsg,
  }) {
    if (!_outputController.isClosed) {
      _outputController.add(
        GymFeedback(
          score: score,
          indicatorColor: color,
          message: message,
          exerciseType: exerciseType,
          phase: phase,
          reps: _reps,
          audioMessage: audioMsg,
        ),
      );
    }
  }

  @override
  void dispose() {
    _inputSubscription?.cancel();
    _outputController.close();
  }
}
