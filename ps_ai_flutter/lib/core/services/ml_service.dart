import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class MLService {
  PoseDetector? _poseDetector;
  ObjectDetector? _objectDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Pose Detector
    final poseOptions = PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    );
    _poseDetector = PoseDetector(options: poseOptions);

    // Object Detector
    // For now we use the base model (prominent object) enabling multiple objects and classification
    final objectOptions = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: objectOptions);

    _isInitialized = true;
  }

  Future<List<Pose>> processPose(InputImage inputImage) async {
    if (!_isInitialized || _poseDetector == null) return [];
    try {
      return await _poseDetector!.processImage(inputImage);
    } catch (e) {
      // debugPrint('Error processing pose: $e');
      return [];
    }
  }

  Future<List<DetectedObject>> processObjects(InputImage inputImage) async {
    if (!_isInitialized || _objectDetector == null) return [];
    try {
      return await _objectDetector!.processImage(inputImage);
    } catch (e) {
      // debugPrint('Error processing objects: $e');
      return [];
    }
  }

  Future<void> dispose() async {
    await _poseDetector?.close();
    await _objectDetector?.close();
    _poseDetector = null;
    _objectDetector = null;
    _isInitialized = false;
  }
}
