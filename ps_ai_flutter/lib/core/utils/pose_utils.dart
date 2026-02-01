import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseUtils {
  /// Normalizes a pose by translating the mid-hip to (0,0,0) and scaling
  /// based on the shoulder width.
  ///
  /// Returns a map of landmark type index to a list of [x, y, z, likelihood].
  static Map<int, List<double>> normalizePose(Pose pose) {
    final landmarks = pose.landmarks;

    // 1. Calculate MidHip (Coordinate System Origin)
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftHip == null || rightHip == null) {
      // Fallback if hips are not visible: just return raw or empty
      // But usually for squat/fitness, hips are essential.
      return {};
    }

    final midHipX = (leftHip.x + rightHip.x) / 2;
    final midHipY = (leftHip.y + rightHip.y) / 2;
    final midHipZ = (leftHip.z + rightHip.z) / 2;

    // 2. Calculate Scale Factor (Based on Shoulder Width)
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    double scaleFactor = 1.0;
    if (leftShoulder != null && rightShoulder != null) {
      final dx = leftShoulder.x - rightShoulder.x;
      final dy = leftShoulder.y - rightShoulder.y;
      final dz = leftShoulder.z - rightShoulder.z;
      final shoulderDist = math.sqrt(dx * dx + dy * dy + dz * dz);

      if (shoulderDist > 0.01) {
        scaleFactor = 1.0 / shoulderDist;
      }
    }

    // 3. Transform all landmarks
    final Map<int, List<double>> normalizedLandmarks = {};

    landmarks.forEach((type, landmark) {
      // Translate
      final tx = landmark.x - midHipX;
      final ty = landmark.y - midHipY;
      final tz = landmark.z - midHipZ;

      // Scale
      final sx = tx * scaleFactor;
      final sy = ty * scaleFactor;
      final sz = tz * scaleFactor;

      normalizedLandmarks[type.index] = [sx, sy, sz, landmark.likelihood];
    });

    return normalizedLandmarks;
  }

  /// Calculates the angle (in degrees) between three landmarks:
  /// [first] -> [mid] -> [last].
  static double calculateAngle(
    PoseLandmark first,
    PoseLandmark mid,
    PoseLandmark last,
  ) {
    return calculateAngleFromCoordinates(
      first.x,
      first.y,
      mid.x,
      mid.y,
      last.x,
      last.y,
    );
  }

  /// Calculates angle from raw coordinates (2D projection mostly used for screen feedback).
  /// For 3D, we can add a flag or separate method, but usually 2D projection is enough for
  /// "seeing" the angle on screen.
  static double calculateAngleFromCoordinates(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final double radians =
        math.atan2(cy - by, cx - bx) - math.atan2(ay - by, ax - bx);
    double angle = (radians * 180.0 / math.pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return angle;
  }

  /// Calculates 3D Euclidean distance between two normalized pose frames.
  ///
  /// [poseA] and [poseB] are maps of landmark index -> [x, y, z, conf].
  /// Returns the average distance per joint.
  static double calculateEuclideanDistance(
    Map<int, List<double>> poseA,
    Map<int, List<double>> poseB,
  ) {
    double totalDist = 0.0;
    int count = 0;

    // Iterate over common keys representing joints we care about
    // Usually we compare specific joints, but here we can compare all available.
    for (final key in poseA.keys) {
      if (!poseB.containsKey(key)) continue;

      final pA = poseA[key]!;
      final pB = poseB[key]!;

      // x=0, y=1, z=2, conf=3
      final dx = pA[0] - pB[0];
      final dy = pA[1] - pB[1];
      final dz = pA[2] - pB[2];

      final dist = math.sqrt(dx * dx + dy * dy + dz * dz);
      totalDist += dist;
      count++;
    }

    if (count == 0) return 1000.0; // Large distance if no common joints
    return totalDist / count;
  }
}
