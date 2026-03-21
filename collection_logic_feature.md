# Collection Logic Feature — Implementation Guide

This document describes the **payment collection** feature for shipments. Use it to replicate the same logic in any app that uses the `Shipment` model.

---

## 1. Payment Methods (طرق الدفع)

```dart
final List<String> paymentMethods = ['COD', 'مدفوعة مسبقا', 'إحضار', 'تبديل'];
```

| Method | Arabic | Description |
|--------|--------|-------------|
| COD | الدفع عند الاستلام | Driver collects full amount (`codAmount`) from recipient |
| Prepaid | مدفوعة مسبقا | Recipient already paid the seller online. `codAmount = 0` |
| Pick-up | إحضار | Driver picks up a package/return, may collect or pay |
| Exchange | تبديل | Swapping products, settling the price difference |

---

## 2. New Fields on the `Shipment` Model

Add these three boolean fields:

```dart
// In Shipment class
final bool isDeliveryFeeOnRecipient; // default: true
final bool isCompanyDeliveryFeePaid; // default: false
final bool isPayToRecipient;         // default: false
```

### Field Descriptions

| Field | Default | Used In | Meaning |
|-------|---------|---------|---------|
| `isDeliveryFeeOnRecipient` | `true` | Prepaid | If `true`, the recipient pays the delivery fee upon receiving the package |
| `isCompanyDeliveryFeePaid` | `false` | Prepaid (when recipient does NOT pay delivery) | If `true`, seller paid delivery fee as cash to the branch. If `false`, delivery fee is deducted from seller's balance on past unclosed orders |
| `isPayToRecipient` | `false` | Exchange / Pick-up | If `true`, the driver **pays** the recipient. If `false`, the driver **collects** from the recipient |

### Serialization

```dart
// In fromMap:
isDeliveryFeeOnRecipient: map['isDeliveryFeeOnRecipient'] ?? true,
isCompanyDeliveryFeePaid: map['isCompanyDeliveryFeePaid'] ?? false,
isPayToRecipient: map['isPayToRecipient'] ?? false,

// In toMap:
'isDeliveryFeeOnRecipient': isDeliveryFeeOnRecipient,
'isCompanyDeliveryFeePaid': isCompanyDeliveryFeePaid,
'isPayToRecipient': isPayToRecipient,
```

---

## 3. Calculated Properties

### `driverCollection` — What the driver collects from the recipient

```dart
double get driverCollection {
  if (status == 'تم إرجاعها') return 0.0;

  if (paymentMethod == 'مدفوعة مسبقا') {
    // Prepaid: driver only collects delivery fee if recipient is paying it
    if (isDeliveryFeeOnRecipient && !isCompanyDeliveryFeePaid) {
      return deliveryCost;
    }
    return 0.0;
  } else if (paymentMethod == 'COD') {
    return codAmount;
  } else if (paymentMethod == 'تبديل' || paymentMethod == 'إحضار') {
    if (!isPayToRecipient) {
      return codAmount; // collecting from recipient
    }
    return 0.0;
  }
  return 0.0;
}
```

### `payableToCustomer` — What is owed to the seller (customer/shipper)

```dart
double get payableToCustomer {
  if (status == 'تم إرجاعها') return -deliveryCost;

  if (paymentMethod == 'مدفوعة مسبقا') {
    // If recipient is NOT paying delivery, and seller chose balance deduction
    if (!isDeliveryFeeOnRecipient && !isCompanyDeliveryFeePaid) {
      return -deliveryCost; // deduct from seller balance
    }
    return 0.0;
  } else if (paymentMethod == 'COD') {
    return codAmount - deliveryCost;
  } else if (paymentMethod == 'تبديل' || paymentMethod == 'إحضار') {
    if (isPayToRecipient) {
      return -codAmount - deliveryCost; // paying recipient + delivery cost
    } else {
      return codAmount - deliveryCost; // collecting from recipient
    }
  }
  return 0.0;
}
```

---

## 4. UI Logic — Add Order Form

### 4.1 State Variables

```dart
bool isDeliveryFeeOnRecipient = true;
bool isCompanyDeliveryFeePaid = false;
bool isPayToRecipient = false;
bool hasUnclosedOrders = false; // queried from DB
String selectedPaymentMethod = 'COD'; // default
```

