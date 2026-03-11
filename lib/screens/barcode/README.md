# ماسح الباركود - Barcode Scanner

## الوصف
هذه الميزة تسمح بمسح رقم الطلب باستخدام ماسح الباركود وعرض تفاصيل الطلب تلقائياً باستخدام شاشة `ShipmentDetails`.

## الملفات
- `barcode_scanner_screen.dart` - شاشة ماسح الباركود مع تكامل Firebase و ShipmentDetails

## كيفية الاستخدام

### 1. الانتقال إلى شاشة الماسح
يمكنك الانتقال إلى شاشة الماسح باستخدام:

```dart
Navigator.pushNamed(context, '/barcodescanner');
```

أو:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const BarcodeScannerScreen(),
  ),
);
```

### 2. مسح الباركود
- استخدم ماسح الباركود لمسح رقم الطلب
- سيتم التعرف تلقائياً على الباركود عند المسح السريع
- يمكنك أيضاً كتابة رقم الطلب يدوياً والضغط على Enter

### 3. عرض تفاصيل الطلب
بعد المسح، سيتم:
- تحميل بيانات الطلب من Firebase Firestore
- عرض شاشة `ShipmentDetails` في نافذة جانبية (Side Drawer)
- عرض جميع تفاصيل الشحنة الكاملة مع:
  - معلومات الطرد الأساسية
  - معلومات إضافية
  - معلومات الخدمة
  - معلومات المرسل والمستلم
  - الحركات وتتبع الحالات
  - الباركود الخاص بالطلب

## هيكل البيانات في Firebase

يجب أن يكون لديك مجموعة (collection) باسم `orders` في Firestore تحتوي على المستندات التالية:

```json
{
  "orderNumber": "123456789",
  "status": "pending",
  "date": Timestamp,
  "customerName": "اسم العميل",
  "phoneNumber": "0501234567",
  "address": "العنوان الكامل",
  "totalAmount": 150.00,
  "notes": "ملاحظات إضافية"
}
```

### حالات الطلب المتاحة:
- `pending` - قيد الانتظار
- `processing` - قيد المعالجة
- `shipped` - تم الشحن
- `delivered` - تم التوصيل
- `cancelled` - ملغي

## إضافة زر في لوحة التحكم

يمكنك إضافة زر في لوحة التحكم للوصول إلى الماسح:

```dart
ElevatedButton.icon(
  onPressed: () => Navigator.pushNamed(context, '/barcodescanner'),
  icon: const Icon(Icons.qr_code_scanner),
  label: const Text('ماسح الباركود'),
)
```

## المكتبات المستخدمة
- `visibility_detector` - للتحقق من ظهور الشاشة
- `cloud_firestore` - لجلب بيانات الطلبات من Firebase

## ملاحظات
- يتم التعرف على الباركود بناءً على سرعة الكتابة (أقل من 35ms بين الأحرف)
- الحد الأدنى لطول الباركود هو 6 أحرف
- يمكن تعديل هذه الإعدادات في class `BarcodeScanDetector`
