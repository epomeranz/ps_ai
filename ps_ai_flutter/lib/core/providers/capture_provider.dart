import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:uuid/uuid.dart';

import '../../models/tracking_data.dart';
import '../services/camera_service.dart';
import '../services/ml_service.dart';
import '../services/tracking_repository.dart';
import '../utils/ml_kit_utils.dart';
import '../../models/exercise_metadata.dart';
import 'settings_providers.dart';

enum CaptureStatus { idle, initializing, streaming, recording, paused, error }

class CaptureState {
  final CaptureStatus status;
  final CameraController? cameraController;
  final List<Pose> poses;
  final List<DetectedObject> objects;
  final InputImageRotation rotation;
  final String? errorMessage;
  final TrackingSession? currentSession;

  CaptureState({
    this.status = CaptureStatus.idle,
    this.cameraController,
    this.poses = const [],
    this.objects = const [],
    this.rotation = InputImageRotation.rotation90deg,
    this.errorMessage,
    this.currentSession,
    this.referenceMetadata,
  });

  final ExerciseMetadata? referenceMetadata;

  CaptureState copyWith({
    CaptureStatus? status,
    CameraController? cameraController,
    List<Pose>? poses,
    List<DetectedObject>? objects,
    InputImageRotation? rotation,
    String? errorMessage,
    TrackingSession? currentSession,
    ExerciseMetadata? referenceMetadata,
  }) {
    return CaptureState(
      status: status ?? this.status,
      cameraController: cameraController ?? this.cameraController,
      poses: poses ?? this.poses,
      objects: objects ?? this.objects,
      rotation: rotation ?? this.rotation,
      errorMessage: errorMessage ?? this.errorMessage,
      currentSession: currentSession ?? this.currentSession,
      referenceMetadata: referenceMetadata ?? this.referenceMetadata,
    );
  }

  // Helper to clear reference metadata when resetting
  CaptureState clearReferenceMetadata() {
    return CaptureState(
      status: status,
      cameraController: cameraController,
      poses: poses,
      objects: objects,
      rotation: rotation,
      errorMessage: errorMessage,
      currentSession: currentSession,
      referenceMetadata: null,
    );
  }
}

final captureControllerProvider =
    NotifierProvider<CaptureController, CaptureState>(CaptureController.new);

class CaptureController extends Notifier<CaptureState> {
  final _cameraService = CameraService();
  final _mlService = MLService();

  bool _isProcessing = false;
  bool _isDisposed = false;
  int _frameCount = 0;

  @override
  CaptureState build() {
    // Clean up on dispose
    ref.onDispose(() {
      _isDisposed = true; // Mark as disposed immediately
      _stopAll();
    });
    return CaptureState();
  }

  // Public method to force stop
  Future<void> disposeController() async {
    // We don't mark as _isDisposed here because we might want to re-initialize
    // this same controller instance later if the provider is kept alive.
    // _isDisposed is strictly for when the Provider is destroyed.
    await _stopAll();
  }

  Future<void> _stopAll() async {
    try {
      if (_cameraService.controller != null &&
          _cameraService.controller!.value.isStreamingImages) {
        await _cameraService.stopImageStream();
      }
      await _cameraService.dispose();
      await _mlService.dispose();
    } catch (e) {
      debugPrint('Error stopping capture services: $e');
    }

    // Reset state to ensure we don't hold onto a disposed controller
    // We only update state if the provider itself is not explicitly disposed by Riverpod
    // (i.e., we are manually resetting via disposeController)
    if (!_isDisposed) {
      state = CaptureState();
    }
  }

