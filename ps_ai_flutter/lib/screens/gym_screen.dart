import 'package:flutter/material.dart';
import 'training_screen.dart';
import 'dashboard_screen.dart';

class GymScreen extends StatelessWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In The Gym'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
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
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;
            return isPortrait
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildChildren(context),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 100,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildNavButtons(context),
                        ),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    return [
      const Icon(
        Icons.fitness_center,
        size: 100,
        color: Colors.green,
      ),
      const SizedBox(height: 40),
      ..._buildNavButtons(context),
    ];
  }

  List<Widget> _buildNavButtons(BuildContext context) {
    return [
      _buildNavButton(
        context,
        title: 'Train Squats',
        icon: Icons.fitness_center,
        color: Colors.green.shade700,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TrainingScreen(
              sportType: 'gym',
              exerciseType: 'Squat',
              baseColor: Colors.green,
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      _buildNavButton(
        context,
        title: 'Dashboard',
        icon: Icons.dashboard,
        color: Colors.blue.shade700,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        ),
      ),
    ];
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
