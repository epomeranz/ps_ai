import 'dart:io';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  int _cameraIndex = 0;
  List<CameraDescription> _cameras = [];

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    if (_cameras.isEmpty) return;

    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
  }

  Future<void> startImageStream(void Function(CameraImage) onImage) async {
    if (!isInitialized) return;
    await _controller?.startImageStream(onImage);
  }

  Future<void> stopImageStream() async {
    if (!isInitialized) return;
    try {
      await _controller?.stopImageStream();
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
