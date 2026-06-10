class BookingModel {
  final String id;
  final String pgId;
  final String pgName;
  final String userId;
  final String roomId;
  final String roomType;
  final DateTime checkInDate;
  final int durationMonths;
  final double totalAmount;
  final double amountPaid;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'

  BookingModel({
    required this.id,
    required this.pgId,
    required this.pgName,
    required this.userId,
    required this.roomId,
    required this.roomType,
    required this.checkInDate,
    required this.durationMonths,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      pgId: json['pgId'] ?? '',
      pgName: json['pgName'] ?? 'Unknown PG',
      userId: json['userId'] ?? '',
      roomId: json['roomId'] ?? '',
      roomType: json['roomType'] ?? '',
      checkInDate: json['checkInDate'] != null
          ? DateTime.parse(json['checkInDate'])
          : DateTime.now(),
      durationMonths: json['durationMonths'] ?? 1,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pgId': pgId,
      'pgName': pgName,
      'userId': userId,
      'roomId': roomId,
      'roomType': roomType,
      'checkInDate': checkInDate.toIso8601String(),
      'durationMonths': durationMonths,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'status': status,
    };
  }
}
