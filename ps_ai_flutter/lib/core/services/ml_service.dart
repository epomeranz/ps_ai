import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/ml_kit_utils.dart';

// Commands
enum _MLCommandType { init, process, dispose }

class _MLCommand {
  final _MLCommandType type;
  final SendPort? sendPort;
  final RootIsolateToken? token;
  final FrameDataFromCameraImage? frameData;
  final bool detectObjects;

  _MLCommand({
    required this.type,
    this.sendPort,
    this.token,
    this.frameData,
    this.detectObjects = false,
  });
}

class _MLResponse {
  final List<Pose>? poses;
  final List<DetectedObject>? objects;
  final String? error;

  _MLResponse({
    this.poses,
    this.objects,
    this.error,
  });
}

/// A service that runs MLKit detectors in a background isolate.
class MLService {
  SendPort? _sendPort;
  bool _isInitialized = false;

  // Since we are async, we need a way to map requests to responses if we were doing concurrent requests.
  // However, for a camera stream, we usually just fire and forget or wait for the next frame.
  // To keep it simple and robust, we will use a single ReceivePort for the main thread to listen to results.
  ReceivePort? _receivePort;

  // We need to complete a future when we get a response.
  // For a simple stream processing, we can just expose a stream of results or return Futures.
  // Since the user used Future<List<Pose>> processPose, we should try to maintain that API if possible,
  // but it's tricky with a single persistent isolate without a request ID map.
  // Given the usage in CaptureController, it waits for the result.

  // To implement Future-based API, we need a Completer map.
  int _nextRequestId = 0;
  final Map<int, Completer<_MLResponse>> _pendingRequests = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    _receivePort = ReceivePort();
    final rootIsolateToken = RootIsolateToken.instance;

    await Isolate.spawn(
      _isolateEntry,
      _MLCommand(
        type: _MLCommandType.init,
        sendPort: _receivePort!.sendPort,
        token: rootIsolateToken,
      ),
    );

    // Listen for responses
    _receivePort!.listen(_handleResponse);

    _isInitialized = true;
  }

  void _handleResponse(dynamic message) {
    if (message is _IsolateResponseWrapper) {
      final completer = _pendingRequests.remove(message.id);
      if (completer != null) {
        if (message.response.error != null) {
          // We might not want to throw to avoid crashing the app, but logging is good
          completer.complete(_MLResponse(error: message.response.error));
        } else {
          completer.complete(message.response);
        }
      }
    } else if (message is SendPort) {
      _sendPort = message;
    }
  }

  Future<MLResult> processFrame(
    FrameDataFromCameraImage frameData, {
    bool detectObjects = false,
  }) async {
    if (!_isInitialized || _sendPort == null) {
      return MLResult(poses: [], objects: []);
    }

    final id = _nextRequestId++;
    final completer = Completer<_MLResponse>();
    _pendingRequests[id] = completer;

    _sendPort!.send(
      _IsolateRequestWrapper(
        id,
        _MLCommand(
          type: _MLCommandType.process,
          frameData: frameData,
          detectObjects: detectObjects,
        ),
      ),
    );

    final response = await completer.future;
    return MLResult(
      poses: response.poses ?? [],
      objects: response.objects ?? [],
    );
  }

  Future<List<Pose>> processPose(InputImage inputImage) async {
    // Deprecated/Not supported in this new mode which takes FrameData
    // We keep it to avoid breaking compilation immediately if used elsewhere,
    // but the intention is to replace usage with processFrame.
    return [];
  }

  Future<List<DetectedObject>> processObjects(InputImage inputImage) async {
    return [];
  }

  Future<void> dispose() async {
    _sendPort?.send(
      _IsolateRequestWrapper(-1, _MLCommand(type: _MLCommandType.dispose)),
    );
    // Do not kill immediately. Let the isolate clean up and kill itself.
    _receivePort?.close();
    _sendPort = null;
    _isInitialized = false;
    _pendingRequests.clear();
  }
}

class MLResult {
  final List<Pose> poses;
  final List<DetectedObject> objects;

  MLResult({required this.poses, required this.objects});
}

// Internal wrapper for request/response correlation
class _IsolateRequestWrapper {
  final int id;
  final _MLCommand command;
  _IsolateRequestWrapper(this.id, this.command);
}

class _IsolateResponseWrapper {
  final int id;
  final _MLResponse response;
  _IsolateResponseWrapper(this.id, this.response);
}

// Isolate Entry Point
void _isolateEntry(_MLCommand initCommand) async {
  final receivePort = ReceivePort();
  final mainSendPort = initCommand.sendPort!;

  // Register background channel
  if (initCommand.token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(initCommand.token!);
  }

  // Initialize detectors
  final poseOptions = PoseDetectorOptions(
    model: PoseDetectionModel.accurate,
    mode: PoseDetectionMode.stream,
  );
  final poseDetector = PoseDetector(options: poseOptions);

  final objectOptions = ObjectDetectorOptions(
    mode: DetectionMode.stream,
    classifyObjects: true,
    multipleObjects: true,
  );
  final objectDetector = ObjectDetector(options: objectOptions);

  // Send our sendPort back to main
  mainSendPort.send(receivePort.sendPort);

  await for (final message in receivePort) {
    if (message is _IsolateRequestWrapper) {
      final cmd = message.command;
      if (cmd.type == _MLCommandType.dispose) {
        await poseDetector.close();
        await objectDetector.close();
        Isolate.current.kill();
        break;
      } else if (cmd.type == _MLCommandType.process && cmd.frameData != null) {
        try {
          final inputImage = MLKitUtils.inputImageFromFrameData(cmd.frameData!);
          if (inputImage == null) {
            mainSendPort.send(
              _IsolateResponseWrapper(
                message.id,
                _MLResponse(poses: [], objects: []),
              ),
            );
            continue;
          }

          final poses = await poseDetector.processImage(inputImage);

          List<DetectedObject> objects = [];
          if (cmd.detectObjects) {
            objects = await objectDetector.processImage(inputImage);
          }

          mainSendPort.send(
            _IsolateResponseWrapper(
              message.id,
              _MLResponse(poses: poses, objects: objects),
            ),
          );
        } catch (e) {
          mainSendPort.send(
            _IsolateResponseWrapper(
              message.id,
              _MLResponse(error: e.toString()),
            ),
          );
        }
      }
    }
  }
}
