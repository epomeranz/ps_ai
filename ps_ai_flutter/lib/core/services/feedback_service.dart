import 'dart:async';
import '../providers/capture_provider.dart';
import '../../models/analysis_data.dart';
import '../analysis/sport_analyzer.dart';
import '../analysis/basketball_analyzer.dart';

// Re-export specific feedback types for consumers
export '../../models/analysis_data.dart';

class FeedbackService {
  final StreamController<AnalysisInput> _inputController =
      StreamController<AnalysisInput>.broadcast();
  SportAnalyzer? _currentAnalyzer;
  StreamSubscription? _analyzerSubscription;

  // Main output stream
  final StreamController<FeedbackOutput> _outputController =
      StreamController<FeedbackOutput>.broadcast();
  Stream<FeedbackOutput> get feedbackStream => _outputController.stream;

  FeedbackService() {
    _initializeAnalyzer('basketball', 'shooting'); // Default or dynamic
  }

  void _initializeAnalyzer(String sportType, String exerciseType) {
    _analyzerSubscription?.cancel();
    _currentAnalyzer?.dispose();

    // Factory logic
    if (sportType == 'basketball') {
      _currentAnalyzer = BasketballShootingAnalyzer();
    } else {
      // Fallback or generic analyzer
      // _currentAnalyzer = GenericAnalyzer();
      // For now, let's just stick with one or throw/log.
      _currentAnalyzer = BasketballShootingAnalyzer();
    }

    // Connect pipelines
    if (_currentAnalyzer != null) {
      _analyzerSubscription = _currentAnalyzer!
          .analyze(_inputController.stream)
          .listen((output) {
            _outputController.add(output);
          });
    }
  }

  void analyzeFrame(CaptureState captureState) {
    if (captureState.status != CaptureStatus.recording) return;

    // Convert CaptureState to AnalysisInput
    final input = LiveAnalysisInput(
      poses: captureState.poses,
      objects: captureState.objects,
      session: captureState.currentSession!,
    );

    _inputController.add(input);
  }

  void dispose() {
    _analyzerSubscription?.cancel();
    _currentAnalyzer?.dispose();
    _inputController.close();
    _outputController.close();
  }
}
