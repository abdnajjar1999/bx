import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/PrintHelper.dart';
import '../../models/Shipment.dart';
import 'package:uuid/uuid.dart';
import '../../services/billing/api_service.dart';
import '../../services/billing/user_preferences.dart';

class NationalBillingScreen extends StatefulWidget {
  const NationalBillingScreen({Key? key}) : super(key: key);

  @override
  State<NationalBillingScreen> createState() => _NationalBillingScreenState();
}

class _NationalBillingScreenState extends State<NationalBillingScreen> {
  List<Shipment> shipments = [];
  List<Shipment> filteredShipments = [];
  final TextEditingController _searchController = TextEditingController();

  // Selection
  Set<String> selectedShipmentIds = {};

  // Filters
  String _selectedTimeFilter =
      'all'; // all, today, yesterday, before_yesterday, last_week, last_month, custom
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterShipments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterShipments() {
    setState(() {
      filteredShipments = _getFilteredShipments(shipments);
    });
  }

  List<Shipment> _getFilteredShipments(List<Shipment> allShipments) {
    final query = _searchController.text.toLowerCase();

    return allShipments.where((shipment) {
      // 1. Check Date Filter
      if (!_matchesTimeFilter(shipment.createdAt)) {
        return false;
      }

      // 2. Check Search Query
      if (query.isEmpty) {
        return true;
      }

      return shipment.orderId.toLowerCase().contains(query) ||
          (shipment.username?.toLowerCase().contains(query) ?? false) ||
          (shipment.recipientName.toLowerCase().contains(query)) ||
          (shipment.phoneNumber.toLowerCase().contains(query));
    }).toList();
  }

  bool _matchesTimeFilter(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final beforeYesterday = today.subtract(const Duration(days: 2));
    final shipmentDate = DateTime(date.year, date.month, date.day);

    switch (_selectedTimeFilter) {
      case 'today':
        return shipmentDate == today;
      case 'yesterday':
        return shipmentDate == yesterday;
      case 'before_yesterday':
        return shipmentDate == beforeYesterday;
      case 'last_week':
        final lastWeek = today.subtract(const Duration(days: 7));
        return shipmentDate.isAfter(lastWeek) || shipmentDate == lastWeek;
      case 'last_month':
        final lastMonth = today.subtract(const Duration(days: 30));
        return shipmentDate.isAfter(lastMonth) || shipmentDate == lastMonth;
      case 'custom':
        if (_customDateRange == null) return true;
        return (date.isAfter(_customDateRange!.start) ||
                date.isAtSameMomentAs(_customDateRange!.start)) &&
            (date.isBefore(_customDateRange!.end) ||
                date.isAtSameMomentAs(_customDateRange!.end));
      case 'all':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('فوتره الوطنيه'),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'تم توصيلها')
              .where('isSentToFaotara', isNotEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: SelectableText('Error: ${snapshot.error}'));
            }

            final localShipments = snapshot.data?.docs
                    .map((doc) =>
                        Shipment.fromMap(doc.data() as Map<String, dynamic>))
                    .toList() ??
                [];

            // Sort locally
            localShipments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Apply current filters
            final localFiltered = _getFilteredShipments(localShipments);

