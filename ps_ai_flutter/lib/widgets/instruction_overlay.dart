import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class InstructionOverlay extends ConsumerStatefulWidget {
  final String sportType;
  final String exerciseType;

  const InstructionOverlay({
    super.key,
    required this.sportType,
    required this.exerciseType,
  });

  @override
  ConsumerState<InstructionOverlay> createState() => _InstructionOverlayState();
}

class _InstructionOverlayState extends ConsumerState<InstructionOverlay> {
  final FlutterTts flutterTts = FlutterTts();
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _initAndSpeak();
  }

  String _getInstruction() {
    // TODO: Move this to a proper configuration/repository
    if (widget.exerciseType == 'Squat') {
      return "Place camera at side profile. Ensure full body visibility.";
    } else if (widget.sportType == 'basketball') {
      return "Position camera to see both player and hoop.";
    }
    return "Face the camera.";
  }

  Future<void> _initAndSpeak() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(
      true,
    ); // Wait for speech to finish if needed

    final message = _getInstruction();

    // Speak
    await flutterTts.speak(message);

    // Auto-hide after 5 seconds (or length of speech if we could measure it, but 5s is safe)
    if (mounted) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final message = _getInstruction();

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_outlined,
            color: Colors.white,
            size: 80,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
