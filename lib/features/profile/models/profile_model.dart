class UserProfile {
  final String id;
  final String name;
  final String email;
  final String mobNo1;
  final String? mobNo2;
  final String role;
  final String? picture;
  final String? gender;
  final String? profileImageKey;
  final String? aadharNumber;
  final String? aadharFileKey;
  final String? aadharFileUrl;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final String? vehicleType;
  final String? vehicleNumber;
  
  // Address fields
  final String? pincode;
  final String? locationDescription;
  final String? landmark;
  final String? city;
  final String? state;
  final String? country;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.mobNo1,
    this.mobNo2,
    required this.role,
    this.picture,
    this.gender,
    this.profileImageKey,
    this.aadharNumber,
    this.aadharFileKey,
    this.aadharFileUrl,
    this.isEmailVerified = false,
    this.createdAt,
    this.vehicleType,
    this.vehicleNumber,
    this.pincode,
    this.locationDescription,
    this.landmark,
    this.city,
    this.state,
    this.country,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final user = json['data'] ?? json['user'] ?? json;
    
    final address = user['address'] as Map<String, dynamic>?;

    return UserProfile(
      id: user['_id'] ?? user['id'] ?? '',
      name: user['name'] ?? '',
      email: user['email'] ?? '',
      mobNo1: user['mobNo1'] ?? '',
      mobNo2: user['mobNo2'],
      role: user['role'] ?? 'user',
      picture: user['picture'],
      gender: user['gender'],
      profileImageKey: user['profileImageKey'],
      aadharNumber: user['aadharNumber'],
      aadharFileKey: user['aadharFileKey'],
      aadharFileUrl: user['aadharFileUrl'],
      isEmailVerified: user['isEmailVerified'] ?? false,
      createdAt: user['createdAt'] != null ? DateTime.tryParse(user['createdAt']) : null,
      vehicleType: user['vehicleType'],
      vehicleNumber: user['vehicleNumber'],
      pincode: address?['pincode']?.toString(),
      locationDescription: address?['locationDescription'],
      landmark: address?['landmark'],
      city: address?['city'],
      state: address?['state'],
      country: address?['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobNo1': mobNo1,
      'mobNo2': mobNo2,
      'gender': gender,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'address': {
        'pincode': pincode,
        'locationDescription': locationDescription,
        'landmark': landmark,
        'city': city,
        'state': state,
        'country': country,
      }
    };
  }
}
