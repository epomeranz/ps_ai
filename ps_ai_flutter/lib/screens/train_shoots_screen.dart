import 'package:flutter/material.dart';

class TrainShootsScreen extends StatelessWidget {
  const TrainShootsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Shoots'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Train Shoots Page (Empty)'),
      ),
    );
  }
}
