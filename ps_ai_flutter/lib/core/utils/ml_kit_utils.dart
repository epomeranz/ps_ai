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
    if (format == null) return null;

    final plane = image.planes.first;

    final planeDataList = image.planes.map((p) => PlaneData(
      bytes: p.bytes,
      bytesPerRow: p.bytesPerRow,
      height: p.height,
      width: p.width,
    )).toList();

    return InputImage.fromBytes(
      bytes: concatenatePlanes(planeDataList),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // We need to calculate this outside
        format: format,
        bytesPerRow: plane.bytesPerRow, // simplified
      ),
    );
  }

  static FrameDataFromCameraImage? extractFrameData(
    CameraImage image,
    CameraDescription camera,
    InputImageRotation rotation,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final planes = image.planes.map((p) {
      return PlaneData(
        bytes: p.bytes,
        bytesPerRow: p.bytesPerRow,
        height: p.height,
        width: p.width,
      );
    }).toList();

    return FrameDataFromCameraImage(
      planes: planes,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );
  }

  static InputImage? inputImageFromFrameData(FrameDataFromCameraImage data) {
    return InputImage.fromBytes(
      bytes: concatenatePlanes(data.planes),
      metadata: InputImageMetadata(
        size: data.size,
        rotation: data.rotation,
        format: data.format,
        bytesPerRow: data.bytesPerRow,
      ),
    );
  }

  static Uint8List concatenatePlanes(List<PlaneData> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final PlaneData plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  static InputImageRotation getRotation(
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
    CameraLensDirection lensDirection,
  ) {
    int rotationCompensation = 0;

    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp:
        rotationCompensation = 0;
        break;
      case DeviceOrientation.landscapeLeft:
        rotationCompensation = 90;
        break;
      case DeviceOrientation.portraitDown:
        rotationCompensation = 180;
        break;
      case DeviceOrientation.landscapeRight:
        rotationCompensation = 270;
        break;
    }

    int rotation;
    if (lensDirection == CameraLensDirection.front) {
      rotation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      // Back camera
      rotation = (sensorOrientation - rotationCompensation + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(rotation) ??
        InputImageRotation.rotation0deg;
  }
}

class PlaneData {
  final Uint8List bytes;
  final int bytesPerRow;
  final int? height;
  final int? width;

  PlaneData({
    required this.bytes,
    required this.bytesPerRow,
    this.height,
    this.width,
  });
}

class FrameDataFromCameraImage {
  final List<PlaneData> planes;
  final Size size;
  final InputImageRotation rotation;
  final InputImageFormat format;
  final int bytesPerRow;

  FrameDataFromCameraImage({
    required this.planes,
    required this.size,
    required this.rotation,
    required this.format,
    required this.bytesPerRow,
  });
}
