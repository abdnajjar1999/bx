import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/Driver.dart';
import '../../shared/appProvider.dart';
import '../ManageShipments/widget/CustomTextField.dart';
import '../ManageShipments/widget/CustomDropdown.dart';
import 'package:fl_chart/fl_chart.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({Key? key}) : super(key: key);

  @override
  _ToursScreenState createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tourNameController = TextEditingController();
  final _areaSearchController = TextEditingController();
  final _globalTourSearchController = TextEditingController();
  String _areaSearchQuery = '';
  String _globalTourSearchQuery = '';
  List<String> selectedAreas = []; // Format: "CityName - AreaName"
  Driver? selectedDriver;
  DocumentSnapshot? selectedTour;

  @override
  void dispose() {
    _tourNameController.dispose();
    _areaSearchController.dispose();
    _globalTourSearchController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      selectedTour = null;
      _tourNameController.clear();
      selectedAreas = [];
      selectedDriver = null;
    });
  }

  void _selectTour(DocumentSnapshot doc, List<Driver> drivers) {
    setState(() {
      selectedTour = doc;
      final data = doc.data() as Map<String, dynamic>;
      _tourNameController.text = data['name'] ?? '';
      selectedAreas = List<String>.from(data['areas'] ?? []);

      // Migrate old data if necessary (dash to space)
      selectedAreas =
          selectedAreas.map((e) => e.replaceAll(' - ', ' ')).toList();

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
      if (selectedAreas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار منطقة واحدة على الأقل')),
        );
        return;
      }

      final data = {
        'name': _tourNameController.text.trim(),
        'areas': selectedAreas,
        'driverId': selectedDriver?.userid,
        'driverName': selectedDriver?.username,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        if (selectedTour == null) {
          await FirebaseFirestore.instance.collection('tours').add({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance
              .collection('tours')
              .doc(selectedTour!.id)
              .update(data);
        }

        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الجولة بنجاح')),
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
            content: const Text('هل أنت متأكد من حذف هذه الجولة؟'),
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
        await FirebaseFirestore.instance.collection('tours').doc(id).delete();
        if (selectedTour?.id == id) {
          _clearForm();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الجولة بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
        );
      }
    }
  }

  Widget _buildTourStats(
      List<String> areas, List<QueryDocumentSnapshot> todayOrders) {
    final tourOrders = todayOrders.where((order) {
      final city =
          (order.data() as Map<String, dynamic>)['city']?.toString() ?? '';
      return areas.contains(city);
    }).toList();

    int newOrders = 0;
    int awaitingApproval = 0;
    int inVehicle = 0;

    for (var order in tourOrders) {
      final status = (order.data() as Map<String, dynamic>)['status'] ?? '';
      if (status == 'الطلبات الجديدة') {
        newOrders++;
      } else if (status == 'بانتظار موافقة السائق') {
        awaitingApproval++;
      } else if (status == 'في المركبة') {
        inVehicle++;
      }
    }

    if (tourOrders.isEmpty) {
      return const Center(
          child: Text('لا توجد طلبات اليوم',
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
                  if (awaitingApproval > 0)
                    PieChartSectionData(
                      color: Colors.orange,
                      value: awaitingApproval.toDouble(),
                      title: awaitingApproval.toString(),
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
                _buildSimpleLegend('الجديدة', Colors.blue, newOrders),
                const SizedBox(height: 4),
                _buildSimpleLegend(
                    'بانتظار الموافقة', Colors.orange, awaitingApproval),
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
    final citiesAndPlaces = appProvider.citiesAndPlaces;
    final drivers = appProvider.drivers;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إحصائيات وإدارة الجولات'),
          actions: [
            if (selectedTour != null)
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                onPressed: _clearForm,
                tooltip: 'إضافة جولة جديدة',
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
                // Right side - Tours List & Stats (Main area for web)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ملخص الجولات اليوم',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            // Global Search Field
                            Container(
                              width: 300,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: _globalTourSearchController,
                                style: const TextStyle(fontSize: 14),
                                onChanged: (value) {
                                  setState(() {
                                    _globalTourSearchQuery = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'بحث عن منطقة أو اسم جولة...',
                                  border: InputBorder.none,
                                  icon: Icon(Icons.search, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('tours')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const Center(
                                    child: CircularProgressIndicator());

                              var docs = snapshot.data!.docs;

                              if (_globalTourSearchQuery.isNotEmpty) {
                                docs = docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final name = (data['name'] ?? '').toString().toLowerCase();
                                  final areas = List<String>.from(data['areas'] ?? [])
                                      .map((e) => e.toLowerCase())
                                      .toList();
                                  final query = _globalTourSearchQuery.toLowerCase();

                                  bool nameMatch = name.contains(query);
                                  bool areaMatch = areas.any((area) => area.contains(query));
                                  
                                  return nameMatch || areaMatch;
                                }).toList();
                              }

                              if (docs.isEmpty) {
                                return const Center(
                                    child: Text('لا يوجد جولات مطابقة للبحث'));
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
                                  final areas =
                                      List<String>.from(data['areas'] ?? []);
                                  final isSelected = selectedTour?.id == doc.id;

                                  return Card(
                                    elevation: isSelected ? 4 : 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: isSelected
                                          ? BorderSide(
                                              color: Colors.blue, width: 2)
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
                                                        : Colors.blue,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            const Divider(height: 24),
                                            const Text('إحصائيات اليوم:',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                            const SizedBox(height: 8),
                                            _buildTourStats(areas, todayOrders),
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

                // Left side - Integration/Editing Form
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
                                    ? 'تعديل الجولة'
                                    : 'إنشاء جولة جديدة',
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
                            labelText: 'اسم الجولة',
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'هذا الحقل مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          CustomDropdown(
                            items:
                                drivers.map((d) => d.username ?? '').toList(),
                            value: selectedDriver?.username,
                            labelText: 'السائق المخصص',
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
                          const Text('تغطية المناطق',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          // Area Search Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _areaSearchController,
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) {
                                setState(() {
                                  _areaSearchQuery = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'بحث عن منطقة...',
                                border: InputBorder.none,
                                icon: Icon(Icons.search, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...citiesAndPlaces.where((city) {
                            if (_areaSearchQuery.isEmpty) return true;
                            bool cityMatches = city.name
                                .toLowerCase()
                                .contains(_areaSearchQuery.toLowerCase());
                            bool anyPlaceMatches = city.places.any((p) => p
                                .toLowerCase()
                                .contains(_areaSearchQuery.toLowerCase()));
                            return cityMatches || anyPlaceMatches;
                          }).map((city) {
                            final filteredPlaces = city.places.where((p) {
                              if (_areaSearchQuery.isEmpty) return true;
                              return p
                                      .toLowerCase()
                                      .contains(_areaSearchQuery.toLowerCase()) ||
                                  city.name
                                      .toLowerCase()
                                      .contains(_areaSearchQuery.toLowerCase());
                            }).toList();

                            final cityAreas = city.places
                                .map((p) => '${city.name} $p')
                                .toList();
                            final selectedCityAreas = selectedAreas
                                .where((a) => cityAreas.contains(a))
                                .toList();
                            final isAllSelected =
                                selectedCityAreas.length == cityAreas.length &&
                                    cityAreas.isNotEmpty;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: _areaSearchQuery.isNotEmpty,
                                title: Text(city.name,
                                    style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                    '${selectedCityAreas.length} منطقة (${filteredPlaces.length} ظاهر)',
                                    style: const TextStyle(fontSize: 11)),
                                leading: Checkbox(
                                  value: isAllSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        for (var area in cityAreas) {
                                          if (!selectedAreas.contains(area))
                                            selectedAreas.add(area);
                                        }
                                      } else {
                                        selectedAreas.removeWhere(
                                            (a) => cityAreas.contains(a));
                                      }
                                    });
                                  },
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: filteredPlaces.map((place) {
                                        final areaKey = '${city.name} $place';
                                        final isSelected =
                                            selectedAreas.contains(areaKey);
                                        return FilterChip(
                                          label: Text(place,
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          selected: isSelected,
                                          visualDensity: VisualDensity.compact,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected)
                                                selectedAreas.add(areaKey);
                                              else
                                                selectedAreas.remove(areaKey);
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _saveTour,
                            child: Text(
                                selectedTour != null
                                    ? 'تحديث بيانات الجولة'
                                    : 'إنشاء الجولة الآن',
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
