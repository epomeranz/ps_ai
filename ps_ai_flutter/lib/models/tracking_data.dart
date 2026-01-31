import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Configuration for a specific object type to track
class TrackedObjectTypeConfig {
  final String label; // e.g., "Ball", "Person"
  final int expectedCount; // How many do we look for?
  final DetectedObject?
  filter; // Optional filter criteria (e.g. classification)

  TrackedObjectTypeConfig({
    required this.label,
    this.expectedCount = 1,
    this.filter,
  });
}

/// Represents a detected object at a specific point in time
class TrackedObject {
  final int? trackingId;
  final String label;
  final double x; // Center X (normalized 0.0-1.0)
  final double y; // Center Y (normalized 0.0-1.0)
  final double w; // Width (normalized)
  final double h; // Height (normalized)
  final double confidence; // Confidence score

  TrackedObject({
    this.trackingId,
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'id': trackingId,
    'label': label,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'c': confidence,
  };
}

/// Represents a detected person (pose)
class TrackedPerson {
  final int? id; // Assigned by us or MLKit (if using pose tacker)
  final Map<int, List<double>> landmarks; // Type -> [x, y, z, confidence]

  TrackedPerson({
    this.id,
    required this.landmarks,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'landmarks': landmarks.map((k, v) => MapEntry(k.toString(), v)),
  };

  static TrackedPerson fromPose(Pose pose, {int? id}) {
    final Map<int, List<double>> lm = {};
    pose.landmarks.forEach((type, landmark) {
      lm[type.index] = [
        landmark.x,
        landmark.y,
        landmark.z,
        landmark.likelihood,
      ];
    });
    return TrackedPerson(id: id, landmarks: lm);
  }
}

/// A single frame of data
class FrameData {
  final int timestampMs; // Milliseconds from session start
  final List<TrackedObject> objects;
  final List<TrackedPerson> people;

  FrameData({
    required this.timestampMs,
    this.objects = const [],
    this.people = const [],
  });

  Map<String, dynamic> toJson() => {
    'ts': timestampMs,
    'objects': objects.map((o) => o.toJson()).toList(),
    'people': people.map((p) => p.toJson()).toList(),
  };
}

/// The entire recording session
class TrackingSession {
  final String sessionId;
  final String profileId;
  final String activePlayerId;
  final String sportType;
  final String exerciseType;
  final DateTime startTime;
  final List<FrameData> frames;

  TrackingSession({
    required this.sessionId,
    required this.profileId,
    required this.activePlayerId,
    required this.sportType,
    required this.exerciseType,
    required this.startTime,
    List<FrameData>? frames,
  }) : frames = frames ?? [];

  void addFrame(FrameData frame) {
    frames.add(frame);
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'profileId': profileId,
    'activePlayerId': activePlayerId,
    'sport': sportType,
    'exerciseType': exerciseType,
    'startTime': startTime.toIso8601String(),
    'frames': frames.map((f) => f.toJson()).toList(),
  };
}
