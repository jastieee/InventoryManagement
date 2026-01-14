class User {
  final String id;
  final String username;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  // Create User from Map (Firestore data)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert User to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Check if user is regular user
  bool get isUser => role == 'user';

  // Copy with (for creating modified copies)
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.name == name &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    username.hashCode ^
    email.hashCode ^
    name.hashCode ^
    role.hashCode;
  }
}