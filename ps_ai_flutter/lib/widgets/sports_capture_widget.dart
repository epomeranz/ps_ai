import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:ps_ai_flutter/core/providers/capture_provider.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';
import 'package:ps_ai_flutter/widgets/tracking_overlay_painter.dart';

class SportsCaptureWidget extends ConsumerStatefulWidget {
  final int peopleCount;
  final List<TrackedObjectTypeConfig> objectConfigs;
  final String profileId;
  final String sportType;

  const SportsCaptureWidget({
    super.key,
    required this.peopleCount,
    required this.objectConfigs,
    required this.profileId,
    required this.sportType,
  });

  @override
  ConsumerState<SportsCaptureWidget> createState() =>
      _SportsCaptureWidgetState();
}

class _SportsCaptureWidgetState extends ConsumerState<SportsCaptureWidget> {
  @override
  void initState() {
    super.initState();
    // Initialize controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(captureControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider);

    if (captureState.status == CaptureStatus.initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (captureState.status == CaptureStatus.error) {
      return Center(child: Text('Error: ${captureState.errorMessage}'));
    }

    if (captureState.cameraController == null ||
        !captureState.cameraController!.value.isInitialized) {
      return const Center(child: Text('Camera not ready'));
    }

    // final size = MediaQuery.of(context).size;
    // Calculate scaling to ensure overlay matches camera preview
    // This is simplified; robust implementations handling aspect ratio are more verbose.
    // Assuming full screen or fitted container.

    return Stack(
      children: [
        // Camera Preview
        CameraPreview(captureState.cameraController!),

        // Tracking Overlay
        if (captureState.status == CaptureStatus.streaming ||
            captureState.status == CaptureStatus.recording)
          CustomPaint(
            painter: TrackingOverlayPainter(
              poses: captureState.poses,
              objects: captureState.objects,
              rotation: InputImageRotation
                  .rotation90deg, // Need real rotation from controller/utils
              absoluteImageSize:
                  captureState.cameraController!.value.previewSize!,
            ),
            child: Container(),
          ),

        // Controls
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                backgroundColor: captureState.status == CaptureStatus.recording
                    ? Colors.red
                    : Colors.white,
                onPressed: () {
                  if (captureState.status == CaptureStatus.recording) {
                    ref
                        .read(captureControllerProvider.notifier)
                        .stopRecording();
                  } else {
                    ref
                        .read(captureControllerProvider.notifier)
                        .startRecording(widget.profileId, widget.sportType);
                  }
                },
                child: Icon(
                  captureState.status == CaptureStatus.recording
                      ? Icons.stop
                      : Icons.circle,
                  color: captureState.status == CaptureStatus.recording
                      ? Colors.white
                      : Colors.red,
                ),
              ),
              const SizedBox(width: 20),
              if (captureState.status == CaptureStatus.recording ||
                  captureState.status == CaptureStatus.paused)
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    if (captureState.status == CaptureStatus.paused) {
                      ref
                          .read(captureControllerProvider.notifier)
                          .resumeRecording();
                    } else {
                      ref
                          .read(captureControllerProvider.notifier)
                          .pauseRecording();
                    }
                  },
                  child: Icon(
                    captureState.status == CaptureStatus.paused
                        ? Icons.play_arrow
                        : Icons.pause,
                  ),
                ),
            ],
          ),
        ),

        // Stats
        Positioned(
          top: 40,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black54,
            child: Column(
              children: [
                Text(
                  'People: ${captureState.poses.length} / ${widget.peopleCount}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Objects: ${captureState.objects.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (captureState.status == CaptureStatus.recording)
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
