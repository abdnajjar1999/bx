import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:good_line_delivery/shared/ExcelUtils.dart';
import 'package:good_line_delivery/shared/appProvider.dart';

import '../models/Shipment.dart';
import '../models/UserAccount.dart';
import '../models/Expense.dart';
import 'package:intl/intl.dart';

class ExcelImportHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Synonyms dictionary for field mapping
  final Map<String, List<String>> _fieldSynonyms = {
    'orderId': [
      'رقم الطلب',
      'Order ID',
      'رقم الشحنة',
      'Barcode',
      'باركود',
      'رقم الإرسالية',
      'رقم التسلسلي',
      'الباركود'
    ],
    'senderName': [
      'المرسل',
      'اسم المرسل',
      'إسم المرسل',
      'التاجر',
      'اسم التاجر',
      'المتجر',
      'اسم المتجر',
      'المحل',
      'مصدر الطلب',
      'العميل',
      'اسم الصفحه',
      'Sender Name',
      'Sender',
    ],
    'recipientName': [
      'المستقبل',
      'إسم المستقبل',
      'Recipient Name',
      'Recipient',
    ],
    'phoneNumber': [
      'رقم الهاتف',
      'هاتف المستقبل',
      'Phone Number',
      'Phone',
      'رقم الجوال',
      'هاتف المستلم',
      'رقم هاتف المستقبل'
    ],
    'extraPhone': [
      'هاتف المستقبل الإضافي',
      'رقم هاتف إضافي',
      'Secondary Phone'
    ],
    'city': ['المدينة', 'City', 'مدينة المستقبل', 'مدينة المستلم'],
    'address': [
      'العنوان',
      'Address',
      'العنوان بالتفصيل',
      'الحي',
      'الشارع',
      'تفاصيل العنوان'
    ],
    'contents': ['المحتويات', 'Contents', 'وصف الطرد', 'محتوى الطرد'],
    'status': ['الحالة', 'Status', 'حالة الطرد'],
    'paymentMethod': ['طريقة الدفع', 'Payment Method', 'نوع الدفع'],
    'codAmount': [
      'قيمة الدفع عند الاستلام',
      'COD',
      'COD Amount',
      'التحصيل',
      'التحصيل الأصلي',
      'صافي التحصيل',
      'القيمة المطلوب تحصيلها',
      'الإجمالي'
    ],
    'deliveryCost': [
      'تكلفة التوصيل',
      'Delivery Cost',
      'سعر التوصيل',
      'أجرة التوصيل'
    ],
    'weight': ['الوزن', 'Weight'],
    'parcelCount': [
      'عدد الطرود',
      'Parcel Count',
      'الكمية',
      'عدد القطع',
      'عدد الطرود'
    ],
    'notes': ['ملاحظات', 'Notes', 'ملاحظات العميل'],
    'serviceType': ['نوع الخدمة', 'Service Type'],
    'expectedDeliveryDate': [
      'تاريخ التوصيل المتوقع',
      'Expected Delivery Date',
      'تاريخ التوصيل'
    ],
    'deliveryDate': ['تاريخ التوصيل فعلي', 'تم التوصيل بتاريخ'],
    'trackingNumber': [
      'رقم إرسالية المزود',
      'الإرسالية',
      'Tracking Number',
      'Barcode',
      'باركود',
      'الباركود'
    ],
  };

  Future<List<Shipment>> importShipmentsFromExcel({
    String? selectedUserId,
    String? selectedUsername,
    AppProvider? appProvider,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      // print(result);

      if (result != null && result.files.isNotEmpty) {
        Uint8List bytes = result.files.first.bytes!;
        var excel = _safeDecodeExcel(bytes);
        print(excel.tables);

        List<Shipment> parsedShipments = [];

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          if (rows.isEmpty) continue;
          //print(rows);

          // Determine header and mapping (using custom config if available)
          var headerInfo = _determineHeaderAndMapping(
              rows, selectedUserId, appProvider?.excelConfigs);
          Map<String, List<int>> colMap =
              headerInfo['colMap'] as Map<String, List<int>>;
          int headerRowIndex = headerInfo['headerRowIndex'] as int;
          bool hasHeaders = colMap.isNotEmpty;
          int startRow = hasHeaders ? headerRowIndex + 1 : 0;
          print(colMap);

          for (int i = startRow; i < rows.length; i++) {
            var row = rows[i];

            String? orderId = DateTime.now()
                .millisecondsSinceEpoch
                .toString()
                .replaceRange(0, 3, i.toString());

            // تنظيف العنوان من المسافات الزائدة والمزدوجة لضمان مطابقة دقيقة
            String address = (_getValueByField(row, colMap, 'address') ?? "")
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            String city = "";
            
            // خوارزمية المطابقة المباشرة المعتمدة على البحث عن الاسم الأطول والأكثر دقة
            if (address.isNotEmpty && appProvider?.citiesAndPlacesNames != null) {
              List<String> choices = List.from(appProvider!.citiesAndPlacesNames);
              // ترتيب الخيارات من الأطول إلى الأقصر لضمان التقاط المنطقة التفصيلية أولاً
              choices.sort((a, b) => b.length.compareTo(a.length));
              
              for (var choice in choices) {
                if (address.contains(choice)) {
                  city = choice;
                  break; // توقف عند أول تطابق لأنه الأطول والأكثر دقة
                }
              }
            }
            
            // محاولة أخيرة من عمود المدينة إذا لم تجد الخوارزمية شيئاً في العنوان
            if (city.isEmpty) {
              city = _getValueByField(row, colMap, 'city') ?? "غير محدد";
            }

            double deliveryCost = appProvider!
                .calculateDeliveryCostForCity(city, selectedUserId ?? "");

            Shipment shipment = Shipment(
              userId: selectedUserId ?? '',
              username: selectedUsername ?? 'مجهول',
              senderName:
                  _getValueByField(row, colMap, 'senderName') ?? "مجهول",
              orderId: orderId ?? '',
              profileImageUrl: null,
              packageAttributes: PackageAttributes(
                isFragile: false,
                needsPackaging: false,
                hasDangerousMaterials: false,
                isNonOpenable: false,
                canBeFolded: false,
                measurementForbidden: false,
              ),
              deliveryCost: deliveryCost,
              collectionMethod:
                  _getValueByField(row, colMap, 'collectionMethod') ?? 'كاش',
              recipientName:
                  _getValueByField(row, colMap, 'recipientName') ?? 'مجهول',
              phoneNumber: _getValueByField(row, colMap, 'phoneNumber') ?? '',
              secondaryPhoneNumber:
                  _getValueByField(row, colMap, 'extraPhone') ?? '',
              city: city,
              addressDescription: address,
              paymentMethod:
                  _getValueByField(row, colMap, 'paymentMethod') ?? 'إحضار',
              codAmount: _parseDouble(
                  _getValueByField(row, colMap, 'codAmount') ?? '0'),
              serviceType:
                  _getValueByField(row, colMap, 'serviceType') ?? 'اعتيادي',
              trackingNumber: _getValueByField(row, colMap, 'trackingNumber') ??
                  orderId ??
                  '',
              contents: _getValueByField(row, colMap, 'contents') ?? '',
              weight:
                  _parseDouble(_getValueByField(row, colMap, 'weight') ?? '0'),
              notes: _getValueByField(row, colMap, 'notes') ?? '',
              parcelCount: _parseInt(
                  _getValueByField(row, colMap, 'parcelCount') ?? '1'),
              status: 'الطلبات الجديدة',
              createdAt: DateTime.now(),
              lastUpdated: DateTime.now(),
              deliveryDate: _parseDateTime(
                  _getValueByField(row, colMap, 'deliveryDate') ?? null),
              expectedDeliveryDate: _parseDateTime(
                  _getValueByField(row, colMap, 'expectedDeliveryDate') ??
                      null),
              postponementDate: null,
              isAddressed: false,
              cashPossession: CashPossession.receiver,
              orderPossession: OrderPossession.customer,
              logs: [
                ShipmentLog(
                  date: DateTime.now(),
                  text: 'تمت إضافة الشحنة عن طريق الإكسل',
                  status: 'الطلبات الجديدة',
                  userName:
                      FirebaseAuth.instance.currentUser?.displayName ?? "مجهول",
                )
              ],
            );

            parsedShipments.add(shipment);
          }
        }
        return parsedShipments;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadShipments(List<Shipment> shipments) async {
    if (shipments.isEmpty) return;

    // Convert List<Shipment> to List<Map<String, dynamic>>
    List<Map<String, dynamic>> batchData =
        shipments.map((s) => s.toMap()).toList();
    await _uploadBatchOrders(batchData);
  }

  Map<String, int> _buildColumnMap(List<Data?> headerRow) {
    Map<String, int> map = {};

    _fieldSynonyms.forEach((field, synonyms) {
      int bestIndex = -1;

      for (int i = 0; i < headerRow.length; i++) {
        String? header = headerRow[i]?.value?.toString().trim().toLowerCase();
        if (header == null || header.isEmpty) continue;

        for (var synonym in synonyms) {
          String normalizedSynonym = synonym.toLowerCase();
          // المطابقة المباشرة أو الاحتواء الكامل
          if (header == normalizedSynonym || 
              header.contains(normalizedSynonym) || 
              normalizedSynonym.contains(header)) {
            bestIndex = i;
            break;
          }
        }
        if (bestIndex != -1) break;
      }

      if (bestIndex != -1) {
        map[field] = bestIndex;
      }
    });

    return map;
  }

  Map<String, dynamic> _findBestHeaderRow(List<List<Data?>> rows) {
    int bestRowIndex = -1;
    Map<String, int> bestColMap = {};
    int maxMatches = 0;

    // Check first 20 rows for headers
    int searchLimit = rows.length < 20 ? rows.length : 20;

    for (int i = 0; i < searchLimit; i++) {
      Map<String, int> colMap = _buildColumnMap(rows[i]);
      if (colMap.length > maxMatches) {
        maxMatches = colMap.length;
        bestColMap = colMap;
        bestRowIndex = i;
      }
    }

    return {
      'headerRowIndex': bestRowIndex,
      'colMap': bestColMap,
    };
  }

  Excel _safeDecodeExcel(Uint8List bytes) {
    return ExcelUtils.safeDecode(bytes);
  }

  String? _getValueByField(
      List<Data?> row, Map<String, List<int>> colMap, String field) {
    if (!colMap.containsKey(field)) return null;
    List<int> indices = colMap[field]!;
    if (indices.isEmpty) return null;
    String value = "";
    for (int index in indices) {
      value += " ${row[index]?.value?.toString() ?? ""}";
    }

    return value.trim();
  }

  Future<Uint8List> exportShipmentsToExcel(List<Shipment> shipments, {List<Map<String, dynamic>>? columns}) async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    List<Map<String, dynamic>> effectiveColumns = columns ?? [
      {'id': 'orderId', 'label': 'رقم الطلب', 'visible': true},
      {'id': 'trackingNumber', 'label': 'الإرسالية', 'visible': true},
      {'id': 'username', 'label': 'العميل', 'visible': true},
      {'id': 'recipientName', 'label': 'اسم المستلم', 'visible': true},
      {'id': 'phoneNumber', 'label': 'رقم الهاتف', 'visible': true},
      {'id': 'city', 'label': 'المدينة', 'visible': true},
      {'id': 'addressDescription', 'label': 'العنوان', 'visible': true},
      {'id': 'contents', 'label': 'المحتويات', 'visible': true},
      {'id': 'status', 'label': 'الحالة', 'visible': true},
      {'id': 'paymentMethod', 'label': 'طريقة الدفع', 'visible': true},
      {'id': 'codAmount', 'label': 'قيمة الدفع عند الاستلام', 'visible': true},
      {'id': 'deliveryCost', 'label': 'تكلفة التوصيل', 'visible': true},
      {'id': 'weight', 'label': 'الوزن', 'visible': true},
      {'id': 'parcelCount', 'label': 'عدد الطرود', 'visible': true},
      {'id': 'notes', 'label': 'ملاحظات', 'visible': true},
      {'id': 'serviceType', 'label': 'نوع الخدمة', 'visible': true},
      {'id': 'createdAt', 'label': 'تاريخ الإنشاء', 'visible': true},
      {'id': 'lastUpdated', 'label': 'تاريخ التحديث', 'visible': true},
      {'id': 'expectedDeliveryDate', 'label': 'تاريخ التسليم المتوقع', 'visible': true},
      {'id': 'deliveryDate', 'label': 'تاريخ التسليم', 'visible': true},
      {'id': 'driverName', 'label': 'اسم السائق', 'visible': true},
    ];

    List<Map<String, dynamic>> visibleColumns =
        effectiveColumns.where((c) => c['visible'] == true).toList();

    List<String> headers = visibleColumns.map((c) => c['label'] as String).toList();

    // Add headers
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
    }

    // Write data
    for (var i = 0; i < shipments.length; i++) {
      var shipment = shipments[i];
      var rowIndex = i + 1;

      List<CellValue> row = [];
      for (var col in visibleColumns) {
        String id = col['id'] ?? '';
        if (id == 'orderId') row.add(TextCellValue(shipment.orderId));
        else if (id == 'trackingNumber') row.add(TextCellValue(shipment.trackingNumber));
        else if (id == 'username') row.add(TextCellValue(shipment.username ?? ''));
        else if (id == 'recipientName') row.add(TextCellValue(shipment.recipientName));
        else if (id == 'phoneNumber') row.add(TextCellValue(shipment.phoneNumber));
        else if (id == 'city') row.add(TextCellValue(shipment.city));
        else if (id == 'addressDescription') row.add(TextCellValue(shipment.addressDescription));
        else if (id == 'contents') row.add(TextCellValue(shipment.contents));
        else if (id == 'status') row.add(TextCellValue(shipment.status));
        else if (id == 'paymentMethod') row.add(TextCellValue(shipment.paymentMethod));
        else if (id == 'codAmount') row.add(DoubleCellValue(shipment.codAmount));
        else if (id == 'deliveryCost') row.add(DoubleCellValue(shipment.deliveryCost));
        else if (id == 'weight') row.add(DoubleCellValue(shipment.weight));
        else if (id == 'parcelCount') row.add(IntCellValue(shipment.parcelCount));
        else if (id == 'notes') row.add(TextCellValue(shipment.notes));
        else if (id == 'serviceType') row.add(TextCellValue(shipment.serviceType));
        else if (id == 'createdAt') row.add(TextCellValue(DateFormat('yyyy/MM/dd').format(shipment.createdAt)));
        else if (id == 'lastUpdated') row.add(TextCellValue(DateFormat('yyyy/MM/dd').format(shipment.lastUpdated)));
        else if (id == 'expectedDeliveryDate') {
          row.add(TextCellValue(shipment.expectedDeliveryDate != null
              ? DateFormat('yyyy/MM/dd').format(shipment.expectedDeliveryDate!)
              : ''));
        } else if (id == 'deliveryDate') {
          row.add(TextCellValue(shipment.deliveryDate != null
              ? DateFormat('yyyy/MM/dd').format(shipment.deliveryDate!)
              : ''));
        }
        else if (id == 'driverName') row.add(TextCellValue(shipment.driverName ?? ''));
        else row.add(TextCellValue(''));
      }

      for (var j = 0; j < row.length; j++) {
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex))
          ..value = row[j];
      }
    }

    // Auto-fit columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    // Convert to Uint8List
    var excelData = excel.encode();
    return Uint8List.fromList(excelData!);
  }

  Future<Uint8List> exportAccountsToExcel(List<UserAccount> accounts) async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers
    List<String> headers = [
      'اسم العميل',
      'الموقع',
      'الفرع',
      'إجمالي الطرود',
      'الطرود المرتجعة',
      'إجمالي الشحنات',
      'الطلبات المعينة',
      'نوع العميل',
      'طريقة الدفع',
      'رسوم الخدمات',
      'رسوم التأمين',
      'الضرائب',
      'المبلغ الإجمالي'
    ];

    // Write headers
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
    }

    // Write data
    for (var i = 0; i < accounts.length; i++) {
      var account = accounts[i];
      var rowIndex = i + 1;

      var row = [
        TextCellValue(account.client),
        TextCellValue(account.location ?? ''),
        TextCellValue(account.branch ?? ''),
        IntCellValue(account.totalParcels),
        IntCellValue(account.returnedParcels),
        IntCellValue(account.totalShipments),
        IntCellValue(account.assignedOrders),
        TextCellValue(account.userType ?? ''),
        TextCellValue(account.paymentType ?? ''),
        DoubleCellValue(account.servicesFees),
        DoubleCellValue(account.insuranceFees),
        DoubleCellValue(account.taxFees),
        DoubleCellValue(account.totalAmount),
      ];

      for (var j = 0; j < row.length; j++) {
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex))
          ..value = row[j];
      }
    }

    // Auto-fit columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    // Convert to Uint8List
    var excelData = excel.encode();
    return Uint8List.fromList(excelData!);
  }

  Future<Uint8List> exportExpensesToExcel(List<Expense> expenses) async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers
    List<String> headers = [
      'نوع المصروف',
      'اسم المستخدم',
      'المستفيد',
      'المستفيد (شريك)',
      'الفرع',
      'القيمة',
      'تاريخ الإنشاء',
      'تاريخ اخر تعديل',
      'ملاحظات'
    ];

    // Write headers
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
    }

    // Write data
    for (var i = 0; i < expenses.length; i++) {
      var expense = expenses[i];
      var rowIndex = i + 1;

      var row = [
        TextCellValue(expense.type),
        TextCellValue(expense.userName),
        TextCellValue(expense.beneficiary),
        TextCellValue(expense.partner ?? ''),
        TextCellValue(expense.branch),
        DoubleCellValue(expense.amount),
        TextCellValue(DateFormat('yyyy/MM/dd').format(expense.creationDate)),
        TextCellValue(
            DateFormat('yyyy/MM/dd').format(expense.modificationDate)),
        TextCellValue(expense.notes),
      ];

      for (var j = 0; j < row.length; j++) {
        sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex))
          ..value = row[j];
      }
    }

    // Auto-fit columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    // Convert to Uint8List
    var excelData = excel.encode();
    return Uint8List.fromList(excelData!);
  }

  Future<void> _uploadBatchOrders(List<Map<String, dynamic>> batchData) async {
    WriteBatch batch = _firestore.batch();
    print(batchData);

    for (var data in batchData) {
      DocumentReference docRef =
          _firestore.collection('orders').doc(data['orderId']);
      batch.set(docRef, data);
    }

    await batch.commit();
  }

  String? _getCellValue(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    return row[index]?.value?.toString();
  }

  double _parseDouble(String? value) {
    if (value == null) return 0.0;
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }

  int _parseInt(String? value) {
    if (value == null) return 1;
    try {
      return int.parse(value);
    } catch (e) {
      return 1;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // Try parsing as num (Excel internal date)
    if (value is num) {
      try {
        final startDate = DateTime(1900, 1, 1);
        final days = value.toInt() - 2;
        return startDate.add(Duration(days: days));
      } catch (_) {}
    }

    String stringValue = value.toString();
    try {
      return DateTime.parse(stringValue);
    } catch (e) {
      try {
        List<String> parts = stringValue.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (e) {
        return null;
      }
      return null;
    }
  }

  String _combineAddress(String? district, String? street) {
    List<String> parts = [];
    if (district?.isNotEmpty == true) parts.add(district!);
    if (street?.isNotEmpty == true) parts.add(street!);
    return parts.join(' - ');
  }

  Map<String, dynamic> _determineHeaderAndMapping(List<List<Data?>> rows,
      String? selectedUserId, List<Map<String, dynamic>>? excelConfigs) {
    // Check for custom config
    Map<String, dynamic>? customConfig;
    if (excelConfigs != null && selectedUserId != null) {
      try {
        customConfig = excelConfigs.firstWhere(
          (config) => (config['customerIds'] as List).contains(selectedUserId),
        );
      } catch (e) {
        print(e);
      }
    }

    if (customConfig != null) {
      int headerRowIndex = customConfig['headerRowIndex'] ?? 0;
      // Ensure we don't go out of bounds
      if (headerRowIndex < rows.length) {
        var headerRow = rows[headerRowIndex];
        Map<String, dynamic> configMap = customConfig['colMap'];
        Map<String, List<int>> colMap =
            configMap.map((key, value) => MapEntry(key, []));

        configMap.forEach((field, headerName) {
          for (int i = 0; i < headerRow.length; i++) {
            if (headerName
                .toString()
                .trim()
                .contains(headerRow[i]?.value.toString().trim() ?? "")) {
              colMap[field]!.add(i);
            }
          }
        });

        return {
          'headerRowIndex': headerRowIndex,
          'colMap': colMap,
        };
      }
    }

    // Fallback to auto-detection
    return _findBestHeaderRow(rows);
  }

  Future<Set<String>> getExistingTrackingNumbers(
      List<String> trackingNumbers) async {
    Set<String> existing = {};
    // Filter out empty tracking numbers to avoid unnecessary queries
    List<String> validTrackingNumbers =
        trackingNumbers.where((t) => t.isNotEmpty).toList();

    if (validTrackingNumbers.isEmpty) return existing;

    try {
      var snapshot = await _firestore
          .collection('orders')
          .where('trackingNumber', whereIn: validTrackingNumbers)
          .get();

      for (var doc in snapshot.docs) {
        existing.add(doc['trackingNumber'] as String);
      }
    } catch (e) {
      print("Error checking duplicates: $e");
    }

    return existing;
  }
}
