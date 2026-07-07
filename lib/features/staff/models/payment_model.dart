class PaymentModel {
  final String id;
  final String employeeId; // We map this to string ID for grouping
  final PaymentUser user;
  final List<String> employeePgIds;
  final String pgId;
  final String pgName;
  final String month;
  final double salaryAmount;
  final double reimbursedExpenses;
  final double totalAmount;
  final String status;
  final DateTime? paidDate;

  PaymentModel({
    required this.id,
    required this.employeeId,
    required this.user,
    required this.employeePgIds,
    required this.pgId,
    required this.pgName,
    required this.month,
    required this.salaryAmount,
    required this.reimbursedExpenses,
    required this.totalAmount,
    required this.status,
    this.paidDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final empObj = json['employeeId'] ?? {};
    final userObj = empObj['userId'] ?? {};
    final pgObj = json['pgId'] ?? {};

    return PaymentModel(
      id: json['_id'] ?? '',
      employeeId: empObj['_id'] ?? '',
      user: PaymentUser.fromJson(userObj),
      employeePgIds: (empObj['pgIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      pgId: pgObj['_id'] ?? '',
      pgName: pgObj['name'] ?? 'Unknown PG',
      month: json['month'] ?? '',
      salaryAmount: (json['salaryAmount'] as num?)?.toDouble() ?? 0.0,
      reimbursedExpenses: (json['reimbursedExpenses'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate']) : null,
    );
  }
}

class PaymentUser {
  final String id;
  final String name;
  final String role;
  final String? email;
  final String? picture;

  PaymentUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.picture,
  });

  factory PaymentUser.fromJson(Map<String, dynamic> json) {
    return PaymentUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? '',
      email: json['email'],
      picture: json['picture'],
    );
  }
}
