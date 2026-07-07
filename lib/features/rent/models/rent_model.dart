class RentModel {
  final String id;
  final String pgId;
  final String userId;
  final String month;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status;
  final double paidAmount;
  final String? paymentMethod;
  final String? receiptNo;
  final String? staffRemarks;
  final double penaltyAmount;

  // Populated fields (if populated in backend)
  final String? userName;
  final String? pgName;
  final String? bedNumber;
  final String? roomNumber;
  final String? userPhone;
  final String? userEmail;

  RentModel({
    required this.id,
    required this.pgId,
    required this.userId,
    required this.month,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.paidAmount = 0.0,
    this.paymentMethod,
    this.receiptNo,
    this.staffRemarks,
    this.penaltyAmount = 0.0,
    this.userName,
    this.pgName,
    this.bedNumber,
    this.roomNumber,
    this.userPhone,
    this.userEmail,
  });

  factory RentModel.fromJson(Map<String, dynamic> json) {
    // Generate a fallback due date from rentMonth (e.g. "2026-06" -> "2026-06-05")
    DateTime parsedDueDate = DateTime.now();
    if (json['dueDate'] != null) {
      parsedDueDate = DateTime.parse(json['dueDate']);
    } else if (json['rentMonth'] != null && json['rentMonth'].toString().length == 7) {
      parsedDueDate = DateTime.parse('${json['rentMonth']}-05T00:00:00Z');
    } else if (json['createdAt'] != null) {
      parsedDueDate = DateTime.parse(json['createdAt']);
    }

    return RentModel(
      id: json['_id'] ?? '',
      pgId: json['pgId'] is Map ? json['pgId']['_id'] : (json['pgId'] ?? ''),
      pgName: json['pgId'] is Map ? json['pgId']['name'] : null,
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      userName: json['userId'] is Map ? json['userId']['name'] : null,
      bedNumber: json['bedId'] is Map ? json['bedId']['bedNumber'] : null,
      roomNumber: json['roomId'] is Map ? json['roomId']['roomNumber'] : null,
      month: json['rentMonth'] ?? json['month'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: parsedDueDate,
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      status: json['status'] ?? 'pending',
      paidAmount: (json['amountPaid'] ?? json['paidAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMode'] ?? json['paymentMethod'],
      receiptNo: json['referenceNo'] ?? json['receiptNo'],
      staffRemarks: json['notes'] ?? json['staffRemarks'],
      penaltyAmount: (json['penaltyAmount'] ?? 0).toDouble(),
      userPhone: json['userId'] is Map ? (json['userId']['phone'] ?? json['userId']['mobile']) : null,
      userEmail: json['userId'] is Map ? json['userId']['email'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'pgId': pgId,
      'userId': userId,
      'rentMonth': month,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'amountPaid': paidAmount,
      'paymentMode': paymentMethod,
      'referenceNo': receiptNo,
      'notes': staffRemarks,
      'penaltyAmount': penaltyAmount,
    };
  }
}
