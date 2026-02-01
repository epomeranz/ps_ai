import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class TrackingOverlayPainter extends CustomPainter {
  final List<Pose> poses;
  final List<DetectedObject> objects;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  TrackingOverlayPainter({
    required this.poses,
    required this.objects,
    required this.absoluteImageSize,
    required this.rotation,
    this.skeletonColor = Colors.green,
  });

  final Color skeletonColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = skeletonColor;

    final objectPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.red;

    final objectTextPaint = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Draw Poses
    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        final point = _translatePoint(
          landmark.x,
          landmark.y,
          size,
          absoluteImageSize,
          rotation,
        );
        canvas.drawCircle(
          point,
          3.0,
          paint,
        );
      });

      void paintLine(
        PoseLandmarkType type1,
        PoseLandmarkType type2,
        Paint paintType,
      ) {
        final p1 = pose.landmarks[type1];
        final p2 = pose.landmarks[type2];
        if (p1 == null || p2 == null) return;

        final pt1 = _translatePoint(
          p1.x,
          p1.y,
          size,
          absoluteImageSize,
          rotation,
        );
        final pt2 = _translatePoint(
          p2.x,
          p2.y,
          size,
          absoluteImageSize,
          rotation,
        );

        canvas.drawLine(pt1, pt2, paintType);
      }

      // Draw Skeleton connections
      paintLine(PoseLandmarkType.nose, PoseLandmarkType.leftShoulder, paint);
      paintLine(PoseLandmarkType.nose, PoseLandmarkType.rightShoulder, paint);
      paintLine(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        paint,
      );
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, paint);
      paintLine(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        paint,
      );
      paintLine(
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
        paint,
      );
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, paint);
      paintLine(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        paint,
      );
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, paint);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, paint);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, paint);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, paint);
    }

    // Draw Objects
    for (final detectedObject in objects) {
      final bb = detectedObject.boundingBox;

      // Transform coordinates
      final tl = _translatePoint(
        bb.left,
        bb.top,
        size,
        absoluteImageSize,
        rotation,
      );
      final br = _translatePoint(
        bb.right,
        bb.bottom,
        size,
        absoluteImageSize,
        rotation,
      );

      canvas.drawRect(
        Rect.fromPoints(tl, br),
        objectPaint,
      );

      // Draw Label
      if (detectedObject.labels.isNotEmpty) {
        objectTextPaint.text = TextSpan(
          text: detectedObject.labels.first.text,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
            backgroundColor: Colors.white,
          ),
        );
        objectTextPaint.layout();
        objectTextPaint.paint(canvas, Offset(tl.dx, tl.dy - 20));
      }
    }
  }

  // Unified coordinate translation
  Offset _translatePoint(
    double x,
    double y,
    Size size,
    Size absoluteImageSize,
    InputImageRotation rotation,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        // Image width/height are swapped relative to view in vertical orientations
        // For ML Kit Android default (90 or 270), x in image is vertical on screen?
        // Actually, ML Kit returns coordinates relative to the image buffer.
        // If image is 1280x720 (landscape buffer) but displayed Portrait 720x1280.
        // x in buffer (0..1280) maps to x in view (0..720) but rotated?

        // Let's use the standard formula for simplified FitHeight/FitWidth
        // Assuming the preview covers the screen and center crop or similar.

        // This is a complex topic. For MVP, I will assume a direct mapping scaling.
        // If rotation is 90, we swap dimensions for scaling factors.

        return Offset(
          x * size.width / absoluteImageSize.height,
          y * size.height / absoluteImageSize.width,
        );

      default:
        return Offset(
          x * size.width / absoluteImageSize.width,
          y * size.height / absoluteImageSize.height,
        );
    }
  }

  @override
  bool shouldRepaint(TrackingOverlayPainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.objects != objects;
  }
}
