import 'dart:ui';

import 'package:good_line_delivery/models/Shipment.dart';
import 'package:flutter/material.dart';
// configs

List list_btn = [
  'مسار السائق التلقائي',
  'طباعة التقرير',
  'طباعة سند القبض',
  'تحديد مسار السائق'
];

final Map<String, Color> statusOptions = {
  "الطلبات الجديدة": const Color(0xFFB772B8), // rgb(183, 114, 184)
  "بانتظار تعيين السائق": const Color(0xFFFAD16A), // rgb(250, 209, 106)
  "في الفرع": const Color(0xFFFF914D), // rgb(255, 145, 77)
  "بانتظار موافقة السائق": const Color(0xFFCCCCCC), // rgb(204, 204, 204)
  "ملغاة": const Color(0xFFF24645), // rgb(242, 70, 69)
  "رفضها السائق": const Color(0xFFEC7063), // rgb(236, 112, 99)
  "بانتظار التحميل": const Color(0xFF6A9CFA), // rgb(106, 156, 250)
  "في المركبة": const Color(0xFF00E2FF), // rgb(0, 226, 255)
  "على الرفوف": const Color(0xFF913463), // rgb(145, 52, 99)
  "بانتظار مراجعة الإدارة": const Color(0xFFA10500), // rgb(161, 5, 0)
  "تم إرجاعها": const Color(0xFFCC7C68), // rgb(204, 124, 104)
  "مؤجلة لوقت آخر": const Color(0xFF5EB4FF), // rgb(94, 180, 255)
  "تم توصيلها": const Color(0xFF2ED47A), // rgb(46, 212, 122)
  "مصدرة إلى شريك": const Color(0xFFB3404A), // rgb(179, 64, 74)
  "مسودة": const Color(0xFF59788E), // rgb(89, 120, 142)
  "تالفة": const Color(0xFFF08080), // rgb(240, 128, 128)
  "تم توصيلها بشكل جزئي": const Color(0xFF35393b), // rgb(204, 204, 204)
};

// Helper function to get color for a status
Color getStatusColor(String status) {
  return statusOptions[status] ?? Colors.grey; // Returns grey as fallback color
}

final List<String> paymentMethods = ['تبديل', 'COD', 'مدفوعة مسبقا', 'إحضار'];
final List<String> collectionMethods = [
  'كاش',
  'تحويل بنكي',
  'شك',
  'دفع مسبق',
  'محفظة الكترونية',
  'بطاقة الائتمان',
];
List<String> serviceTypes = ['اعتيادي', 'سريع', 'ثلاث الى خمس ايام'];

final List<String> dates = [
  "تاريخ الحجز",
  "تاريخ التوصيل",
  "تاريخ أول تحميل",
  "تاريخ الارجاع",
  "تاريخ التأجيل",
  "تاريخ اخر حالة",
  "تاريخ التعديل",
  "تاريخ تعيين الشحنة للسائق",
];
final List<String> jordanianCities = [
  'u',
  'الزرقاء',
  'إربد',
  'العقبة',
  'السلط',
  'مأدبا',
  'جرش',
  'عجلون',
  'الكرك',
  'المفرق',
  'الطفيلة',
  'معان',
  'الرمثا',
  'الرصيفة',
  'البلقاء',
];

final List<DataColumn> tableColumns = [
  DataColumn(label: SizedBox(width: 0, height: 0)),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "رقم الطرد",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "الوزن",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "السعر",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "COD",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "الزبون",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "السائق",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "هاتف المستقبل",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "المرسل",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "المستقبل",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "الحالة",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "الإرسالية",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "طريقة الدفع",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "طريقة التحصيل",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "تاريخ الحجز",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "تاريخ التوصيل",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "تاريخ التوصيل المتوقع",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "تاريخ اخر حالة",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "تاريخ التأجيل",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
  DataColumn(
    label: Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        "ملاحظات",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ),
];
List<DataCell> tableRows = [
  DataCell(Text('789012')),
  DataCell(Text('1.8')),
  DataCell(Text('35')),
  DataCell(Text('75 JOD')),
  DataCell(Text('سارة')),
  DataCell(Text('0777654321')),
  DataCell(Text('فاطمة')),
  DataCell(Text('خالد\nاربد')),
  DataCell(
    Text(
      'تم توصيلها',
    ),
  ),
  DataCell(Text('TR789012')),
  DataCell(Text('مدفوع مسبقا')),
  DataCell(Text('بطاقة ائتمانية')),
  DataCell(Text('2024-03-10')),
  DataCell(Text('2024-03-11')),
  DataCell(Text('2024-03-11')),
  DataCell(Text('2024-03-11')),
  DataCell(Text('')),
  DataCell(Text('يرجى الاتصال قبل التوصيل')),
];

