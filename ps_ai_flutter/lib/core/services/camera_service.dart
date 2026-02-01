import 'dart:io';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraLensDirection _currentLensDirection = CameraLensDirection.front;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraLensDirection get currentLensDirection => _currentLensDirection;

  Future<void> initialize({
    CameraLensDirection preferredLens = CameraLensDirection.front,
  }) async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    if (_cameras.isEmpty) return;

    _currentLensDirection = preferredLens;
    await _initializeController();
  }

  Future<void> _initializeController() async {
    // Find camera with preferred direction, fallback to first available
    final cameraDescription = _cameras.firstWhere(
      (camera) => camera.lensDirection == _currentLensDirection,
      orElse: () => _cameras.first,
    );

    // If we couldn't find the preferred one and fell back, update state
    _currentLensDirection = cameraDescription.lensDirection;

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: true, // Keep audio enabled as per original
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
  }

  Future<void> switchCamera(void Function(CameraImage) onImage) async {
    if (_cameras.isEmpty) return;

    // Toggle direction
    _currentLensDirection = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await stopImageStream();
    await _controller?.dispose();
    _controller = null;

    await _initializeController();
    await startImageStream(onImage);
  }

  Future<void> startImageStream(void Function(CameraImage) onImage) async {
    if (!isInitialized) return;
    await _controller?.startImageStream(onImage);
  }

  Future<void> stopImageStream() async {
    if (!isInitialized) return;
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller?.stopImageStream();
      }
    } catch (_) {
      // Sometimes it throws if already stopped or disposed
    }
  }

  Future<void> startVideoRecording() async {
    if (!isInitialized) return;
    if (_controller!.value.isRecordingVideo) return;
    await _controller?.startVideoRecording();
  }

  Future<XFile?> stopVideoRecording() async {
    if (!isInitialized) return null;
    if (!_controller!.value.isRecordingVideo) return null;
    return await _controller?.stopVideoRecording();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
