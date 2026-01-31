import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feedback_service.dart';
import 'capture_provider.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService();
  ref.onDispose(() => service.dispose());
  return service;
});

final feedbackStreamProvider = StreamProvider<FeedbackOutput>((ref) {
  final service = ref.watch(feedbackServiceProvider);

  // Listen to capture state changes to drive analysis
  // We use listen instead of watch to trigger side-effects without rebuilding the stream
  ref.listen<CaptureState>(captureControllerProvider, (previous, next) {
    service.analyzeFrame(next);
  });

  return service.feedbackStream;
});
