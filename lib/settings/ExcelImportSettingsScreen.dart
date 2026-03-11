import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../shared/appProvider.dart';
import '../../shared/constants.dart';
import '../../models/customer.dart';

class ExcelImportSettingsScreen extends StatefulWidget {
  const ExcelImportSettingsScreen({super.key});

  @override
  State<ExcelImportSettingsScreen> createState() =>
      _ExcelImportSettingsScreenState();
}

class _ExcelImportSettingsScreenState extends State<ExcelImportSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Directionality(
                  textDirection: TextDirection.ltr,

      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text("ضبط استيراد الاكسل",
              style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header with Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تكوينات استيراد الاكسل",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showConfigDialog(context, appProvider);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("إضافة تكوين جديد"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // List of Configurations
              Expanded(
                child: appProvider.excelConfigs.isEmpty
                    ? const Center(
                        child: Text("لا توجد تكوينات محفوظة"),
                      )
                    : ListView.builder(
                        itemCount: appProvider.excelConfigs.length,
                        itemBuilder: (context, index) {
                          final config = appProvider.excelConfigs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(config['name'] ?? 'بدون اسم'),
                              subtitle: Text(
                                  "رقم سطر العناوين: ${config['headerRowIndex']}"),
                              leading: const Icon(Icons.table_chart),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _showConfigDialog(context, appProvider,
                                          config: config,
                                          configId: config['id']);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      _confirmDelete(
                                          context, appProvider, config['id']);
                                    },
                                  ),
                                  const Icon(Icons.expand_more),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "العملاء المرتبطين:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        children: (config['customerIds']
                                                as List<dynamic>)
                                            .map((id) {
                                          final customer = appProvider.customers
                                              .where((c) => c.userid == id)
                                              .firstOrNull;
                                          return Chip(
                                            label:
                                                Text(customer?.username ?? id),
                                            avatar: const Icon(Icons.person,
                                                size: 16),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "تعيين الأعمدة:",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: (config['colMap']
                                                as Map<String, dynamic>)
                                            .entries
                                            .map((entry) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: Colors.grey[400]!),
                                            ),
                                            child: Text(
                                                "${entry.key} -> ${entry.value}"),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider appProvider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف التكوين"),
        content: const Text("هل أنت متأكد من رغبتك في حذف هذا التكوين؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              appProvider.deleteExcelConfig(id);
              Navigator.of(ctx).pop();
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog(BuildContext context, AppProvider appProvider,
      {Map<String, dynamic>? config, String? configId}) {
    final nameController = TextEditingController(text: config?['name'] ?? '');
    final headerRowController = TextEditingController(
        text: config?['headerRowIndex']?.toString() ?? '0');

    // Map of internal field names to user-friendly names
    final Map<String, String> fieldOptions = {
      // 'orderId': 'رقم الطلب',
      'senderName': 'اسم المرسل',
      'recipientName': 'اسم المستقبل',
      'phoneNumber': 'رقم الهاتف',
      'extraPhone': 'رقم هاتف إضافي',
      //'city': 'المدينة',
      'address': 'العنوان',
      'contents': 'المحتويات',
      //'status': 'الحالة',
      'paymentMethod': 'طريقة الدفع',
      'codAmount': 'قيمة الدفع عند الاستلام',
      //'deliveryCost': 'تكرة التوصيل',
      'weight': 'الوزن',
      'parcelCount': 'عدد الطرود',
      'notes': 'ملاحظات',
      'serviceType': 'نوع الخدمة',
      'expectedDeliveryDate': 'تاريخ التوصيل المتوقع',
      //'deliveryDate': 'تاريخ التوصيل الفعلي',
      'trackingNumber': 'رقم التتبع',
    };

    Map<String, String> currentMapping = {};
    if (config != null && config['colMap'] != null) {
      (config['colMap'] as Map<String, dynamic>).forEach((key, value) {
        currentMapping[key] = value.toString();
      });
    }

    Set<String> selectedCustomerIds = {};
    if (config != null && config['customerIds'] != null) {
      selectedCustomerIds = Set<String>.from(config['customerIds']);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(config == null ? "إضافة تكوين جديد" : "تعديل التكوين"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: "اسم التكوين"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: headerRowController,
                      decoration: const InputDecoration(
                          labelText: "رقم سطر العناوين (يبدأ من 0)"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    const Text("العملاء:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: appProvider.customers.length,
                        itemBuilder: (context, index) {
                          final customer = appProvider.customers[index];
                          final isSelected =
                              selectedCustomerIds.contains(customer.userid);
                          return CheckboxListTile(
                            title: Text(customer.username ?? customer.userid),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedCustomerIds.add(customer.userid);
                                } else {
                                  selectedCustomerIds.remove(customer.userid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("تعيين الأعمدة:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text("أدخل اسم العمود كما يظهر في ملف الإكسل",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...fieldOptions.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(entry.value),
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: currentMapping[entry.key] ?? '',
                                decoration: InputDecoration(
                                  hintText: "اسم العمود في الملف",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 0),
                                ),
                                onChanged: (val) {
                                  if (val.trim().isEmpty) {
                                    currentMapping.remove(entry.key);
                                  } else {
                                    currentMapping[entry.key] = val.trim();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("يرجى إدخال اسم التكوين")),
                    );
                    return;
                  }

                  final newConfig = {
                    if (configId != null) 'id': configId,
                    'name': nameController.text,
                    'headerRowIndex':
                        int.tryParse(headerRowController.text) ?? 0,
                    'customerIds': selectedCustomerIds.toList(),
                    'colMap': currentMapping,
                  };

                  if (configId != null) {
                    appProvider.updateExcelConfig(configId, newConfig);
                  } else {
                    appProvider.addExcelConfig(newConfig);
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text("حفظ"),
              ),
            ],
          );
        },
      ),
    );
  }
}
