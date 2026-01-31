import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/capture_provider.dart';
import '../core/providers/feedback_provider.dart';

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
  String? _lastAnimationEvent;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerAnimation(String event) {
    if (_lastAnimationEvent == event && _animationController.isAnimating)
      return;

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
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
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
                                Colors.red.withOpacity(0.5),
                                Colors.yellow.withOpacity(0.5),
                                Colors.green.withOpacity(0.5),
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
                                    color: feedback.indicatorColor.withOpacity(
                                      0.5,
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                  loading: () => const Text(
                    'Initializing analysis...',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  error: (_, __) => const Text(
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
