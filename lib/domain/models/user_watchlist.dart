class UserWatchlist {
  final String id;
  final String userId;
  final String ingredientId;
  final String createdAt;

  const UserWatchlist({
    required this.id,
    required this.userId,
    required this.ingredientId,
    required this.createdAt,
  });

  factory UserWatchlist.fromJson(Map<String, dynamic> json) {
    return UserWatchlist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ingredientId: json['ingredient_id'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ingredient_id': ingredientId,
      'created_at': createdAt,
    };
  }
}