            // Update member variables safely for button actions
            // Using postFrameCallback to avoid build-phase state updates
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                shipments = localShipments;
                filteredShipments = localFiltered;
              }
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTableHeader(localFiltered),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DataTable(
                          onSelectAll: (value) {
                            setState(() {
                              if (value!) {
                                selectedShipmentIds.addAll(
                                    localFiltered.map((s) => s.orderId));
                              } else {
                                selectedShipmentIds.clear();
                              }
                            });
                          },
                          columns: _createColumns(),
                          rows: _createRows(localFiltered),
                          columnSpacing: 15,
                          horizontalMargin: 10,
                          headingRowHeight: 40,
                          dataRowHeight: 45,
                          border: TableBorder(
                            horizontalInside:
                                BorderSide(color: Colors.grey.shade300),
                            verticalInside:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildTableFooter(localFiltered),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableHeader(List<Shipment> currentFiltered) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Time Filter
          PopupMenuButton<String>(
            initialValue: _selectedTimeFilter,
            onSelected: (value) async {
              if (value == 'custom') {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _customDateRange = picked;
                    _selectedTimeFilter = value;
                    _filterShipments();
                  });
                }
              } else {
                setState(() {
                  _selectedTimeFilter = value;
                  _filterShipments();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  Text(_getTimeFilterLabel(_selectedTimeFilter)),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('الكل')),
              const PopupMenuItem(value: 'today', child: Text('اليوم')),
              const PopupMenuItem(value: 'yesterday', child: Text('أمس')),
              const PopupMenuItem(
                  value: 'before_yesterday', child: Text('قبل أمس')),
              const PopupMenuItem(value: 'last_week', child: Text('قبل أسبوع')),
              const PopupMenuItem(value: 'last_month', child: Text('قبل شهر')),
              const PopupMenuItem(value: 'custom', child: Text('مخصص...')),
            ],
          ),
          const SizedBox(width: 8),
          // Send Selected Button
          if (selectedShipmentIds.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                final selectedInfo = currentFiltered
                    .where((s) => selectedShipmentIds.contains(s.orderId))
                    .toList();
                _sendToBilling(selectedInfo);
              },
              icon: const Icon(Icons.send_to_mobile),
              label:
                  Text('ارسال المحدد لفوتره (${selectedShipmentIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          if (selectedShipmentIds.isNotEmpty) const SizedBox(width: 8),

          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Center(child: Text('عامل التصفية')),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'بحث (رقم الشحنة، المرسل، المستلم)...',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _getTimeFilterLabel(String filter) {
    switch (filter) {
      case 'today':
        return 'اليوم';
      case 'yesterday':
        return 'أمس';
      case 'before_yesterday':
        return 'قبل أمس';
      case 'last_week':
        return 'قبل أسبوع';
      case 'last_month':
        return 'قبل شهر';
      case 'custom':
        return 'مخصص';
      case 'all':
      default:
        return 'الكل';
    }
  }

  Future<void> _sendToBilling(List<Shipment> targetShipments) async {
    if (targetShipments.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإرسال لفوتره'),
        content: Text(
            'هل أنت متأكد من إرسال ${targetShipments.length} شحنة إلى الفوترة الوطنية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final apiService = ApiService();
      final activity = await UserPreferences.getActivity() ?? '';
      final uuid = Uuid();

      try {
        // Get next invoice number
        final nextInvResponse = await apiService.getNextInvoiceNumber();
        print(nextInvResponse);
        final String invoiceNumber = nextInvResponse['invoiceNumber'];
        print(invoiceNumber);
        final invoiceDate = DateTime.now();

        // Build invoice items list from all shipments
        List<Map<String, dynamic>> invoiceItems = [];
        double totalSubtotal = 0.0;
        double totalTaxAmount = 0.0;
        double taxRate = 16.0;

        for (var shipment in targetShipments) {
          // Calculate for each shipment
          double itemSubtotal =
              double.parse(shipment.deliveryCost.toStringAsFixed(3));
          double itemTaxAmount =
              double.parse((itemSubtotal * (taxRate / 100)).toStringAsFixed(3));
          double itemTotalAmount =
              double.parse((itemSubtotal + itemTaxAmount).toStringAsFixed(3));

          // Add to invoice items list
          invoiceItems.add({
            "invoiceItemType": "SERVICE_CHARGE",
            "productDescription": "Delivery Fee - ${shipment.orderId}",
            "quantity": 1.000,
            "unitPrice": itemSubtotal,
            "customerPrice": itemSubtotal,
            "subtotalAmount": itemSubtotal,
            "discountAmount": 0.000,
            "totalAmountAfterDiscount": itemSubtotal,
            "generalTaxAmount": itemTaxAmount,
            "totalAmountAfterTaxes": itemTotalAmount,
            "specialTaxAmount": 0.000,
            "uuid": uuid.v4(),
            "generalTaxPercentage": taxRate,
            "generalTaxType": "SIXTEEN",
          });

          // Accumulate totals
          totalSubtotal += itemSubtotal;
          totalTaxAmount += itemTaxAmount;
        }

        // Round final totals to 3 decimal places
        totalSubtotal = double.parse(totalSubtotal.toStringAsFixed(3));
        totalTaxAmount = double.parse(totalTaxAmount.toStringAsFixed(3));
        double totalPayableAmount =
            double.parse((totalSubtotal + totalTaxAmount).toStringAsFixed(3));

        final invoiceData = {
          "invoiceTypeCode": "CASH_GENERAL_TAX",
          "invoiceNumber": invoiceNumber,
          "buyerInvoiceNumber": "",
          "issueDate":
              "${invoiceDate.day.toString().padLeft(2, '0')}-${invoiceDate.month.toString().padLeft(2, '0')}-${invoiceDate.year}",
          "invoiceKind": "LOCAL",
          "currencyEnum": "JOD",
          "notes": "",
          "buyerDTO": null,
          "activityDTO": {"activity": activity},
          "totalAmountExcludingTaxes": totalSubtotal,
          "totalDiscountsAmount": 0.000,
          "totalGeneralTaxesAmount": totalTaxAmount,
          "totalSpecialTaxAmount": 0.000,
          "totalWithSpecialTaxAmount": totalSubtotal,
          "totalPayableAmount": totalPayableAmount,
          "invoiceItemDTOList": invoiceItems,
        };

        final response = await apiService.submitInvoice(invoiceData);

        if (response['invoiceNumber'] != null) {
          // Update all shipments in Firestore
          final batch = FirebaseFirestore.instance.batch();
          for (var shipment in targetShipments) {
            final docRef = FirebaseFirestore.instance
                .collection('orders')
                .doc(shipment.orderId);
            batch.update(docRef, {'isSentToFaotara': true});
          }
          await batch.commit();

          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'تم إرسال ${targetShipments.length} شحنة بنجاح في فاتورة واحدة')),
          );
        } else {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل إرسال الفاتورة')),
          );
        }
      } catch (e) {
        print('Error sending invoice: $e');
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }

      setState(() {
        selectedShipmentIds.clear();
      });
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ عام: $e')),
      );
    }
  }

  List<DataColumn> _createColumns() {
    return [
      // DataColumn(
      //   label: Checkbox(
      //     value: filteredShipments.isNotEmpty &&
      //         filteredShipments
      //             .every((s) => selectedShipmentIds.contains(s.orderId)),
      //     onChanged: (value) {
      //   ),
      // ),
      const DataColumn(label: Text('رقم الشحنة', textAlign: TextAlign.center)),
      const DataColumn(label: Text('المرسل', textAlign: TextAlign.center)),
      const DataColumn(label: Text('المستلم', textAlign: TextAlign.center)),
      const DataColumn(label: Text('المدينة', textAlign: TextAlign.center)),
      const DataColumn(label: Text('التاريخ', textAlign: TextAlign.center)),
      const DataColumn(label: Text('حوزة النقد', textAlign: TextAlign.center)),
      const DataColumn(label: Text('سعر التوصيل', textAlign: TextAlign.center)),
      const DataColumn(
          label: Text('المبلغ (COD)', textAlign: TextAlign.center)),
      const DataColumn(
          label: Text('إجمالي المبلغ', textAlign: TextAlign.center)),
      const DataColumn(label: Text('إجراءات', textAlign: TextAlign.center)),
    ];
  }

  List<DataRow> _createRows(List<Shipment> currentFiltered) {
    return currentFiltered.map((shipment) {
      final isSelected = selectedShipmentIds.contains(shipment.orderId);
      final isSent = shipment.isSentToFaotara;

      return DataRow(
        selected: isSelected,
        color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (isSent) return Colors.green.withOpacity(0.1);
          return null;
        }),
        onSelectChanged: (value) {
          setState(() {
            if (value == true) {
              selectedShipmentIds.add(shipment.orderId);
            } else {
              selectedShipmentIds.remove(shipment.orderId);
            }
          });
        },
        cells: [
          DataCell(Text(shipment.orderId)),
          DataCell(Text(shipment.username ?? '-')),
          DataCell(Text(shipment.recipientName)),
          DataCell(Text(shipment.city)),
          DataCell(Text(
              '${shipment.createdAt.day}/${shipment.createdAt.month}/${shipment.createdAt.year}')),
          DataCell(Text(shipment.cashPossession.nameAr)),
          DataCell(Text(shipment.deliveryCost.toStringAsFixed(3))),
          DataCell(Text(shipment.codAmount.toStringAsFixed(3))),
          DataCell(Text((shipment.codAmount).toStringAsFixed(3))),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isSent)
                  IconButton(
                    icon:
                        const Icon(Icons.send, size: 20, color: Colors.orange),
                    onPressed: () => _sendToBilling([shipment]),
                    tooltip: 'ارسال لفوتره',
                  )
                else
                  const Icon(Icons.check_circle, size: 20, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.print, size: 20, color: Colors.blue),
                  onPressed: () {
                    PrintHandler().printShipmentsDocument([shipment]);
                  },
                  tooltip: 'طباعة',
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildTableFooter(List<Shipment> currentFiltered) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Text(
              'إجمالي التحصيلات: JOD ${_calculateTotalCollections(currentFiltered).toStringAsFixed(3)}'),
          const Spacer(),
          Text('عدد الشحنات: ${currentFiltered.length}'),
        ],
      ),
    );
  }

  double _calculateTotalCollections(List<Shipment> currentFiltered) {
    return currentFiltered.fold(
      0.0,
      (sum, item) => sum + item.codAmount,
    );
  }
}
