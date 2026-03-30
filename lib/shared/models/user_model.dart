import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['nama_user'] as String? ?? map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['no_telephone'] as String? ?? map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    if (phone != null) 'no_telephone': phone,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