  Future<void> initialize(String profileId) async {
    if (_isDisposed) return;

    state = state.copyWith(status: CaptureStatus.initializing);
    try {
      // Load settings
      final settings = await ref
          .read(settingsServiceProvider)
          .getSettingsStream(profileId)
          .first;
      final preferredLensString = settings['cameraLens'] as String? ?? 'front';
      final preferredLens = preferredLensString == 'back'
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      await _cameraService.initialize(preferredLens: preferredLens);
      await _mlService.initialize();

      if (_isDisposed) return;

      state = state.copyWith(
        status: CaptureStatus.streaming,
        cameraController: _cameraService.controller,
      );

      _startStream();
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> switchCamera(String profileId) async {
    if (state.status != CaptureStatus.streaming &&
        state.status != CaptureStatus.recording)
      return;

    // Temporarily set to initializing to unmount CameraPreview from UI
    // preventing "Disposed CameraController" error
    final previousStatus = state.status;
    state = state.copyWith(status: CaptureStatus.initializing);

    try {
      await _cameraService.switchCamera((image) {
        if (_isDisposed) return;
        _processFrame(image);
      });

      // Update state with new controller info
      state = state.copyWith(
        status: previousStatus, // Restore status (usually streaming)
        cameraController: _cameraService.controller,
      );

      // Save preference
      final newLens = _cameraService.currentLensDirection;
      final newLensString = newLens == CameraLensDirection.back
          ? 'back'
          : 'front';

      await ref
          .read(settingsServiceProvider)
          .updateSetting(
            profileId,
            'cameraLens',
            newLensString,
          );
    } catch (e) {
      debugPrint("Error switching camera: $e");
      // Restore previous status on error so user isn't stuck
      state = state.copyWith(
        status: previousStatus,
        errorMessage: "Failed to switch camera",
      );
    }
  }

  void _startStream() {
    if (_isDisposed) return;
    _cameraService.startImageStream((image) {
      if (_isDisposed) return;
      _processFrame(image);
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || _isDisposed) return; // Drop frame if busy or disposed
    if (state.status != CaptureStatus.streaming &&
        state.status != CaptureStatus.recording) {
      return;
    }

    _isProcessing = true;
    _frameCount++;

    try {
      if (_isDisposed) return;
      final camera = _cameraService.controller!.description;
      final deviceOrientation =
          _cameraService.controller!.value.deviceOrientation;
      final rotation = MLKitUtils.getRotation(
        camera.sensorOrientation,
        deviceOrientation,
        camera.lensDirection,
      );

      // Extract raw data for isolate transfer (lightweight)
      final frameData = MLKitUtils.extractFrameData(
        image,
        camera,
        rotation,
      );

      if (frameData == null) {
        _isProcessing = false;
        return;
      }

      // Process in isolate
      // Process objects every 3rd frame, BUT ONLY IF NOT REFERENCE SESSION
      final bool isReference = state.referenceMetadata != null;
      final bool shouldDetectObjects = !isReference && (_frameCount % 3 == 0);

      final result = await _mlService.processFrame(
        frameData,
        detectObjects: shouldDetectObjects,
      );

      // Update UI state with rotation
      // Use existing objects if not detected this frame
      final objects = shouldDetectObjects ? result.objects : state.objects;

      state = state.copyWith(
        poses: result.poses,
        objects: objects,
        rotation: rotation,
      );

      // Save data if recording
      if (state.status == CaptureStatus.recording &&
          state.currentSession != null) {
        _recordFrameData(result.poses, objects);
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

  Future<void> startRecording(
    String profileId,
    String activePlayerId,
    String sportType,
    String exerciseType,
  ) async {
    if (state.status != CaptureStatus.streaming) return;

    final session = TrackingSession(
      sessionId: const Uuid().v4(),
      profileId: profileId,
      activePlayerId: activePlayerId,
      sportType: sportType,
      exerciseType: exerciseType,
      startTime: DateTime.now(),
    );

    // _cameraService.startVideoRecording(); // Optional: actual video file

    state = state.copyWith(
      status: CaptureStatus.recording,
      currentSession: session,
      referenceMetadata: null, // Ensure normal recording logic
    );
  }

  Future<void> startReferenceRecording(
    ExerciseMetadata metadata,
    String profileId,
  ) async {
    if (state.status != CaptureStatus.streaming) return;

    final session = TrackingSession(
      sessionId: const Uuid().v4(),
      profileId: profileId,
      activePlayerId: 'reference', // or create a 'standard' player ID
      sportType: metadata.sportType,
      exerciseType: metadata.id, // ID is likely consistent
      startTime: DateTime.now(),
    );

    state = state.copyWith(
      status: CaptureStatus.recording,
      currentSession: session,
      referenceMetadata: metadata,
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
        if (state.referenceMetadata != null) {
          await ref
              .read(trackingRepositoryProvider)
              .saveReferenceExercise(
                session,
                state.referenceMetadata!,
              );
        } else {
          await ref.read(trackingRepositoryProvider).saveSession(session);
        }
      }

      state = CaptureState(
        status: CaptureStatus.streaming,
        cameraController: state.cameraController,
        rotation: state.rotation,
        // Keep other config potentially? No, basic reset to streaming.
      );
    }
  }
}
