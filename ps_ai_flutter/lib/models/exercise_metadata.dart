class ExerciseMetadata {
  final String id;
  final String name;
  final String sportType;
  final String cameraPosition;
  final String gender;
  final String ageRange;
  final int colorValue; // Storing int value of color
  final String iconName;

  ExerciseMetadata({
    required this.id,
    required this.name,
    required this.sportType,
    required this.cameraPosition,
    required this.gender,
    required this.ageRange,
    required this.colorValue,
    required this.iconName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sportType': sportType,
      'cameraPosition': cameraPosition,
      'gender': gender,
      'ageRange': ageRange,
      'colorValue': colorValue,
      'iconName': iconName,
    };
  }

  factory ExerciseMetadata.fromJson(Map<String, dynamic> json) {
    return ExerciseMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      sportType: json['sportType'] as String,
      cameraPosition: json['cameraPosition'] as String,
      gender: json['gender'] as String,
      ageRange: json['ageRange'] as String,
      colorValue: json['colorValue'] as int,
      iconName: json['iconName'] as String,
    );
  }
}
