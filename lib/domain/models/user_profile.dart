class UserProfile {
  final String userId;
  final String? fullName;
  final String languagePref;
  final bool isAdmin;
  final String updatedAt;

  const UserProfile({
    required this.userId,
    this.fullName,
    this.languagePref = 'en',
    this.isAdmin = false,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      languagePref: json['language_pref'] as String? ?? 'en',
      isAdmin: json['is_admin'] as bool? ?? false,
      updatedAt:
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'language_pref': languagePref,
      'is_admin': isAdmin,
      'updated_at': updatedAt,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? languagePref,
    bool? isAdmin,
    String? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      languagePref: languagePref ?? this.languagePref,
      isAdmin: isAdmin ?? this.isAdmin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
