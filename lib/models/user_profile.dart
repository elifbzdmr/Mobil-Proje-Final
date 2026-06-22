class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phone,
    required this.avatarId,
    required this.favoriteGenre,
    required this.passwordHash,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final String avatarId;
  final String favoriteGenre;
  final String passwordHash;
  String get fullName => '$firstName $lastName'.trim();

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? avatarId,
    String? favoriteGenre,
    String? passwordHash,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarId: avatarId ?? this.avatarId,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'avatarId': avatarId,
      'favoriteGenre': favoriteGenre,
      'passwordHash': passwordHash,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final legacyName = (json['name'] as String? ?? '').trim();
    final firstName = (json['firstName'] as String? ?? '').trim();
    final lastName = (json['lastName'] as String? ?? '').trim();
    final username = (json['username'] as String? ?? '').trim();
    final email = json['email'] as String? ?? '';
    return UserProfile(
      firstName: firstName.isEmpty ? legacyName : firstName,
      lastName: lastName,
      username: username.isEmpty ? _usernameFromEmail(email) : username,
      email: email,
      phone: json['phone'] as String? ?? '',
      avatarId: json['avatarId'] as String? ?? 'avatar_1',
      favoriteGenre: json['favoriteGenre'] as String? ?? 'Karisik',
      passwordHash: json['passwordHash'] as String? ?? '',
    );
  }

  static String _usernameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    return prefix.isEmpty ? 'bimuzik' : prefix;
  }
}
