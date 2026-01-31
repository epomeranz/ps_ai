import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';
import 'package:ps_ai_flutter/widgets/sports_capture_widget.dart';
import 'package:ps_ai_flutter/core/providers/player_providers.dart';

class TrainShootsScreen extends ConsumerWidget {
  const TrainShootsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const sportType = 'basketball';
    final playersAsync = ref.watch(playersStreamProvider);
    final activePlayerIdAsync = ref.watch(activePlayerProvider(sportType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Shoots'),
        backgroundColor: Colors.black,
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
                          .setActivePlayerId(sportType, newValue);
                    }
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SportsCaptureWidget(
        peopleCount: 1, // Default to 1 person
        objectConfigs: [
          TrackedObjectTypeConfig(
            label: 'Ball',
            expectedCount: 1,
          ), // Default to 1 ball
        ],
        profileId: 'user_123',
        sportType: sportType,
        exerciseType: 'shoting_training',
      ),
    );
  }
}
