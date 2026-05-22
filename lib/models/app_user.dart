class AppUser {
  final String id;
  final String name;
  final String email;
  final String password; // local password for offline auth
  final String role; // agent or admin
  final String location;
  final bool isActive; // false means suspended
  final String syncStatus;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.location,
    this.isActive = true,
    this.syncStatus = 'pending',
  });

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      location: map['location'],
      isActive: map['isActive'] ?? true,
      syncStatus: map['syncStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'location': location,
      'isActive': isActive,
      'syncStatus': syncStatus,
    };
  }
}