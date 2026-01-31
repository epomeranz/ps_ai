import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ps_ai_flutter/core/providers/capture_provider.dart';
import 'package:ps_ai_flutter/models/exercise_metadata.dart';
import 'package:ps_ai_flutter/widgets/capture_controls_widget.dart';
import 'package:ps_ai_flutter/widgets/tracking_overlay_painter.dart';

class ReferenceCaptureScreen extends ConsumerStatefulWidget {
  final ExerciseMetadata metadata;
  final String profileId;

  const ReferenceCaptureScreen({
    super.key,
    required this.metadata,
    required this.profileId,
  });

  @override
  ConsumerState<ReferenceCaptureScreen> createState() =>
      _ReferenceCaptureScreenState();
}

class _ReferenceCaptureScreenState
    extends ConsumerState<ReferenceCaptureScreen> {
  late CaptureController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = ref.read(captureControllerProvider.notifier);
      _controller.initialize();
    });
  }

  @override
  void dispose() {
    // Stop recording if active when leaving
    // We call stopRecording on the controller directly.
    // It checks the state internally, so it's safe to call even if not recording.
    _controller.stopRecording();
    _controller.disposeController();
    super.dispose();
  }

  void _handleStop() async {
    await _controller.stopRecording();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise Saved!')),
      );
      // Navigate back to GymScreen (pop twice: capture -> creation -> gym)
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider);

    if (captureState.status == CaptureStatus.initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (captureState.status == CaptureStatus.error) {
      return Scaffold(
        body: Center(child: Text('Error: ${captureState.errorMessage}')),
      );
    }

    if (captureState.cameraController == null ||
        !captureState.cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: Text('Camera not ready')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          Center(child: CameraPreview(captureState.cameraController!)),

          // Tracking Overlay (Pose only, object detection is disabled for reference)
          if (captureState.status == CaptureStatus.streaming ||
              captureState.status == CaptureStatus.recording)
            CustomPaint(
              painter: TrackingOverlayPainter(
                poses: captureState.poses,
                objects: captureState.objects, // Should be empty
                rotation: captureState.rotation,
                absoluteImageSize:
                    captureState.cameraController!.value.previewSize!,
              ),
              child: Container(),
            ),

          // Header / Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Recording: ${widget.metadata.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: CaptureControlsWidget(
                status: captureState.status,
                onRecord: () {
                  _controller.startReferenceRecording(
                    widget.metadata,
                    widget.profileId,
                  );
                },
                onStop: _handleStop,
                onPause: () => _controller.pauseRecording(),
                onResume: () => _controller.resumeRecording(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
