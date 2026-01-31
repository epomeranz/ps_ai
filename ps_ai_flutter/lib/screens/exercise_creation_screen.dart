import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ps_ai_flutter/core/providers/firebase_providers.dart';
import 'package:ps_ai_flutter/models/exercise_metadata.dart';
import 'reference_capture_screen.dart';

class ExerciseCreationScreen extends ConsumerStatefulWidget {
  const ExerciseCreationScreen({super.key});

  @override
  ConsumerState<ExerciseCreationScreen> createState() =>
      _ExerciseCreationScreenState();
}

class _ExerciseCreationScreenState
    extends ConsumerState<ExerciseCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  String _cameraPosition = 'Front';
  String _gender = 'Female';
  String _ageRange = 'Adult';
  Color _selectedColor = Colors.green;
  IconData _selectedIcon = Icons.fitness_center;

  final List<String> _cameraPositions = [
    'Front',
    'Side (Left)',
    'Side (Right)',
    'Back',
    '45 Degree',
  ];

  final List<String> _genders = ['Female', 'Male', 'Child'];
  final List<String> _ageRanges = ['Child', 'Teen', 'Adult', 'Senior'];

  final List<Color> _colors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  final List<IconData> _icons = [
    Icons.fitness_center,
    Icons.directions_run,
    Icons.accessibility_new,
    Icons.pool,
    Icons.self_improvement,
    Icons.sports_gymnastics,
  ];

  // Helper to get string name of icon
  String _getIconName(IconData icon) {
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.directions_run) return 'directions_run';
    if (icon == Icons.accessibility_new) return 'accessibility_new';
    if (icon == Icons.pool) return 'pool';
    if (icon == Icons.self_improvement) return 'self_improvement';
    if (icon == Icons.sports_gymnastics) return 'sports_gymnastics';
    return 'fitness_center';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final userAsync = ref.read(authStateChangesProvider);
      final profileId = userAsync.value?.uid ?? 'anonymous';

      final metadata = ExerciseMetadata(
        id: _nameController.text.toLowerCase().replaceAll(' ', '_'),
        name: _nameController.text,
        sportType: 'gym', // Default for now as invoked from GymScreen
        cameraPosition: _cameraPosition,
        gender: _gender,
        ageRange: _ageRange,
        colorValue: _selectedColor.value,
        iconName: _getIconName(_selectedIcon),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReferenceCaptureScreen(
            metadata: metadata,
            profileId: profileId,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Exercise'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exercise Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Camera Position
              DropdownButtonFormField<String>(
                initialValue: _cameraPosition,
                decoration: InputDecoration(
                  labelText: 'Camera Position',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _cameraPositions.map((pos) {
                  return DropdownMenuItem(value: pos, child: Text(pos));
                }).toList(),
                onChanged: (val) => setState(() => _cameraPosition = val!),
              ),
              const SizedBox(height: 20),

              // Row for Gender and Age
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _genders.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _ageRange,
                      decoration: InputDecoration(
                        labelText: 'Age Range',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _ageRanges.map((a) {
                        return DropdownMenuItem(value: a, child: Text(a));
                      }).toList(),
                      onChanged: (val) => setState(() => _ageRange = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Color Selection
              const Text(
                'Color Theme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _colors.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Icon Selection
              const Text(
                'Sport Icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _icons.map((icon) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: _selectedIcon == icon
                            ? Border.all(color: _selectedColor, width: 3)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: _selectedIcon == icon
                            ? _selectedColor
                            : Colors.black54,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_camera_front),
                    SizedBox(width: 12),
                    Text(
                      'Capture Reference',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
