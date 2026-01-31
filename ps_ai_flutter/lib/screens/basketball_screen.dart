import 'package:flutter/material.dart';
import 'train_shoots_screen.dart';
import 'dashboard_screen.dart';

class BasketballScreen extends StatelessWidget {
  const BasketballScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basketball'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.sports_basketball,
              size: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 40),
            _buildNavButton(
              context,
              title: 'Train Shoots',
              icon: Icons.fitness_center,
              color: Colors.orange.shade700,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainShootsScreen(),
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
          ],
        ),
      ),
    );
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
