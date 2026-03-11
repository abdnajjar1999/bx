import '../../main.dart';
import '../../models/Driver.dart';
import '../../models/DriverDeliveryData.dart';
import '../../shared/PrintHelper.dart';
import '../../shared/firebaseHelper.dart';
import '../../shared/appProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class FinancialSettlementsDialog extends StatefulWidget {
  final DriverDeliveryData driverData;
  const FinancialSettlementsDialog({Key? key, required this.driverData})
      : super(key: key);

  @override
  State<FinancialSettlementsDialog> createState() =>
      _FinancialSettlementsDialogState();
}

class _FinancialSettlementsDialogState
    extends State<FinancialSettlementsDialog> {
  bool isPrintReport = false;
  bool isLoading = false;
  String? selectedExpenseType;
  String? selectedPaymentMethod;
  final TextEditingController transportFeeController = TextEditingController();
  final TextEditingController receivedAmountController =
      TextEditingController();
  final TextEditingController expensesController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController documentNumberController =
      TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  Driver? selectedDriver;

  @override
  void initState() {
    super.initState();
    // Initialize the received amount with the expected total
    receivedAmountController.text =
        widget.driverData.totalCollections.toStringAsFixed(2);
    selectedDriver = Provider.of<AppProvider>(context, listen: false)
        .drivers
        .firstWhere(
            (driver) => driver.username == widget.driverData.driverName);
  }

  @override
  void dispose() {
    receivedAmountController.dispose();
    expensesController.dispose();
    notesController.dispose();
    documentNumberController.dispose();
    transportFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildContent(),
            const SizedBox(height: 24),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'المقبوضات المالية',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expected Collections
          Text(
            'التحصيلات المتوقعة: ${widget.driverData.totalCollections.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
          //total price
          Text(
            'السعر الإجمالي: ${widget.driverData.price.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
          if(widget.driverData.driverPrice > 0)
            Text(
              'نصيب السائق: ${widget.driverData.driverPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),

          //driver share from total price
          if (selectedDriver != null &&
              selectedDriver!.driverShare != null &&
              selectedDriver!.driverShare != 0)
            Text(
              'نصيب السائق (${selectedDriver!.driverShare}%) : ${widget.driverData.price * (selectedDriver!.driverShare ?? 0) / 100}',
              style: TextStyle(fontSize: 16),
            ),

          const SizedBox(height: 16),
          TextField(
            controller: receivedAmountController,
            decoration: InputDecoration(
              label: Text('التحصيلات المستلمة *'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: documentNumberController,
            decoration: InputDecoration(
              labelText: 'رقم الوثيقة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedPaymentMethod,
            decoration: InputDecoration(
              label: Text('الحساب'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              ...Provider.of<AppProvider>(context, listen: false)
                  .bankAccounts
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
            ],
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Expense Type Dropdown and amount - only show if amount doesn't match expected
          if (receivedAmountController.text.isNotEmpty &&
              (double.tryParse(receivedAmountController.text) ?? 0) !=
                  widget.driverData.totalCollections) ...[
            DropdownButtonFormField<String>(
              value: selectedExpenseType,
              decoration: InputDecoration(
                label: Text('نوع المصروف *'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                ...Provider.of<AppProvider>(context, listen: false)
                    .expenseTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedExpenseType = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: expensesController,
              decoration: InputDecoration(
                label: Text('المصاريف *'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],

          // Image attachment
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                if (_imageFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'ملاحظات (اختياري)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),

          // Print Report Switch
          Row(
            children: [
              const Text('طباعة تقرير الاستلام'),
              const Spacer(),
              Switch(
                value: isPrintReport,
                onChanged: (value) {
                  setState(() {
                    isPrintReport = value;
                  });
                },
                activeColor: primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(isLoading ? 'جاري المعالجة...' : 'تأكيد'),
          onPressed: isLoading
              ? null
              : () async {
                  // Validate required fields
                  if (receivedAmountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('يجب إدخال التحصيلات المستلمة')),
                    );
                    return;
                  }

                  double receivedAmount =
                      double.tryParse(receivedAmountController.text) ?? 0;
                  bool amountsMatch =
                      receivedAmount == widget.driverData.totalCollections;

                  // If amounts don't match, require expenses and expense type
                  if (!amountsMatch) {
                    if (expensesController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'يجب إدخال المصاريف عندما تكون التحصيلات المستلمة مختلفة عن المتوقعة')),
                      );
                      return;
                    }

                    if (selectedExpenseType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يجب اختيار نوع المصروف')),
                      );
                      return;
                    }
                  }

                  setState(() {
                    isLoading = true;
                  });
                  try {
                    // Update delivery data with payment details
                    DriverDeliveryData updatedDriverData =
                        widget.driverData.copyWith(
                      paymentMethod: selectedPaymentMethod,
                      documentNumber: documentNumberController.text,
                      notes: notesController.text,
                      paymentDate: DateTime.now(),
                    );
                    print("done beforeprinting");

                    // Generate PDF and get URL
                    final String? pdfUrl = await PrintHandler()
                        .printDriverDeliveryDataDocument(updatedDriverData,
                            isDownload: true);
                    print("done printing");

                    // Update with PDF URL
                    updatedDriverData =
                        updatedDriverData.copyWith(pdfUrl: pdfUrl);

                    // Save the receipt invoice
                    FirebaseHelper()
                        .saveDriverReceiptInvoice(updatedDriverData);
                    if (selectedPaymentMethod != null) {
                      FirebaseHelper().addTransfer({
                        'type': "إيداع",
                        'account': selectedPaymentMethod,
                        'amount': receivedAmount,
                        'notes':
                            "سند قبض من السائق ${widget.driverData.driverName}",
                        'date': DateTime.now().toIso8601String(),
                      });
                    }

                    // Only add expense if there is an expense amount entered
                    if (!amountsMatch) {
                      FirebaseHelper().addExpense({
                        'type': selectedExpenseType,
                        'beneficiary': widget.driverData.driverName ?? '',
                        'amount': double.parse(expensesController.text),
                        'notes': notesController.text,
                        'branch': KcompanyName,
                      });
                    }

                    // Print receipt if requested
                    if (isPrintReport) {
                      PrintHandler()
                          .printDriverDeliveryDataDocument(updatedDriverData);
                    }

                    // Process the transaction
                    await FirebaseHelper()
                        .receiveOrdersFromDriver(widget.driverData);

                    // Add transfer record

                    Navigator.of(context).pop(true);
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('خطأ'),
                        content: Text('حدث خطأ: ${e.toString()}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('حسناً'),
                          ),
                        ],
                      ),
                    );
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
