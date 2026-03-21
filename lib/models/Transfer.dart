enum AccountCategory {
  customerCurrent('جاري العملاء'),
  expenses('المصروفات'),
  revenues('ايرادات'),
  cashAccounts('النقديه'),
  other('أخرى');

  final String label;
  const AccountCategory(this.label);

  static AccountCategory fromString(String label) {
    return AccountCategory.values.firstWhere(
      (e) => e.label == label,
      orElse: () => AccountCategory.other,
    );
  }
}

class Transfer {
  final String id;
  final String type;
  final String account;
  final String otherAccount;
  final AccountCategory? otherAccountCategory;
  final double amount;
  final DateTime date;
  final String notes;
  final String? relatedTo;

  Transfer({
    required this.id,
    required this.type,
    required this.account,
    this.otherAccount = '',
    this.otherAccountCategory,
    required this.amount,
    required this.date,
    required this.notes,
    this.relatedTo,
  });

  factory Transfer.fromMap(Map<String, dynamic> map, String id) {
    return Transfer(
      id: id,
      type: map['type'] ?? '',
      account: map['account'] ?? '',
      otherAccount: map['otherAccount'] ?? '',
      otherAccountCategory: map['otherAccountCategory'] != null 
          ? AccountCategory.fromString(map['otherAccountCategory']) 
          : null,
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'] ?? '',
      relatedTo: map['relatedTo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'account': account,
      'otherAccount': otherAccount,
      if (otherAccountCategory != null) 'otherAccountCategory': otherAccountCategory!.label,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      if (relatedTo != null) 'relatedTo': relatedTo,
    };
  }

  /// إيداع: account = "إلى حساب", otherAccount = "من حساب"
  /// سحب: account = "من حساب", otherAccount = "إلى حساب"
  String get fromAccountDisplay =>
      type == 'إيداع' ? otherAccount : account;

  String get toAccountDisplay =>
      type == 'إيداع' ? account : otherAccount;
}