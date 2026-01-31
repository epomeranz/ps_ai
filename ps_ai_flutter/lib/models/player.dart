class Player {
  final String id;
  final String name;
  final String? email;
  final DateTime? birthday;
  final String? sex; // 'Male' or 'Female'

  Player({
    required this.id,
    required this.name,
    this.email,
    this.birthday,
    this.sex,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'birthday': birthday?.toIso8601String(),
      'sex': sex,
    };
  }

  factory Player.fromMap(String id, Map<String, dynamic> map) {
    return Player(
      id: id,
      name: map['name'] ?? '',
      email: map['email'],
      birthday: map['birthday'] != null
          ? DateTime.tryParse(map['birthday'])
          : null,
      sex: map['sex'],
    );
  }
}
