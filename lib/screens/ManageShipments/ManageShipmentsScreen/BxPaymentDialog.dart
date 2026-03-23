import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/appProvider.dart';
import '../../../models/Shipment.dart';
import '../../../models/UserAccount.dart';
import '../../../main.dart'; // For primary color

class BxPaymentDialog extends StatefulWidget {
  final Shipment? order;
  final UserAccount? userAccount;
  const BxPaymentDialog({Key? key, this.order, this.userAccount})
      : super(key: key);

  @override
  State<BxPaymentDialog> createState() => _BxPaymentDialogState();
}

class _BxPaymentDialogState extends State<BxPaymentDialog> {
  String? selectedPaymentMethod;
  bool _isLoading = false;

  Future<void> _handlePayment(AppProvider appProvider) async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار طريقة الدفع')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.userAccount != null) {
        // 1. Update the order status for company delivery fee
        for (var shipment in widget.userAccount!.shipments) {
          if (!shipment.isCompanyDeliveryFeePaid) {
            await appProvider.updateIsCompanyDeliveryFeePaid(shipment, true);
          }
        }

        // 2. Add the transfer transaction to 'حساب المبيعات'
        double amountToPay = -widget.userAccount!.getAmountToPay();
        if (amountToPay > 0) {
          await appProvider.addTransfer({
            'type': 'إيداع',
            'account': selectedPaymentMethod,
            'otherAccount': 'المبيعات',
            'otherAccountCategory': 'ايرادات',
            'amount': amountToPay,
            'notes': "واصل bx للزبون ${widget.userAccount!.client}",
            'date': DateTime.now().toIso8601String(),
            'relatedTo': widget.userAccount!.id,
          });
        }
      } else if (widget.order != null) {
        // 1. Update the order status for company delivery fee
        await appProvider.updateIsCompanyDeliveryFeePaid(widget.order!, true);

        // 2. Add the transfer transaction to 'حساب المبيعات'
        if (widget.order!.deliveryCost > 0) {
          await appProvider.addTransfer({
            'type': 'إيداع',
            'account': selectedPaymentMethod,
            'otherAccount': 'المبيعات',
            'otherAccountCategory': 'ايرادات',
            'amount': widget.order!.deliveryCost.toDouble(),
            'notes': "واصل bx للطلب ${widget.order!.trackingNumber}",
            'date': DateTime.now().toIso8601String(),
            'relatedTo': widget.order!.orderId,
          });
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الدفع بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    'اختر طريقة الدفع لواصل bx',
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
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'المبلغ المطلوب: ${widget.order != null ? widget.order!.deliveryCost : (-widget.userAccount!.getAmountToPay()).toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.indigo),
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
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
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
