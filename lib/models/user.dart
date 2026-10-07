class User {
  final String id;
  final String name;
  final String serviceId;
  final String pinHash;
  final String role; // 'admin' ou 'agent'
  final bool mustChangePin;

  User({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.pinHash,
    required this.role,
    this.mustChangePin = false,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'service_id': serviceId,
      'pin_hash': pinHash,
      'role': role,
      'must_change_pin': mustChangePin ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      serviceId: map['service_id'] as String,
      pinHash: map['pin_hash'] as String,
      role: map['role'] as String? ?? 'agent',
      mustChangePin: (map['must_change_pin'] as int? ?? 0) == 1,
    );
  }
}
