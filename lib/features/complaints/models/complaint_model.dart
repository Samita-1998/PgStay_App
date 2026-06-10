class ComplaintModel {
  final String id;
  final String pgId;
  final String userId;
  final String userName;
  final String category; // 'Maintenance', 'Cleaning', 'Food', 'Other'
  final String description;
  final String status; // 'Open', 'In Progress', 'Resolved'
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.pgId,
    required this.userId,
    required this.userName,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      pgId: json['pgId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      category: json['category'] ?? 'Other',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Open',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pgId': pgId,
      'userId': userId,
      'userName': userName,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
