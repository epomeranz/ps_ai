import 'package:flutter/material.dart';
import 'package:ps_ai_flutter/models/tracking_data.dart';
import 'package:ps_ai_flutter/widgets/sports_capture_widget.dart';

class TrainShootsScreen extends StatelessWidget {
  const TrainShootsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Shoots'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SportsCaptureWidget(
        peopleCount: 1, // Default to 1 person
        objectConfigs: [
          TrackedObjectTypeConfig(
            label: 'Ball',
            expectedCount: 1,
          ), // Default to 1 ball
        ],
        profileId: 'user_123', // TODO: Get from Auth Provider
        sportType: 'basketball',
        exerciseType: 'shoting_training',
      ),
    );
  }
}
