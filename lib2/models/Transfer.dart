class Transfer {
  final String id;
  final String type;
  final String account;
  final double amount;
  final DateTime date;
  final String notes;

  Transfer({
    required this.id,
    required this.type,
    required this.account,
    required this.amount,
    required this.date,
    required this.notes,
  });

  factory Transfer.fromMap(Map<String, dynamic> map, String id) {
    return Transfer(
      id: id,
      type: map['type'] ?? '',
      account: map['account'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'account': account,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
} 