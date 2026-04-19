// ──────────────────────────────────────────────
// Profile Models
// Mirrors: pp-backend modules/users/services/profile.service.ts
// ──────────────────────────────────────────────

class UserProfile {
  final String? displayName;
  final String? email;
  final String? likes;
  final List<String> dietType;
  final List<String> allergies;
  final String? disliked;
  final String? notes;
  final bool onboardingCompleted;

  const UserProfile({
    this.displayName,
    this.email,
    this.likes,
    this.dietType = const [],
    this.allergies = const [],
    this.disliked,
    this.notes,
    this.onboardingCompleted = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      likes: json['likes'] as String?,
      dietType: (json['dietType'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      disliked: json['disliked'] as String?,
      notes: json['notes'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }
}

class UpdateProfilePayload {
  final String? displayName;
  final String? likes;
  final List<String>? dietType;
  final List<String>? allergies;
  final String? disliked;
  final String? notes;

  const UpdateProfilePayload({
    this.displayName,
    this.likes,
    this.dietType,
    this.allergies,
    this.disliked,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName,
        if (likes != null) 'likes': likes,
        if (dietType != null) 'dietType': dietType,
        if (allergies != null) 'allergies': allergies,
        if (disliked != null) 'disliked': disliked,
        if (notes != null) 'notes': notes,
      };
}
