import 'dart:convert';

enum UserRole { passenger, driver }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.vesselName,
    this.vesselCapacity,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;

  /// Driver-only details. Null for passengers.
  final String? vesselName;
  final int? vesselCapacity;

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? vesselName,
    int? vesselCapacity,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      vesselName: vesselName ?? this.vesselName,
      vesselCapacity: vesselCapacity ?? this.vesselCapacity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.name,
        'vesselName': vesselName,
        'vesselCapacity': vesselCapacity,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: j['email'] as String,
        name: j['name'] as String,
        role: UserRole.values.firstWhere((r) => r.name == j['role']),
        vesselName: j['vesselName'] as String?,
        vesselCapacity: j['vesselCapacity'] as int?,
      );

  String encode() => jsonEncode(toJson());
  static AppUser decode(String s) =>
      AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
