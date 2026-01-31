import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:uuid/uuid.dart';

import '../../models/tracking_data.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/tracking_repository.dart';
import '../utils/ml_kit_utils.dart';

enum CaptureStatus { idle, initializing, streaming, recording, paused, error }

class CaptureState {
  final CaptureStatus status;
  final CameraController? cameraController;
  final List<Pose> poses;
  final List<DetectedObject> objects;
  final String? errorMessage;
  final TrackingSession? currentSession;

  CaptureState({
    this.status = CaptureStatus.idle,
    this.cameraController,
    this.poses = const [],
    this.objects = const [],
    this.errorMessage,
    this.currentSession,
  });

  CaptureState copyWith({
    CaptureStatus? status,
    CameraController? cameraController,
    List<Pose>? poses,
    List<DetectedObject>? objects,
    String? errorMessage,
    TrackingSession? currentSession,
  }) {
    return CaptureState(
      status: status ?? this.status,
      cameraController: cameraController ?? this.cameraController,
      poses: poses ?? this.poses,
      objects: objects ?? this.objects,
      errorMessage: errorMessage ?? this.errorMessage,
      currentSession: currentSession ?? this.currentSession,
    );
  }
}

final captureControllerProvider =
    NotifierProvider<CaptureController, CaptureState>(CaptureController.new);

class CaptureController extends Notifier<CaptureState> {
  final _cameraService = CameraService();
  final _mlService = MLService();
  final _repository = TrackingRepository();

  bool _isProcessing = false;
  int _frameCount = 0;

  @override
  CaptureState build() {
    // Clean up on dispose
    ref.onDispose(() {
      _StopAll();
    });
    return CaptureState();
  }

  Future<void> _StopAll() async {
    await _cameraService.stopImageStream();
    await _cameraService.dispose();
    await _mlService.dispose();
  }

  Future<void> initialize() async {
    state = state.copyWith(status: CaptureStatus.initializing);
    try {
      await _cameraService.initialize();
      await _mlService.initialize();

      state = state.copyWith(
        status: CaptureStatus.streaming,
        cameraController: _cameraService.controller,
      );

      _startStream();
    } catch (e) {
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _startStream() {
    _cameraService.startImageStream((image) {
      _processFrame(image);
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing) return; // Drop frame if busy
    if (state.status != CaptureStatus.streaming &&
        state.status != CaptureStatus.recording)
      return;

    _isProcessing = true;
    _frameCount++;

    try {
      final camera = _cameraService.controller!.description;
      final rotation = MLKitUtils.getRotation(camera.sensorOrientation);
      final inputImage = MLKitUtils.inputImageFromCameraImage(
        image,
        camera,
        rotation,
      );

      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Always process pose
      final poses = await _mlService.processPose(inputImage);

      // Process objects every 3rd frame to save resources, or every frame if recording?
      // User tip: "process Pose every frame but only process the Ball detection every 2nd or 3rd frame"
      List<DetectedObject> objects = state.objects;
      if (_frameCount % 3 == 0) {
        objects = await _mlService.processObjects(inputImage);
      }

      // Update UI state
      state = state.copyWith(poses: poses, objects: objects);

      // Save data if recording
      if (state.status == CaptureStatus.recording &&
          state.currentSession != null) {
        _recordFrameData(poses, objects);
      }
    } catch (e) {
      debugPrint("Error processing frame: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _recordFrameData(List<Pose> poses, List<DetectedObject> objects) {
    final frameData = FrameData(
      timestampMs: DateTime.now()
          .difference(state.currentSession!.startTime)
          .inMilliseconds,
      people: poses.map((p) => TrackedPerson.fromPose(p)).toList(),
      objects: objects
          .map(
            (o) => TrackedObject(
              trackingId: o.trackingId,
              label: o.labels.isNotEmpty ? o.labels.first.text : 'Unknown',
              x: o
                  .boundingBox
                  .center
                  .dx, // Note: Need normalization logic if not normalized
              y: o.boundingBox.center.dy,
              w: o.boundingBox.width,
              h: o.boundingBox.height,
              confidence: o.labels.isNotEmpty ? o.labels.first.confidence : 0.0,
            ),
          )
          .toList(),
    );

    state.currentSession!.addFrame(frameData);
  }

  Future<void> startRecording(String profileId, String sportType) async {
    if (state.status != CaptureStatus.streaming) return;

    final session = TrackingSession(
      sessionId: const Uuid().v4(),
      profileId: profileId,
      sportType: sportType,
      startTime: DateTime.now(),
    );

    // _cameraService.startVideoRecording(); // Optional: actual video file

    state = state.copyWith(
      status: CaptureStatus.recording,
      currentSession: session,
    );
  }

  Future<void> pauseRecording() async {
    if (state.status == CaptureStatus.recording) {
      state = state.copyWith(status: CaptureStatus.paused);
    }
  }

  Future<void> resumeRecording() async {
    if (state.status == CaptureStatus.paused) {
      state = state.copyWith(status: CaptureStatus.recording);
    }
  }

  Future<void> stopRecording() async {
    if (state.status == CaptureStatus.recording ||
        state.status == CaptureStatus.paused) {
      // _cameraService.stopVideoRecording();

      final session = state.currentSession;
      if (session != null) {
        await _repository.saveSession(session);
      }

      state = state.copyWith(
        status: CaptureStatus.streaming,
        currentSession: null, // Reset session
      );
    }
  }
}
