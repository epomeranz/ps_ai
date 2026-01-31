import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ps_ai_flutter/core/providers/firebase_providers.dart';
import 'package:ps_ai_flutter/core/services/tracking_repository.dart';
import 'package:ps_ai_flutter/models/exercise_metadata.dart';
import 'exercise_creation_screen.dart';
import 'training_screen.dart';
import 'dashboard_screen.dart';

class GymScreen extends ConsumerWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final profileId = userAsync.value?.uid ?? 'anonymous';

    // Stream of custom exercises
    final customExercisesStream = ref
        .watch(trackingRepositoryProvider)
        .getCustomExercises(profileId, 'gym');

    return Scaffold(
      appBar: AppBar(
        title: const Text('In The Gym'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExerciseCreationScreen(),
            ),
          );
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Header / Dashboard Link
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  radius: 24,
                  child: const Icon(Icons.dashboard, color: Colors.white),
                ),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: const Text('View your progress and stats'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<ExerciseMetadata>>(
                stream: customExercisesStream,
                builder: (context, snapshot) {
                  // Default exercise
                  final List<ExerciseItem> exercises = [
                    ExerciseItem(
                      id: 'Squat',
                      name: 'Train Squats',
                      icon: Icons.fitness_center,
                      color: Colors.green.shade700,
                      sportType: 'gym',
                      exerciseType: 'Squat',
                    ),
                  ];

                  if (snapshot.hasData) {
                    for (var meta in snapshot.data!) {
                      exercises.add(
                        ExerciseItem(
                          id: meta.id,
                          name: meta.name,
                          icon: _getIconData(meta.iconName),
                          color: Color(meta.colorValue),
                          sportType: meta.sportType,
                          exerciseType: meta.id,
                        ),
                      );
                    }
                  }

                  return ListView.separated(
                    itemCount: exercises.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = exercises[index];
                      return _buildExerciseCard(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: item.color,
          child: Icon(item.icon, color: Colors.white),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingScreen(
              sportType: item.sportType,
              exerciseType: item.exerciseType,
              baseColor: item.color,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'directions_run':
        return Icons.directions_run;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'pool':
        return Icons.pool;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics;
      default:
        return Icons.fitness_center;
    }
  }
}

class ExerciseItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String sportType;
  final String exerciseType;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sportType,
    required this.exerciseType,
  });
}
