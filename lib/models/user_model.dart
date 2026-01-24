/// Model untuk User Data
class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String name;
  final String? avatar;
  final String? address;
  final String? date_of_birth;
  final String role;
  final bool isProfileComplete;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    required this.name,
    this.avatar,
    this.address,
    this.date_of_birth,
    required this.role,
    required this.isProfileComplete,
  });

  /// Convert dari JSON response ke UserModel object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct response and nested profile structure
    final profileData = json['profile'] ?? json;

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'],
      phone: profileData['phone'],
      // API uses 'full_name', fallback to 'name' for backward compatibility
      name: profileData['full_name'] ?? json['name'] ?? '',
      // API uses 'profil_url', fallback to 'avatar' for backward compatibility
      avatar: profileData['profil_url'] ?? json['avatar'],
      address: profileData['address'],
      date_of_birth: profileData['date_of_birth'],
      role: profileData['role'] ?? json['role'] ?? 'user',
      // Check if important fields are filled to determine profile completeness
      isProfileComplete:
          (profileData['full_name'] ?? json['name'] ?? '').isNotEmpty &&
          (profileData['phone'] ?? '') != '',
    );
  }

  /// Convert dari UserModel object ke JSON untuk disimpan
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': name, // Store as full_name to match API
      'name': name, // Keep for backward compatibility
      'profil_url': avatar, // Store as profil_url to match API
      'avatar': avatar, // Keep for backward compatibility
      'address': address,
      'date_of_birth': date_of_birth,
      'role': role,
      'isProfileComplete': isProfileComplete,
    };
  }

  /// Copy dengan perubahan tertentu
  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? name,
    String? avatar,
    String? address,
    String? date_of_birth,
    String? role,
    bool? isProfileComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      address: address ?? this.address,
      date_of_birth: date_of_birth ?? this.date_of_birth,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