### 4.2 Payment Section Visibility Rules

| UI Element | COD | Prepaid | Exchange / Pick-up |
|------------|-----|---------|---------------------|
| سعر التوصيل (Delivery Cost field) | ✅ Show | ✅ Show | ✅ Show |
| التحصيل شامل التوصيل (COD Amount field) | ✅ Show (in main row) | ❌ Hidden, value = `0` | ❌ Hidden from main row, shown inside Exchange/Pick-up section |
| Prepaid options section | ❌ | ✅ Show | ❌ |
| Exchange/Pick-up options section | ❌ | ❌ | ✅ Show |

### 4.3 When Prepaid is Selected

Show a **switch**: "المستلم سيدفع سعر التوصيل" → controls `isDeliveryFeeOnRecipient`

If the switch is **OFF** (recipient not paying delivery):
- Show **radio buttons**:
  - "دفع من رصيد البائع" → `isCompanyDeliveryFeePaid = false`
    - **Only enabled** if the seller has unclosed past orders (query Firestore)
  - "دفع كاش" → `isCompanyDeliveryFeePaid = true`

### 4.4 When Exchange or Pick-up is Selected

Show:
- A **text field** for the amount (`codAmountController`)
  - Label: "قيمة الفرق/الاستبدال" for Exchange, "المبلغ المطلوب" for Pick-up
- **Radio buttons** next to the text field:
  - "تحصيل من المستلم" → `isPayToRecipient = false`
  - "الدفع للمستلم" → `isPayToRecipient = true`

### 4.5 On Payment Method Change

```dart
onChanged: (value) {
  setState(() {
    selectedPaymentMethod = value!;
    if (selectedPaymentMethod == 'مدفوعة مسبقا') {
      isDeliveryFeeOnRecipient = true;
      isCompanyDeliveryFeePaid = false;
      codAmountController.text = '0';
    } else if (selectedPaymentMethod == 'تبديل' || selectedPaymentMethod == 'إحضار') {
      isPayToRecipient = false;
    }
  });
},
```

---

## 5. Checking Unclosed Orders (for "Deduct from Seller Balance")

Query Firestore for orders belonging to this seller that have NOT been fully settled:

```dart
Future<void> _checkUnclosedOrders(String customerId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: customerId)
      .where('cashPossession', isNotEqualTo: 'customer')
      .limit(1)
      .get();

  setState(() {
    hasUnclosedOrders = snapshot.docs.isNotEmpty;
  });
}
```

Call this whenever the selected customer changes.

---

## 6. Summary Table — All Cases

| Case | `codAmount` | `isDeliveryFeeOnRecipient` | `isCompanyDeliveryFeePaid` | `isPayToRecipient` | `driverCollection` | `payableToCustomer` |
|------|-------------|---------------------------|--------------------------|--------------------|--------------------|---------------------|
| COD | User input | N/A | N/A | N/A | `codAmount` | `codAmount - deliveryCost` |
| Prepaid (recipient pays delivery) | 0 | `true` | `false` | N/A | `deliveryCost` | `0` |
| Prepaid (seller pays from balance) | 0 | `false` | `false` | N/A | `0` | `-deliveryCost` |
| Prepaid (seller pays cash) | 0 | `false` | `true` | N/A | `0` | `0` |
| Exchange/Pick-up (collect from recipient) | User input | N/A | N/A | `false` | `codAmount` | `codAmount - deliveryCost` |
| Exchange/Pick-up (pay to recipient) | User input | N/A | N/A | `true` | `0` | `-codAmount - deliveryCost` |
| Returned (any method) | — | — | — | — | `0` | `-deliveryCost` |

---

## 7. Passing to Shipment Object in `_handleSubmit`

```dart
final shipment = Shipment(
  // ... other fields ...
  isDeliveryFeeOnRecipient: isDeliveryFeeOnRecipient,
  isCompanyDeliveryFeePaid: isCompanyDeliveryFeePaid,
  isPayToRecipient: isPayToRecipient,
);
```

---

## 8. Resetting State on "Save & Continue"

```dart
isDeliveryFeeOnRecipient = true;
isCompanyDeliveryFeePaid = false;
isPayToRecipient = false;
```
