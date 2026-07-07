class ExpenseModel {
  final String id;
  final ExpenseUser spentBy;
  final ExpenseUser submittedBy;
  final ExpensePg pgId;
  final double amount;
  final String description;
  final String category;
  final DateTime spentDate;
  final String status;
  final ExpenseUser? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? reimbursementType;
  final String payoutStatus;
  final DateTime? reimbursedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.spentBy,
    required this.submittedBy,
    required this.pgId,
    required this.amount,
    required this.description,
    required this.category,
    required this.spentDate,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.reimbursementType,
    required this.payoutStatus,
    this.reimbursedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? '',
      spentBy: json['spentBy'] is Map<String, dynamic> ? ExpenseUser.fromJson(json['spentBy']) : ExpenseUser(id: json['spentBy']?.toString() ?? '', name: 'Unknown', role: ''),
      submittedBy: json['submittedBy'] is Map<String, dynamic> ? ExpenseUser.fromJson(json['submittedBy']) : ExpenseUser(id: json['submittedBy']?.toString() ?? '', name: 'Unknown', role: ''),
      pgId: json['pgId'] is Map<String, dynamic> ? ExpensePg.fromJson(json['pgId']) : ExpensePg(id: json['pgId']?.toString() ?? '', name: 'Unknown PG'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      spentDate: DateTime.parse(json['spentDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      approvedBy: json['approvedBy'] == null 
          ? null 
          : (json['approvedBy'] is Map<String, dynamic> 
              ? ExpenseUser.fromJson(json['approvedBy']) 
              : ExpenseUser(id: json['approvedBy'].toString(), name: 'Unknown', role: '')),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectionReason: json['rejectionReason'],
      reimbursementType: json['reimbursementType'],
      payoutStatus: json['payoutStatus'] ?? 'unpaid',
      reimbursedDate: json['reimbursedDate'] != null ? DateTime.parse(json['reimbursedDate']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ExpenseUser {
  final String id;
  final String name;
  final String role;
  final String? email;
  final String? picture;

  ExpenseUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.picture,
  });

  factory ExpenseUser.fromJson(Map<String, dynamic> json) {
    return ExpenseUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? '',
      email: json['email'],
      picture: json['picture'],
    );
  }
}

class ExpensePg {
  final String id;
  final String name;

  ExpensePg({
    required this.id,
    required this.name,
  });

  factory ExpensePg.fromJson(Map<String, dynamic> json) {
    return ExpensePg(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown PG',
    );
  }
}
