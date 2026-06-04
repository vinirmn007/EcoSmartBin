class UserProfile {
  final String userId;
  final String email;
  final String nombres;
  final String apellidos;
  final String cedula;
  final String? facultad;
  final String role;
  final int puntosEcologicos;
  final bool isActive;
  final String createdAt;

  UserProfile({
    required this.userId,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.cedula,
    this.facultad,
    required this.role,
    required this.puntosEcologicos,
    required this.isActive,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      cedula: json['cedula'] ?? '',
      facultad: json['facultad'],
      role: json['role'] ?? 'user',
      puntosEcologicos: json['puntos_ecologicos'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'nombres': nombres,
      'apellidos': apellidos,
      'cedula': cedula,
      'facultad': facultad,
      'role': role,
      'puntos_ecologicos': puntosEcologicos,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  String get nombreCompleto => '$nombres $apellidos';
}
