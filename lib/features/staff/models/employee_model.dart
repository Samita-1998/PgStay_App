class EmployeeModel {
  final String id;
  final EmployeeUser user;
  final String status;
  final double monthlySalary;
  final DateTime? joinedDate;
  final List<EmployeePg> assignedPgs;
  final Map<String, dynamic> pgSalaries;
  final String? notes;
  
  EmployeeModel({
    required this.id,
    required this.user,
    required this.status,
    required this.monthlySalary,
    required this.joinedDate,
    required this.assignedPgs,
    required this.pgSalaries,
    this.notes,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['_id'] ?? '',
      user: EmployeeUser.fromJson(json['userId'] ?? {}),
      status: json['status'] ?? 'active',
      monthlySalary: (json['monthlySalary'] ?? 0).toDouble(),
      joinedDate: json['joinedDate'] != null ? DateTime.tryParse(json['joinedDate']) : null,
      assignedPgs: (json['pgIds'] as List<dynamic>?)
              ?.map((e) => EmployeePg.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pgSalaries: json['pgSalaries'] as Map<String, dynamic>? ?? {},
      notes: json['notes'],
    );
  }
}

class EmployeeUser {
  final String id;
  final String name;
  final String role;
  final String email;
  final String? mobNo1;
  final String? picture;
  final String? gender;

  EmployeeUser({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.mobNo1,
    this.picture,
    this.gender,
  });

  factory EmployeeUser.fromJson(Map<String, dynamic> json) {
    return EmployeeUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'staff',
      email: json['email'] ?? '',
      mobNo1: json['mobNo1'],
      picture: json['picture'],
      gender: json['gender'],
    );
  }
}

class EmployeePg {
  final String id;
  final String name;

  EmployeePg({
    required this.id,
    required this.name,
  });

  factory EmployeePg.fromJson(Map<String, dynamic> json) {
    return EmployeePg(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown PG',
    );
  }
}