List<String> roles = [
  'مدير النظام',
  'سائق',
  'العناية بالزبائن',
  'موظف الاستلام',
  'مدير فرع',
  'مدير عدة فروع',
  'مسؤول الحركة',
  'أمين الصندوق',
];
List<String> permissions = [
  "تغير السعر",
  "تغير الحاله",
  "حذف الطرود",
];

const List<String> drawerTitles = [
  'الملخص', // Index 0
  'إدارة الطرود', // Index 1
  'المتابعات', // Index 2
  'إدارة المركبات', // Index 3
  'إدارة السائقين', // Index 4
  'إدارة الزبائن', // Index 5
  'استلام التحصيلات', // Index 6
  'التحصيلات المفرزة', // Index 7
  'التحصيلات المصدرة', // Index 8
  'التحصيلات المسلمه', // Index 9
  'حاسبة الاسعار', // Index 10
  'ملخص مالي', // Index 11
  'المصروفات', // Index 12
  'الملفات', // Index 13
  'واتساب', // Index 14
  'اداره المناطق', // Index 15
  'الطلبات المرتجعة المسلمة', // Index 16
  'الطلبات المرتجعة في الفرع', // Index 17
  'الحسابات', // Index 18
  'سندات الاستلام', // Index 19
  'إدارة المخزون', // Index 20
  'حاسبة الاسعار السائق', // Index 21
  'إدارة الرفوف', // Index 22
  'إحصائيات الذكاء الاصطناعي', // Index 23
  'إدارة الحزم المجمعة', // Index 24
  'فوتره الوطنيه', // Index 25
  'طلبات التوريد', // Index 26
  'إدارة الجولات', // Index 27
  'إدارة جولات الجلب', // Index 28
  'اداره الموظفين', // Index 29
  "ضبط استيراد الاكسل", // Index 30
  'أنواع الطرود', // Index 31
  'شاشة استلام الطرود', // Index 32
  'الرواجع', // Index 33
  'رواجع التبديل', // Index 34
  'رواجع التوصيل الجزئي', // Index 35
  'طرود الاحضار', // Index 36
  'مع السائق', // Index 37
  'مسلمة إلى المرسل', // Index 38
];

List<String>? userPermissions;
OrderPossession orderPossessionFallback(
    String status, String? orderPossession) {
  OrderPossession orderPossessionValue = OrderPossession.values.firstWhere(
    (e) => e.toString().split('.').last == (orderPossession ?? 'branch'),
    orElse: () => OrderPossession.branch,
  );
  switch (status) {
    case 'تم توصيلها':
      return OrderPossession.receiver;
    case 'تم إرجاعها':
      return orderPossessionValue;
    case 'في الفرع':
      return OrderPossession.branch;
    case 'بانتظار موافقة السائق':
      return OrderPossession.driverShipping;
    case 'في المركبة':
      return orderPossessionValue;
    case 'على الرفوف':
      return OrderPossession.branch;
    case 'بانتظار التحميل':
      return OrderPossession.customer;
    case "الطلبات الجديدة":
      return OrderPossession.customer;
    case 'بانتظار مراجعة الإدارة':
      return OrderPossession.customer;
    case 'ملغاة':
      return OrderPossession.customer;
    case 'رفضها السائق':
      return OrderPossession.branch;
    case 'مصدرة إلى شريك':
      return OrderPossession.branch;
    case 'مسودة':
      return OrderPossession.branch;
    case 'تالفة':
      return OrderPossession.branch;
    case 'تم توصيلها بشكل جزئي':
      return OrderPossession.driverShipping;
    case 'مؤجلة لوقت آخر':
      return OrderPossession.branch;
    default:
      return OrderPossession.branch;
  }
}
