class Expense {
  final String id;
  final String type;
  final String beneficiary;
  final String? partner;
  final String branch;
  final String notes;
  final double amount;
  final String userName;
  final DateTime creationDate;
  final DateTime modificationDate;
  final List<String>? attachments;

  Expense({
    required this.id,
    required this.type,
    required this.beneficiary,
    this.partner,
    required this.branch,
    required this.notes,
    required this.amount,
    required this.userName,
    required this.creationDate,
    required this.modificationDate,
    this.attachments,
  });

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      type: map['type'] ?? '',
      beneficiary: map['beneficiary'] ?? '',
      partner: map['partner'],
      branch: map['branch'] ?? '',
      notes: map['notes'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      userName: map['userName'] ?? '',
      creationDate: map['creationDate']?.toDate() ?? DateTime.now(),
      modificationDate: map['modificationDate']?.toDate() ?? DateTime.now(),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'beneficiary': beneficiary,
      'partner': partner,
      'branch': branch,
      'notes': notes,
      'amount': amount,
      'userName': userName,
      'creationDate': creationDate,
      'modificationDate': modificationDate,
      'attachments': attachments,
    };
  }
}

class ExpenseType {
  final String id;
  final String name;

  ExpenseType({
    required this.id,
    required this.name,
  });

  factory ExpenseType.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseType(
      id: id,
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
