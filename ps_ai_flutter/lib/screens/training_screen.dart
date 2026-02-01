import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ps_ai_flutter/widgets/sports_capture_widget.dart';
import 'package:ps_ai_flutter/core/providers/player_providers.dart';
import 'package:ps_ai_flutter/core/providers/firebase_providers.dart';
import 'package:ps_ai_flutter/core/providers/feedback_provider.dart';
import 'package:ps_ai_flutter/core/services/tracking_repository.dart';
import 'package:ps_ai_flutter/core/providers/capture_provider.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  final String sportType;
  final String exerciseType;
  final Color baseColor;

  const TrainingScreen({
    super.key,
    required this.sportType,
    required this.exerciseType,
    required this.baseColor,
  });

  @override
  ConsumerState<TrainingScreen> createState() => _GymTrainingScreenState();
}

class _GymTrainingScreenState extends ConsumerState<TrainingScreen> {
  @override
  void initState() {
    super.initState();
    // Configure the analyzer for the specific gym exercise
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authStateChangesProvider).value;
      if (user != null) {
        final referenceSession = await ref
            .read(trackingRepositoryProvider)
            .getReferenceSession(
              user.uid,
              widget.sportType,
              widget.exerciseType,
            );

        ref
            .read(feedbackServiceProvider)
            .setAnalyzerConfig(
              widget.sportType,
              widget.exerciseType,
              widget.baseColor,
              referenceSession: referenceSession,
            );
      } else {
        // Just set without reference if no user
        ref
            .read(feedbackServiceProvider)
            .setAnalyzerConfig(
              widget.sportType,
              widget.exerciseType,
              widget.baseColor,
            );
      }

      _fetchSessionHistory();
    });
  }

  void _setupCaptureListener() {
    ref.listen<CaptureState>(captureControllerProvider, (previous, next) async {
      // Detect transition from recording to not recording
      if (previous?.status == CaptureStatus.recording &&
          next.status != CaptureStatus.recording) {
        final user = ref.read(authStateChangesProvider).value;
        if (user != null) {
          // Trigger saving of analysis results
          await ref.read(feedbackServiceProvider).finishSession(user.uid);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session analysis saved!')),
            );
          }
        }
      }
    });
  }

  Future<void> _fetchSessionHistory() async {
    // TODO: Retrieve past 3 months of session for that player and exercise
    // ref.read(analysisServiceProvider).getHistory(widget.sportType, widget.exerciseType);
    print("Fetching history for ${widget.exerciseType}");
  }

  @override
  Widget build(BuildContext context) {
    _setupCaptureListener();

    final playersAsync = ref.watch(playersStreamProvider);
    final activePlayerIdAsync = ref.watch(
      activePlayerProvider(widget.sportType),
    );
    final userAsync = ref.watch(authStateChangesProvider);
    final profileId = userAsync.value?.uid ?? 'anonymous';

    return Scaffold(
      appBar: AppBar(
        title: Text('Train ${widget.exerciseType}'), // e.g. Train Squat
        backgroundColor: widget.baseColor,
        foregroundColor: Colors.white,
        actions: [
          playersAsync.when(
            data: (players) {
              final activeId = activePlayerIdAsync.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButton<String>(
                  value: players.any((p) => p.id == activeId) ? activeId : null,
                  hint: const Text(
                    'Select Player',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.person, color: Colors.white),
                  items: players.map((player) {
                    return DropdownMenuItem<String>(
                      value: player.id,
                      child: Text(player.name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      ref
                          .read(playerServiceProvider)
                          .setActivePlayerId(widget.sportType, newValue);
                    }
                  },
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SportsCaptureWidget(
        peopleCount: 1, // Default to 1 person for gym exercises
        objectConfigs:
            const [], // Usually no ball tracking for gym unless specified
        profileId: profileId,
        sportType: widget.sportType,
        exerciseType: widget.exerciseType,
      ),
    );
  }
}
