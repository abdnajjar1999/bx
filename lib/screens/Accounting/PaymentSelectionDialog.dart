import '../../main.dart';
import '../../shared/appProvider.dart';
import '../../shared/firebaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../models/UserAccount.dart';
import '../../shared/PrintHelper.dart';

class PaymentSelectionDialog extends StatefulWidget {
  final UserAccount userAccount;
  const PaymentSelectionDialog({Key? key, required this.userAccount})
      : super(key: key);

  @override
  State<PaymentSelectionDialog> createState() => _PaymentSelectionDialogState();
}

class _PaymentSelectionDialogState extends State<PaymentSelectionDialog> {
  String? selectedPaymentMethod;
  bool isPrintDeliveryReport = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _documentNumberController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _documentNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_imageFile == null) return null;

    try {
      final String fileName =
          'payments/${widget.userAccount.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_imageFile!.path)}';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(_imageFile!);
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _handlePayment(AppProvider appProvider) async {
    // if (selectedPaymentMethod == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('الرجاء اختيار طريقة الدفع')),
    //   );
    //   return;
    // }

    // if (_documentNumberController.text.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('الرجاء إدخال رقم الوثيقة')),
    //   );
    //   return;
    // }

    setState(() => _isLoading = true);

    try {
      final String? imageUrl = await _uploadImageToFirebase();
      final String? pdfUrl = await PrintHandler()
          .printUserAccountDocument(widget.userAccount, isDownload: true);

      // Update user account with payment details
      widget.userAccount.paymentMethod = selectedPaymentMethod;
      widget.userAccount.documentNumber = _documentNumberController.text;
      widget.userAccount.notes = _notesController.text;
      widget.userAccount.paymentImageUrl = imageUrl;
      widget.userAccount.paymentDate = DateTime.now();
      widget.userAccount.pdfUrl = pdfUrl;

      String invoiceId = await FirebaseHelper().payOrdersToCustomer(widget.userAccount);
      if (selectedPaymentMethod != null && widget.userAccount.getAmountToPay() > 0) {
        appProvider.addTransfer({
          'type': "سحب",
          'account': selectedPaymentMethod,
          'otherAccount': widget.userAccount.client,
          'otherAccountCategory': 'جاري العملاء',
          'amount': widget.userAccount.getAmountToPay(),
          'notes': "سند دفع للعميل ${widget.userAccount.client}",
          'date': DateTime.now().toIso8601String(),
          'relatedTo': invoiceId,
        });
      }

      if (isPrintDeliveryReport) {
        await PrintHandler().printUserAccountDocument(widget.userAccount);
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'اختر نوع الدفع',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (var paymentMethod in appProvider.bankAccounts)
                    _buildPaymentButton(paymentMethod, paymentMethod),
                ],
              ),
              const SizedBox(height: 24),
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
                        child: Image.network(
                          _imageFile!.path,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('اختر صورة من المعرض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                          });
                        },
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          'حذف الصورة',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _documentNumberController,
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
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('طباعة تقرير التوصيل'),
                value: isPrintDeliveryReport,
                onChanged: (value) {
                  setState(() {
                    isPrintDeliveryReport = value;
                  });
                },
                activeColor: primary,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : () => _handlePayment(appProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('تأكيد الدفع'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String label, String value) {
    final isSelected = selectedPaymentMethod == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primary : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: isSelected ? primary : Colors.grey[300]!),
      ),
      child: Text(label),
    );
  }
}
