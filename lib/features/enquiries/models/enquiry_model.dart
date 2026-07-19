class EnquiryUserModel {
  final String id;
  final String name;
  final String email;
  final String? mobNo1;
  final String? picture;
  final String? gender;
  final String? aadharNumber;
  final String? aadharFileUrl;

  EnquiryUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.mobNo1,
    this.picture,
    this.gender,
    this.aadharNumber,
    this.aadharFileUrl,
  });

  factory EnquiryUserModel.fromJson(Map<String, dynamic> json) {
    return EnquiryUserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobNo1: json['mobNo1'],
      picture: json['picture'],
      gender: json['gender'],
      aadharNumber: json['aadharNumber'],
      aadharFileUrl: json['aadharFileUrl'],
    );
  }
}

class EnquiryPgModel {
  final String id;
  final String name;

  EnquiryPgModel({required this.id, required this.name});

  factory EnquiryPgModel.fromJson(Map<String, dynamic> json) {
    return EnquiryPgModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class EnquiryPostModel {
  final String id;
  final String title;
  final String? occupancyType;
  final bool isActive;
  final double? maxPrice;
  final double? minPrice;

  EnquiryPostModel({
    required this.id,
    required this.title,
    this.occupancyType,
    this.isActive = true,
    this.maxPrice,
    this.minPrice,
  });

  factory EnquiryPostModel.fromJson(Map<String, dynamic> json) {
    return EnquiryPostModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      occupancyType: json['occupancyType'],
      isActive: json['isActive'] ?? true,
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      minPrice: (json['minPrice'] as num?)?.toDouble(),
    );
  }
}

class EnquiryModel {
  final String id;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? staffRemarks;
  final EnquiryUserModel? user;
  final EnquiryPgModel? pg;
  final EnquiryPostModel? post;

  EnquiryModel({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.staffRemarks,
    this.user,
    this.pg,
    this.post,
  });

  factory EnquiryModel.fromJson(Map<String, dynamic> json) {
    return EnquiryModel(
      id: json['_id'] ?? json['id'] ?? '',
      status: json['status'] ?? 'interested',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      staffRemarks: json['staffRemarks'],
      user: json['userId'] is Map<String, dynamic>
          ? EnquiryUserModel.fromJson(json['userId'])
          : null,
      pg: json['pgId'] is Map<String, dynamic>
          ? EnquiryPgModel.fromJson(json['pgId'])
          : null,
      post: json['postId'] is Map<String, dynamic>
          ? EnquiryPostModel.fromJson(json['postId'])
          : null,
    );
  }
}
