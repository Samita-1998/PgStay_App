class PgPost {
  final String id;
  final String title;
  final String description;
  final int vacancyCount;
  final int? maleVacancyCount;
  final int? femaleVacancyCount;
  final String occupancyType;
  final String pgType;
  final double? minPrice;
  final double? maxPrice;
  final String createdAt;
  final String? availableFrom;
  final PgModel pg;
  final EnquiryData? enquiryData;
  final List<String> images;
  final List<String> occupancyTypes;
  final bool isActive;
  final List<Map<String, String>> facilities;

  PgPost({
    required this.id,
    required this.title,
    required this.description,
    required this.vacancyCount,
    this.maleVacancyCount,
    this.femaleVacancyCount,
    required this.occupancyType,
    required this.pgType,
    this.minPrice,
    this.maxPrice,
    required this.createdAt,
    this.availableFrom,
    required this.pg,
    this.enquiryData,
    this.images = const [],
    this.occupancyTypes = const [],
    this.isActive = true,
    this.facilities = const [],
  });

  factory PgPost.fromJson(Map<String, dynamic> json) {
    return PgPost(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      vacancyCount: (json['vacancyCount'] as num?)?.toInt() ?? 0,
      maleVacancyCount: (json['maleVacancyCount'] as num?)?.toInt(),
      femaleVacancyCount: (json['femaleVacancyCount'] as num?)?.toInt(),
      occupancyType: json['occupancyType'] ?? 'single',
      pgType: json['pgType'] ?? 'Coliving',
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      createdAt: json['createdAt'] ?? '',
      availableFrom: json['availableFrom'],
      pg: json['pgId'] is Map<String, dynamic>
          ? PgModel.fromJson(json['pgId'])
          : PgModel.empty(),
      enquiryData: json['enquiryData'] != null
          ? EnquiryData.fromJson(json['enquiryData'])
          : null,
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      occupancyTypes: (json['occupancyTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['isActive'] ?? true,
      facilities: (json['facilities'] as List<dynamic>?)?.map((f) {
        if (f is Map) {
          return {
            'id': f['_id']?.toString() ?? '',
            'name': f['name']?.toString() ?? '',
          };
        }
        return {'id': '', 'name': f.toString()};
      }).toList() ?? [],
    );
  }
}

class PgModel {
  final String id;
  final String name;
  final double rating;
  final String checkInTime;
  final String checkOutTime;
  final PgAddress address;
  final List<String> facilities;
  final int totalRooms;
  final int totalBeds;
  final int occupiedBeds;
  final int emptyBeds;
  final bool isActive;
  final String pgType;
  final String? managerId;
  final String? managerName;
  final String? description;
  final String? pgStartedDate;
  final int? dueDayOfMonth;
  final String? landline;
  final String? locationLink;

  PgModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.checkInTime,
    required this.checkOutTime,
    required this.address,
    required this.facilities,
    required this.totalRooms,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.emptyBeds,
    required this.isActive,
    required this.pgType,
    this.managerId,
    this.managerName,
    this.description,
    this.pgStartedDate,
    this.dueDayOfMonth,
    this.landline,
    this.locationLink,
  });

  factory PgModel.fromJson(Map<String, dynamic> json) {
    var rawFacilities = json['facilities'] ?? [];
    List<String> parsedFacilities = [];
    if (rawFacilities is List) {
      for (var f in rawFacilities) {
        if (f is Map<String, dynamic> && f['name'] != null) {
          parsedFacilities.add(f['name'].toString());
        } else if (f is String) {
          parsedFacilities.add(f);
        }
      }
    }

    return PgModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      checkInTime: json['checkInTime'] ?? '12:00 PM',
      checkOutTime: json['checkOutTime'] ?? '11:00 AM',
      address: json['address'] is Map<String, dynamic>
          ? PgAddress.fromJson(json['address'])
          : PgAddress.empty(),
      facilities: parsedFacilities,
      totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
      totalBeds: (json['totalBeds'] as num?)?.toInt() ?? 0,
      occupiedBeds: (json['occupiedBeds'] as num?)?.toInt() ?? 0,
      emptyBeds: (json['emptyBeds'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
      pgType: json['pgType'] ?? 'Co-Living',
      managerId: json['managerId'] is Map
          ? (json['managerId']['_id'] ?? json['managerId']['id'])?.toString()
          : json['managerId']?.toString(),
      managerName: json['managerId'] is Map
          ? json['managerId']['name']?.toString()
          : null,
      description: json['description']?.toString(),
      pgStartedDate: json['pgStartedDate']?.toString(),
      dueDayOfMonth: (json['dueDayOfMonth'] as num?)?.toInt(),
      landline: json['landline']?.toString(),
      locationLink: json['locationLink']?.toString(),
    );
  }

  factory PgModel.empty() {
    return PgModel(
      id: '',
      name: 'StaySync PG',
      rating: 4.0,
      checkInTime: '12:00 PM',
      checkOutTime: '11:00 AM',
      address: PgAddress.empty(),
      facilities: [],
      totalRooms: 0,
      totalBeds: 0,
      occupiedBeds: 0,
      emptyBeds: 0,
      isActive: true,
      pgType: 'Co-Living',
      managerId: null,
      managerName: null,
    );
  }
}

class PgAddress {
  final String landmark;
  final String city;
  final String state;
  final String country;
  final int pincode;
  final String? locationDescription;

  PgAddress({
    required this.landmark,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.locationDescription,
  });

  factory PgAddress.fromJson(Map<String, dynamic> json) {
    return PgAddress(
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? 'India',
      pincode: (json['pincode'] as num?)?.toInt() ?? 0,
      locationDescription: json['locationDescription']?.toString(),
    );
  }

  factory PgAddress.empty() {
    return PgAddress(
      landmark: '',
      city: 'Unknown City',
      state: '',
      country: 'India',
      pincode: 0,
    );
  }

  @override
  String toString() {
    List<String> parts = [];
    if (landmark.isNotEmpty) parts.add(landmark);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    return parts.join(', ');
  }
}

class EnquiryData {
  final String enquiryId;
  final String status;
  final ContactPerson? owner;
  final ContactPerson? manager;

  EnquiryData({
    required this.enquiryId,
    required this.status,
    this.owner,
    this.manager,
  });

  factory EnquiryData.fromJson(Map<String, dynamic> json) {
    return EnquiryData(
      enquiryId: json['enquiryId'] ?? '',
      status: json['status'] ?? 'interested',
      owner: json['owner'] != null ? ContactPerson.fromJson(json['owner']) : null,
      manager: json['manager'] != null ? ContactPerson.fromJson(json['manager']) : null,
    );
  }
}

class ContactPerson {
  final String name;
  final String mobNo1;
  final String? mobNo2;

  ContactPerson({
    required this.name,
    required this.mobNo1,
    this.mobNo2,
  });

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      name: json['name'] ?? 'Contact Person',
      mobNo1: json['mobNo1'] ?? '',
      mobNo2: json['mobNo2'],
    );
  }
}
