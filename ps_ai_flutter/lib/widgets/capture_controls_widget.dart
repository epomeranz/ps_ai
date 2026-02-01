import 'package:flutter/material.dart';
import '../core/providers/capture_provider.dart';

class CaptureControlsWidget extends StatelessWidget {
  final CaptureStatus status;
  final VoidCallback onRecord;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback? onSwitchCamera;

  const CaptureControlsWidget({
    super.key,
    required this.status,
    required this.onRecord,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'record_stop_btn',
          backgroundColor: status == CaptureStatus.recording
              ? Colors.red
              : Colors.white,
          onPressed: () {
            if (status == CaptureStatus.recording) {
              onStop();
            } else {
              onRecord();
            }
          },
          child: Icon(
            status == CaptureStatus.recording ? Icons.stop : Icons.circle,
            color: status == CaptureStatus.recording
                ? Colors.white
                : Colors.red,
          ),
        ),
        const SizedBox(width: 20, height: 20),
        if (status == CaptureStatus.recording || status == CaptureStatus.paused)
          FloatingActionButton(
            heroTag: 'pause_resume_btn',
            mini: true,
            onPressed: () {
              if (status == CaptureStatus.paused) {
                onResume();
              } else {
                onPause();
              }
            },
            child: Icon(
              status == CaptureStatus.paused ? Icons.play_arrow : Icons.pause,
            ),
          ),
        if (status == CaptureStatus.streaming ||
            status == CaptureStatus.initializing) ...[
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'switch_camera_btn',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: onSwitchCamera,
            child: const Icon(Icons.cameraswitch, color: Colors.blue),
          ),
        ],
      ],
    );
  }
}
