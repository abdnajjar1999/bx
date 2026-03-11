import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/Shipment.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import '../../shared/PrintHelper.dart';

class BundledShipmentsScreen extends StatefulWidget {
  const BundledShipmentsScreen({Key? key}) : super(key: key);

  @override
  _BundledShipmentsScreenState createState() => _BundledShipmentsScreenState();
}

class _BundledShipmentsScreenState extends State<BundledShipmentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, List<Shipment>> _bundles = {};
  final Map<String, bool> _deletingBundle = {};
  final Map<String, Set<String>> _deletingShipments = {};

  @override
  void initState() {
    super.initState();
    _fetchBundledShipments();
  }

  Future<void> _fetchBundledShipments() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all shipments that have a bundleId
      final querySnapshot = await _firestore
          .collection('orders')
          .where('bundleId', isNotEqualTo: null)
          .get();

      // Group shipments by bundleId
      final Map<String, List<Shipment>> bundles = {};
      
      for (var doc in querySnapshot.docs) {
        try {
          final shipment = Shipment.fromMap(doc.data());
          final bundleId = doc.data()['bundleId'] as String?;
          
          if (bundleId != null) {
            if (!bundles.containsKey(bundleId)) {
              bundles[bundleId] = [];
            }
            bundles[bundleId]!.add(shipment);
          }
        } catch (e) {
          print('Error processing document ${doc.id}: $e');
        }
      }

      setState(() {
        _bundles = bundles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bundled shipments: $e');
      setState(() => _isLoading = false);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل الحزم المجمعة: $e')),
      );
    }
  }

  double _calculateTotalWeight(List<Shipment> shipments) {
    return shipments.fold(0, (sum, shipment) => sum + (shipment.weight ?? 0));
  }

  double _calculateTotalCost(List<Shipment> shipments) {
    return shipments.fold(0, (sum, shipment) => sum + (shipment.deliveryCost ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إدارة الحزم المجمعة',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchBundledShipments,
                tooltip: 'تحديث',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bundles.isEmpty
                    ? const Center(child: Text('لا توجد حزم مجمعة حالياً'))
                    : ListView.builder(
                  itemCount: _bundles.length,
                  itemBuilder: (context, index) {
                    final bundleId = _bundles.keys.elementAt(index);
                    final shipments = _bundles[bundleId]!;
                    final totalWeight = _calculateTotalWeight(shipments);
                    final totalCost = _calculateTotalCost(shipments);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ExpansionTile(
                        title: Text(
                          'الحزمة ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'عدد الطرود: ${shipments.length} | الوزن الإجمالي: ${totalWeight.toStringAsFixed(2)} كجم',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () {
                            PrintHandler().printShipmentsDocument(shipments, bundleId: bundleId);
                          },
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                                                
                                    _buildInfoRow('عدد الطرود:', shipments.length.toString()),
                                    _buildInfoRow('الوزن الإجمالي:', '${totalWeight.toStringAsFixed(2)} كجم'),
                                    _buildInfoRow('التكلفة الإجمالية:', '${totalCost.toStringAsFixed(2)} دينار'),
                                    const SizedBox(height: 10),
                                      ]),
                                      Spacer(),
                                               SizedBox(
                                        height: 120,
                                        width: 120,
                                        child: SfBarcodeGenerator(
                                          value: bundleId,
                                          symbology:QRCode() ,
                                          showValue: false,
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'تفاصيل الطرود:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (shipments.length > 1)
                                      TextButton.icon(
                                        icon: _deletingBundle[bundleId] == true
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.delete_forever, color: Colors.red, size: 16),
                                        label: const Text('حذف الحزمة', style: TextStyle(color: Colors.red)),
                                        onPressed: _deletingBundle[bundleId] == true
                                            ? null
                                            : () async {
                                                final shouldDelete = await showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text('تأكيد الحذف'),
                                                      content: const Text('هل أنت متأكد من حذف هذه الحزمة بالكامل؟ سيتم إزالة الحزمة ولكن الشحنات ستبقى في النظام.'),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(false),
                                                          child: const Text('إلغاء'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(true),
                                                          child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                if (shouldDelete == true) {
                                                  _deleteEntireBundle(bundleId);
                                                }
                                              },
                                      ),
                                  ],
                                ),
                                const Divider(),
                                ...shipments.map((shipment) => Dismissible(
                                  key: Key(shipment.orderId),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('تأكيد الحذف'),
                                          content: const Text('هل أنت متأكد من حذف هذه الشحنة من الحزمة؟'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('إلغاء'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    // Add to deleting set
                                    if (!_deletingShipments.containsKey(bundleId)) {
                                      _deletingShipments[bundleId] = {};
                                    }
                                    _deletingShipments[bundleId]!.add(shipment.orderId);
                                    
                                    try {
                                      // Remove bundleId from the shipment
                                      await _firestore
                                          .collection('orders')
                                          .doc(shipment.orderId)
                                          .update({'bundleId': FieldValue.delete()});
                                      
                                      // Refresh the list
                                      _fetchBundledShipments();
                                      
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('تم حذف الشحنة من الحزمة')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('خطأ في حذف الشحنة: $e')),
                                        );
                                      }
                                      // Refresh to restore the UI in case of error
                                      _fetchBundledShipments();
                                    } finally {
                                      _deletingShipments[bundleId]?.remove(shipment.orderId);
                                    }
                                  },
                                  child: ListTile(
                                    title: Text(
                                      shipment.orderId.isNotEmpty 
                                          ? 'رقم الشحنة: ${shipment.orderId}'
                                          : 'غير محدد',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('المرسل إليه: ${shipment.recipientName.isNotEmpty ? shipment.recipientName : 'غير محدد'}'),
                                        Text('رقم الجوال: ${shipment.phoneNumber.isNotEmpty ? shipment.phoneNumber : 'غير محدد'}'),
                                        Text('المدينة: ${shipment.city.isNotEmpty ? shipment.city : 'غير محدد'}'),
                                        Text('الوزن: ${(shipment.weight ?? 0).toStringAsFixed(2)} كجم'),
                                        Text('التكلفة: ${(shipment.deliveryCost ?? 0).toStringAsFixed(2)} دينار'),
                                      ],
                                    ),
                                    trailing: _deletingShipments[bundleId]?.contains(shipment.orderId) == true
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : null,
                                  ),
                                )).toList(),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _deleteEntireBundle(String bundleId) async {
    if (_deletingBundle[bundleId] == true) return;
    
    setState(() {
      _deletingBundle[bundleId] = true;
    });

    try {
      // Get all shipments in this bundle
      final querySnapshot = await _firestore
          .collection('orders')
          .where('bundleId', isEqualTo: bundleId)
          .get();

      // Create a batch to update all documents
      final batch = _firestore.batch();
      
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'bundleId': FieldValue.delete()});
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحزمة بنجاح')),
        );
      }
      
      // Refresh the list
      _fetchBundledShipments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف الحزمة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingBundle.remove(bundleId);
        });
      }
    }
  }
}
