import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

// Helper to convert CameraImage to InputImage
class MLKitUtils {
  static InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    InputImageRotation rotation,
  ) {
    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // On Android, the camera returns YUV_420_888 which maps to NV21 logic in MLKit often
    // On iOS, it returns BGRA8888 usually
    if (format == null) return null;

    final plane = image.planes.first;

    // Since we can't easily access all planes in a unified way without more boilerplate,
    // we use the bytes directly.
    // Note: This is simplified.

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // We need to calculate this outside
        format: format,
        bytesPerRow: plane.bytesPerRow, // simplified
      ),
    );
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  static InputImageRotation getRotation(int sensorOrientation) {
    const rotations = {
      0: InputImageRotation.rotation0deg,
      90: InputImageRotation.rotation90deg,
      180: InputImageRotation.rotation180deg,
      270: InputImageRotation.rotation270deg,
    };
    return rotations[sensorOrientation] ?? InputImageRotation.rotation0deg;
  }
}
