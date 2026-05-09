class Profile {
  final String id;
  final String createdAt;
  final String? displayName;

  const Profile({
    required this.id,
    required this.createdAt,
    this.displayName,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      createdAt: json['created_at'] as String,
      displayName: json['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt,
      'display_name': displayName,
    };
  }
}
