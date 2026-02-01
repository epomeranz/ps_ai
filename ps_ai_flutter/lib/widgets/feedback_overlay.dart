import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/providers/capture_provider.dart';
import '../core/providers/feedback_provider.dart';
import '../models/analysis_data.dart';

class FeedbackOverlay extends ConsumerStatefulWidget {
  final int peopleCount;

  const FeedbackOverlay({
    super.key,
    required this.peopleCount,
  });

  @override
  ConsumerState<FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends ConsumerState<FeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FlutterTts _flutterTts;
  String? _lastAnimationEvent;
  String? _lastAudioMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _flutterTts = FlutterTts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerAnimation(String event) {
    if (_lastAnimationEvent == event && _animationController.isAnimating) {
      return;
    }

    setState(() {
      _lastAnimationEvent = event;
    });

    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _animationController.reverse();
        });
      }
    });
  }

  void _playAudio(String message) async {
    if (_lastAudioMessage == message)
      return; // Simple debounce if repeated exactly same?
    // Actually, Analyzer throttles time, but effectively we should just speak independent of equality if time passed.
    // But here we receive stream updates every frame? No, feedback might be frequent.
    // The Analyzer throttles the *presence* of audioMessage.
    // If audioMessage is present, we speak it. BUT we must ensure we don't queue up 100 times.

    // Analyzer logic sets audioMessage ONLY ONCE (when time threshold met).
    // Wait, if it sets it, it will be in the FeedbackOutput for that frame.
    // If the next frame (33ms later) doesn't have it, good.
    // If the Analyzer logic sets it for *multiple frames* while condition holds?
    // My Analyzer logic: `if (now - last > 3s) { audioMsg = ...; last = now; }`
    // This updates `_lastSpokenTime` IMMEDIATELY. So next frame `difference > 3s` will be FALSE.
    // So `audioMsg` will be non-null for EXACTLY ONE FRAME (or a few calls).

    // So here, we just speak if audioMessage is not null.
    // However, `feedbackStreamProvider` might re-emit same value?
    // Let's just check if it's different from last handled or just fire.
    // Since Analyzer ensures sparsity, we can probably just speak.

    // But to be safe, let's store last message or just rely on TTS queue:
    // `await _flutterTts.speak(message);`
    // If we await, we block UI? No.
    await _flutterTts.speak(message);
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureControllerProvider);
    final feedbackAsync = ref.watch(feedbackStreamProvider);

    return Positioned(
      top: 40,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Feedback Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            width: 200, // Fixed width for consistent layout
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Status & Counts)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (captureState.status == CaptureStatus.recording)
                      _buildRecordingIndicator()
                    else
                      const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'People: ${captureState.poses.length} / ${widget.peopleCount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          'Objects: ${captureState.objects.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Feedback Content
                feedbackAsync.when(
                  data: (feedback) {
                    if (feedback.animationEvent != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _triggerAnimation(feedback.animationEvent!);
                      });
                    }
                    if (feedback.audioMessage != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _playAudio(feedback.audioMessage!);
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Score Indicator
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withValues(alpha: 0.5),
                                Colors.yellow.withValues(alpha: 0.5),
                                Colors.green.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment(
                              (feedback.score * 2) - 1, // Map 0..1 to -1..1
                              0,
                            ),
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: feedback.indicatorColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: feedback.indicatorColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Percentage Text
                        Text(
                          'Score: ${(feedback.score * 100).toInt()}%',
                          style: TextStyle(
                            color: feedback.indicatorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Feedback Message
                        Text(
                          feedback.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Specialized Feedback (Basketball)
                        if (feedback is BasketballShootingFeedback) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (feedback.releaseAngle != null)
                                  Text(
                                    'Angle: ${feedback.releaseAngle!.toStringAsFixed(1)}°',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                if (feedback.shotArc != null)
                                  Text(
                                    'Arc: ${feedback.shotArc!.toStringAsFixed(1)}°',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Specialized Feedback (Gym)
                        if (feedback is GymFeedback) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (feedback.phase != null)
                                  Text(
                                    'Phase: ${feedback.phase}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                if (feedback.reps != null)
                                  Text(
                                    'Reps: ${feedback.reps}',
                                    style: const TextStyle(
                                      color: Colors.white, // Emphasize reps
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Text(
                    'Initializing analysis...',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  error: (_, _) => const Text(
                    'Analysis unavailable',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Animation Overlay
          if (_animationController.isAnimating ||
              _animationController.isCompleted)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildAnimationContent(_lastAnimationEvent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'REC',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnimationContent(String? event) {
    if (event == "congrats") {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Great Job!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
