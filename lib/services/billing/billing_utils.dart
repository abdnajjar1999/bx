String getInvoiceType(String invoiceType, String paymentType) {
  if (invoiceType.contains("GENERAL")) {
    if (paymentType == 'cash') {
      return 'CASH_GENERAL_TAX';
    } else {
      return 'RECEIVABLE_GENERAL_TAX';
    }
  } else if (invoiceType.contains("SPECIAL")) {
    if (paymentType == 'cash') {
      return 'CASH_SPECIAL_TAX';
    } else {
      return 'RECEIVABLE_SPECIAL_TAX';
    }
  } else if (invoiceType.contains("INCOME")) {
    if (paymentType == 'cash') {
      return 'CASH_INCOME';
    } else {
      return 'RECEIVABLE_INCOME';
    }
  }
  return 'CASH_GENERAL_TAX';
}

double getTaxPercentage(String taxType) {
  switch (taxType) {
    case 'EXEMPT':
      return 0.0;
    case 'ZERO':
      return 0.0;
    case 'ONE':
      return 1.0;
    case 'TWO':
      return 2.0;
    case 'THREE':
      return 3.0;
    case 'THREE_HALF':
      return 3.5;
    case 'FOUR':
      return 4.0;
    case 'FIVE':
      return 5.0;
    case 'SIX':
      return 6.0;
    case 'SEVEN':
      return 7.0;
    case 'EIGHT':
      return 8.0;
    case 'TEN':
      return 10.0;
    case 'SIXTEEN':
      return 16.0;
    default:
      return 16.0;
  }
}

String getProvinceCode(String city) {
  final cityLower = city.toLowerCase();

  if (cityLower.contains('عمان') || cityLower.contains('amman')) return 'JO-AM';
  if (cityLower.contains('البلقاء') || cityLower.contains('balqa'))
    return 'JO-BA';
  if (cityLower.contains('معان') ||
      cityLower.contains('ma\'an') ||
      cityLower.contains('maan')) return 'JO-MN';
  if (cityLower.contains('مادبا') || cityLower.contains('madaba'))
    return 'JO-MD';
  if (cityLower.contains('المفرق') || cityLower.contains('mafraq'))
    return 'JO-MA';
  if (cityLower.contains('الكرك') || cityLower.contains('karak'))
    return 'JO-KA';
  if (cityLower.contains('جرش') || cityLower.contains('jerash')) return 'JO-JA';
  if (cityLower.contains('إربد') || cityLower.contains('irbid')) return 'JO-IR';
  if (cityLower.contains('الزرقاء') || cityLower.contains('zarqa'))
    return 'JO-AZ';
  if (cityLower.contains('الطفيلة') || cityLower.contains('tafilah'))
    return 'JO-AT';
  if (cityLower.contains('العقبة') || cityLower.contains('aqaba'))
    return 'JO-AQ';
  if (cityLower.contains('عجلون') || cityLower.contains('ajloun'))
    return 'JO-AJ';

  return 'JO-AM'; // Default to Amman
}
