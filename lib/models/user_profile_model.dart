class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String phoneNumber;
  final String? profilePic;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.phoneNumber,
    this.profilePic,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Unknown User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString().toLowerCase() ?? 'homebuyer',
      phoneNumber: json['phone_number']?.toString() ?? '',
      profilePic: json['profile_pic']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? phoneNumber,
    String? profilePic,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePic: profilePic ?? this.profilePic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
