import '../../main.dart';
import '../../models/UserAccount.dart';
import '../../shared/PrintHelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/DriverDeliveryData.dart';
import '../../shared/appProvider.dart';
import '../../shared/firebaseHelper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<DriverDeliveryData> deliveryDataList = [];

  DateTime? startDate;
  DateTime? endDate;
  String? selectedShipmentType = 'كل الشحنات';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final firstDayOfWeek = now
        .subtract(Duration(days: fromWeekdayMondayToSaturday(now.weekday) - 1));
    startDate = DateTime(
        firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day, 0, 0, 0);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  final List<String> shipmentTypes = [
    'كل الشحنات',
    'الشحنات المسلمه',
    'الشحنات الغير المسلمه',
  ];

  bool _showDeliveryData = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      // Show loading indicator while data is being fetched
      if (appProvider.customers.isEmpty && appProvider.drivers.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(appProvider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('عرض حسابات المستخدمين'),
              Switch(
                value: !_showDeliveryData,
                onChanged: (value) {
                  setState(() {
                    _showDeliveryData = !value;
                  });
                },
              ),
            ],
          ),
          _buildDataTable(appProvider),
          const SizedBox(height: 16),
        ],
      );
    });
  }

  Widget _buildFilters(AppProvider appProvider) {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'الإحصائيات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildDropdown(
                hint: 'اختر الزبون',
                onCancel: () =>
                    setState(() => appProvider.selectedCustomer = null),
                appProvider.selectedCustomer,
                appProvider.customers.isNotEmpty
                    ? appProvider.customers
                        .where(
                            (e) => e.username != null && e.username!.isNotEmpty)
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.username!)))
                        .toList()
                    : [],
                (value) {
                  appProvider.setSelectedCustomer(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildDropdown(
                hint: 'اختر السائق',
                onCancel: () =>
                    setState(() => appProvider.selectedDriver = null),
                appProvider.selectedDriver,
                appProvider.drivers.isNotEmpty
                    ? appProvider.drivers
                        .where(
                            (e) => e.username != null && e.username!.isNotEmpty)
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.username!)))
                        .toList()
                    : [],
                (value) {
                  appProvider.setSelectedDriver(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
                width: 200,
                child: _buildDropdown(
                  selectedShipmentType,
                  shipmentTypes
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  (value) {
                    setState(() {
                      selectedShipmentType = value as String?;
                    });
                  },
                )),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  startDate = DateTime(DateTime.now().year,
                      DateTime.now().month, DateTime.now().day, 0, 0, 0);
                  endDate = DateTime(DateTime.now().year, DateTime.now().month,
                      DateTime.now().day, 23, 59, 59);
                });
              },
              child: const Text('اليوم'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final firstDayOfWeek = now.subtract(Duration(
                    days: fromWeekdayMondayToSaturday(now.weekday) - 1));
                setState(() {
                  startDate = DateTime(firstDayOfWeek.year,
                      firstDayOfWeek.month, firstDayOfWeek.day, 0, 0, 0);
                  endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
              },
              child: const Text('هذا الأسبوع'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final firstDayOfMonth = DateTime(now.year, now.month, 1);
                setState(() {
                  startDate = firstDayOfMonth;
                  endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
              },
              child: const Text('هذا الشهر'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                setState(() {
                  startDate = DateTime(now.year, 1, 1);
                  endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
              },
              child: const Text('العام'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      startDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(startDate == null
                          ? 'تاريخ البداية'
                          : DateFormat('yyyy/MM/dd').format(startDate!)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      endDate = DateTime(
                          picked.year, picked.month, picked.day, 23, 59, 59);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(endDate == null
                          ? 'تاريخ النهاية'
                          : DateFormat('yyyy/MM/dd').format(endDate!)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(dynamic value, List<DropdownMenuItem<dynamic>> items,
      Function(dynamic) onChanged,
      {void Function()? onCancel, String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<dynamic>(
        icon: onCancel == null || value == null
            ? null
            : IconButton(
                onPressed: onCancel,
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ),
        value: items.any((item) => item.value == value) ? value : null,
        items: items.isNotEmpty
            ? items
            : [
                DropdownMenuItem(
                    value: null, child: Text(hint ?? 'لا توجد بيانات'))
              ],
        hint: Text(hint ?? ''),
        onChanged: items.isNotEmpty ? onChanged : null,
        isExpanded: true,
        underline: Container(),
      ),
    );
  }

  Widget _buildDataTable(AppProvider appProvider) {
    return Expanded(
      child: StreamBuilder<List<DriverDeliveryData>>(
        stream: FirebaseHelper().getDriverDeliveryData(
          drivers: appProvider.drivers,
          selectedCustomerId: appProvider.selectedCustomer?.userid,
          selectedDriverId: appProvider.selectedDriver?.userid,
          startDate: startDate,
          endDate: endDate,
          shipmentType: selectedShipmentType == 'كل الشحنات'
              ? null
              : selectedShipmentType,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return SelectableText('Error: ${snapshot.error}');
          }

          deliveryDataList = snapshot.data ?? [];
          List<UserAccount> userAccounts = deliveryDataList.toUserAccounts();

          // Calculate statistics
          double totalCollections = deliveryDataList.fold(
              0, (sum, data) => sum + data.totalCollections);
          int totalParcels =
              deliveryDataList.fold(0, (sum, data) => sum + data.parcelCount);
          double totalPrice =
              deliveryDataList.fold(0, (sum, data) => sum + data.price);

          int totalDeliveredParcels = deliveryDataList
              .where((data) => data.parcelCount > 0)
              .fold(0, (sum, data) => sum + data.parcelCount);

          int totalUndeliveredParcels = totalParcels - totalDeliveredParcels;

          double deliverySuccessRate = totalParcels > 0
              ? (totalDeliveredParcels / totalParcels) * 100
              : 0;

          double averageParcelPrice =
              totalParcels > 0 ? totalPrice / totalParcels : 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildSummaryCard(
                      'إجمالي التحصيلات',
                      'JOD ${NumberFormat('#,###.##').format(totalCollections)}',
                      Color(0xFFDC2626),
                    ),
                    _buildSummaryCard(
                      'إجمالي الطرود',
                      totalParcels.toString(),
                      Color(0xFFDC2626),
                    ),
                    _buildSummaryCard(
                      'الطرود المسلمة',
                      totalDeliveredParcels.toString(),
                      Colors.teal,
                    ),
                    _buildSummaryCard(
                      'الطرود غير المسلمة',
                      totalUndeliveredParcels.toString(),
                      primary,
                    ),
                    _buildSummaryCard(
                      'نسبة نجاح التسليم',
                      '${NumberFormat('#,###.#').format(deliverySuccessRate)}%',
                      Colors.purple,
                    ),
                    _buildSummaryCard(
                      'متوسط سعر الطرد',
                      'JOD ${NumberFormat('#,###.##').format(averageParcelPrice)}',
                      Colors.indigo,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: _showDeliveryData
                      ? DataTable(
                          columns: const [
                            DataColumn(label: Text('اسم السائق')),
                            DataColumn(label: Text('تاريخ التوصيل')),
                            DataColumn(label: Text('عدد الطرود')),
                            DataColumn(label: Text('التحصيلات')),
                            DataColumn(label: Text('السعر')),
                            DataColumn(label: Text('حالة التسليم')),
                            DataColumn(label: Text('')),
                          ],
                          rows: deliveryDataList.map((data) {
                            return DataRow(
                              cells: [
                                DataCell(Text(data.driverName)),
                                DataCell(Text(DateFormat('yyyy/MM/dd')
                                    .format(data.deliveryDate))),
                                DataCell(Text(data.parcelCount.toString())),
                                DataCell(Text(
                                    'JOD ${NumberFormat('#,###.##').format(data.totalCollections)}')),
                                DataCell(Text(
                                    'JOD ${NumberFormat('#,###.##').format(data.price)}')),
                                DataCell(Text(data.parcelCount > 0
                                    ? 'تم التسليم'
                                    : 'لم يتم التسليم')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.print),
                                    onPressed: () {
                                      PrintHandler()
                                          .printDriverDeliveryDataDocument(
                                              data);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        )
                      : DataTable(
                          columns: const [
                            DataColumn(label: Text('اسم العميل')),
                            DataColumn(label: Text('إجمالي الطرود')),
                            DataColumn(label: Text('الطرود المرتجعة')),
                            DataColumn(label: Text('إجمالي المبلغ')),
                            DataColumn(label: Text('رسوم الخدمة')),
                            DataColumn(label: Text('')),
                          ],
                          rows: userAccounts.map((account) {
                            return DataRow(
                              cells: [
                                DataCell(Text(account.client)),
                                DataCell(Text(account.totalParcels.toString())),
                                DataCell(
                                    Text(account.returnedParcels.toString())),
                                DataCell(Text(
                                    'JOD ${NumberFormat('#,###.##').format(account.totalAmount)}')),
                                DataCell(Text(
                                    'JOD ${NumberFormat('#,###.##').format(account.servicesFees)}')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.print),
                                    onPressed: () {
                                      PrintHandler()
                                          .printUserAccountDocument(account);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(16),
        width: 200,
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int fromWeekdayMondayToSaturday(int weekday) {
  switch (weekday) {
    case 1:
      return 3;
    case 2:
      return 4;
    case 3:
      return 5;
    case 4:
      return 6;
    case 5:
      return 7;
    case 6:
      return 1;
    case 7:
      return 2;
    default:
      return 1;
  }
}
