import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ps_ai_flutter/widgets/capture_controls_widget.dart';
import 'package:ps_ai_flutter/core/providers/capture_provider.dart';
import 'package:ps_ai_flutter/core/providers/player_providers.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';
import 'package:ps_ai_flutter/widgets/feedback_overlay.dart';
import 'package:ps_ai_flutter/widgets/tracking_overlay_painter.dart';
import 'package:ps_ai_flutter/widgets/instruction_overlay.dart';
import 'package:ps_ai_flutter/core/providers/feedback_provider.dart';

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
  late CaptureController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = ref.read(captureControllerProvider.notifier);
      _controller.initialize(widget.profileId);
    });
  }

  @override
  void dispose() {
    // Manually stop the capture controller since the provider is kept alive
    // This fixes the "camera always running" issue
    // We use the captured _controller to avoid "StateError: Bad state: Using "ref"..."
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider);
    final activePlayerIdAsync = ref.watch(
      activePlayerProvider(widget.sportType),
    );
    final activePlayerId = activePlayerIdAsync.value ?? 'unknown_player';

    // Watch feedback to color the skeleton
    final feedbackAsync = ref.watch(feedbackStreamProvider);
    final feedbackColor = feedbackAsync.value?.indicatorColor ?? Colors.green;

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
                  skeletonColor: feedbackColor,
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
            // Instruction Overlay (Big, Center)
            InstructionOverlay(
              sportType: widget.sportType,
              exerciseType: widget.exerciseType,
            ),

            // Feedback Overlay (Top Right, Small)
            FeedbackOverlay(peopleCount: widget.peopleCount),
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
      CaptureControlsWidget(
        status: captureState.status,
        onRecord: () {
          ref
              .read(captureControllerProvider.notifier)
              .startRecording(
                widget.profileId,
                activePlayerId,
                widget.sportType,
                widget.exerciseType,
              );
        },
        onStop: () {
          ref.read(captureControllerProvider.notifier).stopRecording();
        },
        onPause: () {
          ref.read(captureControllerProvider.notifier).pauseRecording();
        },
        onResume: () {
          ref.read(captureControllerProvider.notifier).resumeRecording();
        },
        onSwitchCamera: () {
          ref
              .read(captureControllerProvider.notifier)
              .switchCamera(widget.profileId);
        },
      ),
    ];
  }
}
