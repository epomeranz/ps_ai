import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ps_ai_flutter/core/providers/capture_provider.dart';
import 'package:ps_ai_flutter/core/providers/player_providers.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';
import 'package:ps_ai_flutter/widgets/tracking_overlay_painter.dart';

class SportsCaptureWidget extends ConsumerStatefulWidget {
  final int peopleCount;
  final List<TrackedObjectTypeConfig> objectConfigs;
  final String profileId;
  final String sportType;
  final String exerciseType;

  const SportsCaptureWidget({
    super.key,
    required this.peopleCount,
    required this.objectConfigs,
    required this.profileId,
    required this.sportType,
    required this.exerciseType,
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
    final activePlayerIdAsync = ref.watch(
      activePlayerProvider(widget.sportType),
    );
    final activePlayerId = activePlayerIdAsync.value ?? 'unknown_player';

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

    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        return Stack(
          children: [
            // Camera Preview
            Center(child: CameraPreview(captureState.cameraController!)),

            // Tracking Overlay
            if (captureState.status == CaptureStatus.streaming ||
                captureState.status == CaptureStatus.recording)
              CustomPaint(
                painter: TrackingOverlayPainter(
                  poses: captureState.poses,
                  objects: captureState.objects,
                  rotation: captureState.rotation,
                  absoluteImageSize:
                      captureState.cameraController!.value.previewSize!,
                ),
                child: Container(),
              ),

            // Controls
            Positioned(
              bottom: isPortrait ? 30 : 0,
              left: isPortrait ? 0 : null,
              right: isPortrait ? 0 : 30,
              top: isPortrait ? null : 0,
              child: isPortrait
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildControlButtons(
                        captureState,
                        activePlayerId,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildControlButtons(
                        captureState,
                        activePlayerId,
                      ),
                    ),
            ),

            // Stats
            Positioned(
              top: 40,
              left: isPortrait ? null : 20,
              right: isPortrait ? 20 : null,
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
      },
    );
  }

  List<Widget> _buildControlButtons(
    CaptureState captureState,
    String activePlayerId,
  ) {
    return [
      FloatingActionButton(
        backgroundColor: captureState.status == CaptureStatus.recording
            ? Colors.red
            : Colors.white,
        onPressed: () {
          if (captureState.status == CaptureStatus.recording) {
            ref.read(captureControllerProvider.notifier).stopRecording();
          } else {
            ref
                .read(captureControllerProvider.notifier)
                .startRecording(
                  widget.profileId,
                  activePlayerId,
                  widget.sportType,
                  widget.exerciseType,
                );
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
      const SizedBox(width: 20, height: 20),
      if (captureState.status == CaptureStatus.recording ||
          captureState.status == CaptureStatus.paused)
        FloatingActionButton(
          mini: true,
          onPressed: () {
            if (captureState.status == CaptureStatus.paused) {
              ref.read(captureControllerProvider.notifier).resumeRecording();
            } else {
              ref.read(captureControllerProvider.notifier).pauseRecording();
            }
          },
          child: Icon(
            captureState.status == CaptureStatus.paused
                ? Icons.play_arrow
                : Icons.pause,
          ),
        ),
    ];
  }
}
