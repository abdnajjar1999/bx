import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/Driver.dart';
import '../../shared/appProvider.dart';
import '../ManageShipments/widget/CustomTextField.dart';
import '../ManageShipments/widget/CustomDropdown.dart';
import 'package:fl_chart/fl_chart.dart';

class CollectionToursScreen extends StatefulWidget {
  const CollectionToursScreen({Key? key}) : super(key: key);

  @override
  _CollectionToursScreenState createState() => _CollectionToursScreenState();
}

class _CollectionToursScreenState extends State<CollectionToursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tourNameController = TextEditingController();
  final _customerSearchController = TextEditingController();
  List<String> selectedCustomers = []; // List of customer usernames
  Driver? selectedDriver;
  DocumentSnapshot? selectedTour;

  @override
  void dispose() {
    _tourNameController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      selectedTour = null;
      _tourNameController.clear();
      _customerSearchController.clear();
      selectedCustomers = [];
      selectedDriver = null;
    });
  }

  void _selectTour(DocumentSnapshot doc, List<Driver> drivers) {
    setState(() {
      selectedTour = doc;
      final data = doc.data() as Map<String, dynamic>;
      _tourNameController.text = data['name'] ?? '';
      selectedCustomers = List<String>.from(data['customers'] ?? []);

      final driverId = data['driverId'];
      if (driverId != null) {
        selectedDriver = drivers.where((d) => d.userid == driverId).firstOrNull;
      } else {
        selectedDriver = null;
      }
    });
  }

  Future<void> _saveTour() async {
    if (_formKey.currentState!.validate()) {
      if (selectedCustomers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار زبون واحد على الأقل')),
        );
        return;
      }

      final data = {
        'name': _tourNameController.text.trim(),
        'customers': selectedCustomers,
        'driverId': selectedDriver?.userid,
        'driverName': selectedDriver?.username,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        if (selectedTour == null) {
          await FirebaseFirestore.instance.collection('collection_tours').add({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance
              .collection('collection_tours')
              .doc(selectedTour!.id)
              .update(data);
        }

        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ جولة الجلب بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _deleteTour(String id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد من حذف جولة الجلب هذه؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('collection_tours')
            .doc(id)
            .delete();
        if (selectedTour?.id == id) {
          _clearForm();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف جولة الجلب بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
        );
      }
    }
  }

  Widget _buildTourStats(
      List<String> customerNames, List<QueryDocumentSnapshot> todayOrders) {
    final tourOrders = todayOrders.where((order) {
      final orderData = order.data() as Map<String, dynamic>;
      final senderName = orderData['senderName']?.toString() ?? '';
      return customerNames.contains(senderName);
    }).toList();

    int newOrders = 0;
    int awaitingLoading = 0;
    int inVehicle = 0;

    for (var order in tourOrders) {
      final status = (order.data() as Map<String, dynamic>)['status'] ?? '';
      if (status == 'الطلبات الجديدة') {
        newOrders++;
      } else if (status == 'بانتظار التحميل') {
        awaitingLoading++;
      } else if (status == 'في المركبة') {
        inVehicle++;
      }
    }

    if (tourOrders.isEmpty) {
      return const Center(
          child: Text('لا توجد طلبات جلب اليوم',
              style: TextStyle(fontSize: 10, color: Colors.grey)));
    }

    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 15,
                sections: [
                  if (newOrders > 0)
                    PieChartSectionData(
                      color: Colors.blue,
                      value: newOrders.toDouble(),
                      title: newOrders.toString(),
                      radius: 35,
                      titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (awaitingLoading > 0)
                    PieChartSectionData(
                      color: Colors.orange,
                      value: awaitingLoading.toDouble(),
                      title: awaitingLoading.toString(),
                      radius: 35,
                      titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (inVehicle > 0)
                    PieChartSectionData(
                      color: Colors.purple,
                      value: inVehicle.toDouble(),
                      title: inVehicle.toString(),
                      radius: 35,
                      titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSimpleLegend('جديدة', Colors.blue, newOrders),
                const SizedBox(height: 4),
                _buildSimpleLegend(
                    'بانتظار التحميل', Colors.orange, awaitingLoading),
                const SizedBox(height: 4),
                _buildSimpleLegend('في المركبة', Colors.purple, inVehicle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Text('$label: $count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final firebaseHelper = appProvider.firebaseHelper;
    final drivers = appProvider.drivers;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إحصائيات وإدارة جولات الجلب'),
          actions: [
            if (selectedTour != null)
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                onPressed: _clearForm,
                tooltip: 'إضافة جولة جلب جديدة',
              ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: firebaseHelper.getTodayOrdersStream(),
          builder: (context, ordersSnapshot) {
            final todayOrders = ordersSnapshot.data?.docs ?? [];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ملخص جولات الجلب اليوم',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('collection_tours')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const Center(
                                    child: CircularProgressIndicator());

                              final docs = snapshot.data!.docs;
                              if (docs.isEmpty) {
                                return const Center(
                                    child:
                                        Text('لا يوجد جولات جلب مضافة حالياً'));
                              }

                              return GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400,
                                  mainAxisExtent: 260,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final customers = List<String>.from(
                                      data['customers'] ?? []);
                                  final isSelected = selectedTour?.id == doc.id;

                                  return Card(
                                    elevation: isSelected ? 4 : 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isSelected
                                          ? BorderSide(
                                              color: Colors.green, width: 2)
                                          : BorderSide.none,
                                    ),
                                    child: InkWell(
                                      onTap: () => _selectTour(doc, drivers),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                      data['name'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _deleteTour(doc.id),
                                                ),
                                              ],
                                            ),
                                            Text(
                                                'السائق: ${data['driverName'] ?? 'غير معين'}',
                                                style: TextStyle(
                                                    color: data['driverName'] ==
                                                            null
                                                        ? Colors.red
                                                        : Colors.green,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            const Divider(height: 24),
                                            const Text('إحصائيات الجلب اليوم:',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                            const SizedBox(height: 8),
                                            _buildTourStats(
                                                customers, todayOrders),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border(right: BorderSide(color: Colors.grey.shade300)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(-2, 0))
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTour != null
                                    ? 'تعديل جولة الجلب'
                                    : 'إنشاء جولة جلب جديدة',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              if (selectedTour != null)
                                TextButton.icon(
                                  onPressed: _clearForm,
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('إلغاء'),
                                )
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _tourNameController,
                            labelText: 'اسم جولة الجلب',
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'هذا الحقل مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          CustomDropdown(
                            items:
                                drivers.map((d) => d.username ?? '').toList(),
                            value: selectedDriver?.username,
                            labelText: 'سائق الجلب المخصص',
                            onChanged: (value) {
                              setState(() {
                                selectedDriver = drivers
                                    .where((d) => d.username == value)
                                    .firstOrNull;
                              });
                            },
                            onClearPressed: () =>
                                setState(() => selectedDriver = null),
                          ),
                          const SizedBox(height: 24),
                          const Text('تغطية الزبائن',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customerSearchController,
                            decoration: InputDecoration(
                              hintText: 'بحث عن زبون...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 400,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: appProvider.customers.length,
                              itemBuilder: (context, index) {
                                final customer = appProvider.customers[index];
                                final name = customer.username;
                                if (_customerSearchController.text.isNotEmpty &&
                                    !name.toLowerCase().contains(
                                        _customerSearchController.text
                                            .toLowerCase())) {
                                  return const SizedBox.shrink();
                                }
                                final isSelected =
                                    selectedCustomers.contains(name);
                                return CheckboxListTile(
                                  title: Text(name),
                                  subtitle: Text(customer.address),
                                  value: isSelected,
                                  dense: true,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedCustomers.add(name);
                                      } else {
                                        selectedCustomers.remove(name);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _saveTour,
                            child: Text(
                                selectedTour != null
                                    ? 'تحديث بيانات جولة الجلب'
                                    : 'إنشاء جولة الجلب الآن',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
