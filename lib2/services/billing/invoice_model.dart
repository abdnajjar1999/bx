class InvoiceItem {
  String? invoiceItemType;
  String? productDescription;
  double? quantity;
  double? unitPrice;
  double? customerPrice;
  double? subtotalAmount;
  double? discountAmount;
  double? totalAmountAfterDiscount;
  double? generalTaxAmount;
  double? totalAmountAfterTaxes;
  double? specialTaxAmount;
  String? uuid;
  String? isic4;
  double? generalTaxPercentage;
  String? generalTaxType;
  int? id;
  String? description;
  String? isic4Code;

  InvoiceItem({
    this.invoiceItemType = 'PRODUCT',
    this.productDescription = '',
    this.quantity = 0,
    this.unitPrice = 0,
    this.customerPrice = 0,
    this.subtotalAmount = 0,
    this.discountAmount = 0,
    this.totalAmountAfterDiscount = 0,
    this.generalTaxAmount = 0,
    this.totalAmountAfterTaxes = 0,
    this.specialTaxAmount = 0,
    this.uuid,
    this.isic4 = '',
    this.generalTaxPercentage = 16,
    this.generalTaxType = 'SIXTEEN',
    this.id,
    this.description,
    this.isic4Code,
  }) {
    // Map description to productDescription for compatibility
    description ??= productDescription;
    productDescription ??= description;
    isic4Code ??= isic4;
    isic4 ??= isic4Code;
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceItemType': invoiceItemType,
      'productDescription': productDescription,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'customerPrice': customerPrice,
      'subtotalAmount': subtotalAmount,
      'discountAmount': discountAmount,
      'totalAmountAfterDiscount': totalAmountAfterDiscount,
      'generalTaxAmount': generalTaxAmount,
      'totalAmountAfterTaxes': totalAmountAfterTaxes,
      'specialTaxAmount': specialTaxAmount,
      'uuid': uuid,
      'isic4': isic4,
      'generalTaxPercentage': generalTaxPercentage,
      'generalTaxType': generalTaxType,
      'id': id,
      'description': description,
      'isic4Code': isic4Code,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      invoiceItemType: json['invoiceItemType'] ?? 'PRODUCT',
      productDescription: json['productDescription'] ?? '',
      quantity: json['quantity']?.toDouble() ?? 0,
      unitPrice: json['unitPrice']?.toDouble() ?? 0,
      customerPrice: json['customerPrice']?.toDouble() ?? 0,
      subtotalAmount: json['subtotalAmount']?.toDouble() ?? 0,
      discountAmount: json['discountAmount']?.toDouble() ?? 0,
      totalAmountAfterDiscount:
          json['totalAmountAfterDiscount']?.toDouble() ?? 0,
      generalTaxAmount: json['generalTaxAmount']?.toDouble() ?? 0,
      totalAmountAfterTaxes: json['totalAmountAfterTaxes']?.toDouble() ?? 0,
      specialTaxAmount: json['specialTaxAmount']?.toDouble() ?? 0,
      uuid: json['uuid'],
      isic4: json['isic4'] ?? '',
      generalTaxPercentage: json['generalTaxPercentage']?.toDouble() ?? 16,
      generalTaxType: json['generalTaxType'] ?? 'SIXTEEN',
      id: json['id'],
      description: json['description'],
      isic4Code: json['isic4Code'],
    );
  }

  double get total => totalAmountAfterTaxes ?? 0;
}

class Buyer {
  String? name;
  String? phoneNumber;
  String? postalCode;
  String? additionalBuyerId;
  String? additionalBuyerIdType;
  String? province;

  Buyer({
    this.name = '',
    this.phoneNumber = '',
    this.postalCode = '',
    this.additionalBuyerId = '',
    this.additionalBuyerIdType = 'NATIONAL_ID_NUMBER',
    this.province = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'postalCode': postalCode,
      'additionalBuyerId': additionalBuyerId,
      'additionalBuyerIdType': additionalBuyerIdType,
      'province': province,
    };
  }

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      postalCode: json['postalCode'] ?? '',
      additionalBuyerId: json['additionalBuyerId'] ?? '',
      additionalBuyerIdType:
          json['additionalBuyerIdType'] ?? 'NATIONAL_ID_NUMBER',
      province: json['province'] ?? '',
    );
  }
}

class Invoice {
  Buyer? buyer;
  String? buyerInvoiceNumber;
  List<InvoiceItem>? items;
  String? notes;
  DateTime? date;
  bool? isUploaded;
  int? id;
  String? paymentType;

  Invoice({
    this.buyer,
    this.buyerInvoiceNumber = '',
    this.items,
    this.notes = '',
    this.date,
    this.isUploaded = false,
    this.id,
    this.paymentType,
  }) {
    buyer ??= Buyer();
    items ??= [];
    date ??= DateTime.now();
  }

  double get subtotal {
    return (items ?? []).fold(0, (sum, item) => sum + item.total);
  }

  double get taxTotal {
    return (items ?? []).fold(0, (sum, item) {
      if (item.generalTaxPercentage == 16) {
        return sum + (item.total * 0.16);
      }
      return sum;
    });
  }

  double get grandTotal {
    return subtotal + taxTotal;
  }

  Map<String, dynamic> toJson() {
    return {
      'buyer': buyer?.toJson(),
      'buyerInvoiceNumber': buyerInvoiceNumber,
      'items': items?.map((item) => item.toJson()).toList(),
      'notes': notes,
      'date': date?.toIso8601String(),
      'isUploaded': isUploaded,
      'id': id,
      'paymentType': paymentType,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      buyer: json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null,
      buyerInvoiceNumber: json['buyerInvoiceNumber'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => InvoiceItem.fromJson(item))
              .toList()
          : null,
      notes: json['notes'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      isUploaded: json['isUploaded'] ?? false,
      id: json['id'],
      paymentType: json['paymentType'],
    );
  }

  @override
  String toString() {
    return 'Invoice(buyer: ${buyer?.toJson()}, buyerInvoiceNumber: $buyerInvoiceNumber, items: ${items?.map((item) => item.toJson()).toList()}, notes: $notes, date: $date)';
  }
}
