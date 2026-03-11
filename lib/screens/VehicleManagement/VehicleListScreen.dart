import '../../main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/Vehicle.dart';

import 'AddVehicleDialog.dart';
import 'VehicleDetailsDrawer.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({Key? key}) : super(key: key);

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  String searchQuery = '';
  String? selectedVehicleType;
  String? selectedInsuranceStatus;

  Stream<List<Vehicle>> getVehiclesStream() {
    Query query = FirebaseFirestore.instance
        .collection('vehicles')
        .where('status', isEqualTo: 'active');

    if (searchQuery.isNotEmpty) {
      query =
          query.where('searchFields', arrayContains: searchQuery.toLowerCase());
    }

    if (selectedVehicleType != null) {
      query = query.where('vehicleType', isEqualTo: selectedVehicleType);
    }

    if (selectedInsuranceStatus != null) {
      DateTime now = DateTime.now();
      if (selectedInsuranceStatus == 'expired') {
        query =
            query.where('insuranceEndDate', isLessThan: now.toIso8601String());
      } else if (selectedInsuranceStatus == 'valid') {
        query = query.where('insuranceEndDate',
            isGreaterThan: now.toIso8601String());
      }
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vehicle.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({'status': VehicleStatus.deleted.toFirestore()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المركبة بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف المركبة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _buildVehicleList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    return StreamBuilder<List<Vehicle>>(
      stream: getVehiclesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final vehicles = snapshot.data ?? [];

        return SingleChildScrollView(
          controller: _verticalScrollController,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الماركة')),
              DataColumn(label: Text('الموديل')),
              DataColumn(label: Text('نوع الوقود')),
              DataColumn(label: Text('رقم اللوحة')),
              DataColumn(label: Text('نوع المركبة')),
              DataColumn(label: Text('اسم السائق')),
              DataColumn(label: Text('حالة التأمين')),
              DataColumn(label: Text('العمليات')),
            ],
            rows: vehicles.map((vehicle) {
              return DataRow(
                onSelectChanged: (_) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: VehicleDetailsDrawer(vehicle: vehicle),
                    ),
                  );
                },
                cells: [
                  DataCell(Text(vehicle.brand)),
                  DataCell(Text(vehicle.model)),
                  DataCell(Text(vehicle.fuelType)),
                  DataCell(Text(vehicle.plateNumber)),
                  DataCell(Text(vehicle.vehicleType)),
                  DataCell(Text(vehicle.driverName ?? '')),
                  DataCell(_buildInsuranceStatus(vehicle)),
                  DataCell(_buildOperations(vehicle)),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildInsuranceStatus(Vehicle vehicle) {
    final daysRemaining = vehicle.daysUntilInsuranceExpiry;
    if (daysRemaining == null) {
      return const Text('غير محدد', style: TextStyle(color: Colors.grey));
    }

    if (daysRemaining < 0) {
      return Text('منتهي منذ ${-daysRemaining} يوم',
          style: const TextStyle(color: Colors.red));
    }

    if (daysRemaining < 30) {
      return Text('ينتهي خلال $daysRemaining يوم',
          style: const TextStyle(color: primary));
    }

    return Text('ساري لمدة $daysRemaining يوم',
        style: const TextStyle(color: Color(0xFFDC2626)));
  }

  Widget _buildOperations(Vehicle vehicle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // TODO: Implement edit functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('تأكيد الحذف'),
                content: const Text('هل أنت متأكد من حذف هذه المركبة؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () {
                      deleteVehicle(vehicle.id);
                      Navigator.pop(context);
                    },
                    child: const Text('حذف'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddVehicleDialog(),
              );
            },
            child: const Text('أضف مركبة'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            hint: const Text('أنواع المركبات'),
            value: selectedVehicleType,
            items: const [
              DropdownMenuItem(value: null, child: Text('الكل')),
              DropdownMenuItem(value: 'شاحنة', child: Text('شاحنة')),
              DropdownMenuItem(value: 'سيارة', child: Text('سيارة')),
              DropdownMenuItem(value: 'دراجة', child: Text('دراجة')),
            ],
            onChanged: (value) {
              setState(() => selectedVehicleType = value);
            },
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            hint: const Text('حالة التأمين'),
            value: selectedInsuranceStatus,
            items: const [
              DropdownMenuItem(value: null, child: Text('الكل')),
              DropdownMenuItem(value: 'valid', child: Text('ساري')),
              DropdownMenuItem(value: 'expired', child: Text('منتهي')),
            ],
            onChanged: (value) {
              setState(() => selectedInsuranceStatus = value);
            },
          ),
        ],
      ),
    );
  }

// Rest of the code remains the same...
}
