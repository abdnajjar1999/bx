# دليل دمج ماسح الباركود

## إضافة زر الماسح في لوحة التحكم

### الطريقة 1: زر بسيط

```dart
ElevatedButton.icon(
  onPressed: () => Navigator.pushNamed(context, '/barcodescanner'),
  icon: const Icon(Icons.qr_code_scanner),
  label: const Text('ماسح الباركود'),
)
```

### الطريقة 2: بطاقة في لوحة التحكم

```dart
Card(
  child: InkWell(
    onTap: () => Navigator.pushNamed(context, '/barcodescanner'),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          const Text(
            'ماسح الباركود',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'امسح رقم الطلب',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  ),
)
```

### الطريقة 3: عنصر في القائمة الجانبية (Drawer)

```dart
ListTile(
  leading: const Icon(Icons.qr_code_scanner),
  title: const Text('ماسح الباركود'),
  subtitle: const Text('مسح وعرض تفاصيل الطلبات'),
  onTap: () {
    Navigator.pop(context); // إغلاق الـ Drawer
    Navigator.pushNamed(context, '/barcodescanner');
  },
)
```

### الطريقة 4: زر عائم (Floating Action Button)

```dart
FloatingActionButton.extended(
  onPressed: () => Navigator.pushNamed(context, '/barcodescanner'),
  icon: const Icon(Icons.qr_code_scanner),
  label: const Text('مسح'),
)
```

## مثال كامل: إضافة في Dashboard

```dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          // زر الماسح في AppBar
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'ماسح الباركود',
            onPressed: () => Navigator.pushNamed(context, '/barcodescanner'),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة الماسح
          _buildDashboardCard(
            context,
            icon: Icons.qr_code_scanner,
            title: 'ماسح الباركود',
            subtitle: 'مسح الطلبات',
            onTap: () => Navigator.pushNamed(context, '/barcodescanner'),
          ),
          // بطاقات أخرى...
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## ملاحظات مهمة

1. **المسار المستخدم**: `/barcodescanner` (تم إضافته في `main.dart`)

2. **الأذونات المطلوبة**: لا توجد أذونات خاصة مطلوبة لأن الماسح يعتمد على لوحة المفاتيح

3. **التوافق**: يعمل مع جميع ماسحات الباركود التي تعمل كلوحة مفاتيح (Keyboard Wedge)

4. **اختبار الماسح**: يمكنك اختبار الماسح بكتابة رقم الطلب يدوياً والضغط على Enter

## استكشاف الأخطاء

### المشكلة: لا يتم التعرف على الباركود
**الحل**: تأكد من أن:
- ماسح الباركود يعمل كلوحة مفاتيح
- رقم الطلب موجود في Firebase بالحقل `orderId`
- طول الباركود 6 أحرف على الأقل

### المشكلة: لا يتم عرض تفاصيل الطلب
**الحل**: تأكد من:
- وجود الطلب في collection `orders` في Firebase
- الحقل `orderId` يطابق الباركود الممسوح
- بيانات الطلب كاملة ومتوافقة مع نموذج `Shipment`

### المشكلة: خطأ في تحميل البيانات
**الحل**: تحقق من:
- اتصال الإنترنت
- إعدادات Firebase
- صلاحيات Firestore Rules
