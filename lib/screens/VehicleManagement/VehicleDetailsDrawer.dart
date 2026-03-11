import 'package:flutter/material.dart';
import '../../models/Vehicle.dart';
import 'package:intl/intl.dart' as intel;
import '../../main.dart';

class VehicleDetailsDrawer extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailsDrawer({
    Key? key,
    required this.vehicle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تفاصيل المركبة',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildActionButtons(context),
                    const SizedBox(height: 24),
                    _buildDetailItem('الماركة', vehicle.brand),
                    _buildDetailItem('الموديل', vehicle.model),
                    _buildDetailItem('رقم اللوحة', vehicle.plateNumber),
                    _buildDetailItem('باركود المركبة', '#${vehicle.id}'),
                    _buildDetailItem('اسم السائق', vehicle.driverName ?? '-'),
                    _buildDetailItem('نوع المركبة', vehicle.vehicleType),
                    const Divider(height: 32),
                    _buildInsuranceInfo(),
                    const SizedBox(height: 16),
                    _buildLicenseInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.edit,
          label: 'تعديل',
          onPressed: () {
            // Handle edit action
          },
        ),
        _buildActionButton(
          icon: Icons.description_outlined,
          label: 'عدد الطرود',
          onPressed: () {
            // Handle packages count action
          },
        ),
        _buildActionButton(
          icon: Icons.print,
          label: 'طباعة',
          onPressed: () {
            // Handle print action
          },
        ),
        _buildActionButton(
          icon: Icons.delete,
          label: 'حذف المركبة',
          color: Colors.red,
          onPressed: () {
            // Handle delete action
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildInsuranceInfo() {
    final isExpired = vehicle.isInsuranceExpired;
    final endDate = vehicle.insuranceEndDate;
    final formattedDate =
        endDate != null ? intel.DateFormat('dd/MM/yyyy').format(endDate) : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isExpired ? Colors.red.withOpacity(0.1) : primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.warning : Icons.info_outline,
                color: isExpired ? Colors.red : primary,
              ),
              const SizedBox(width: 8),
              Text(
                isExpired ? 'انتهى تأمين المركبة' : 'تاريخ انتهاء التأمين',
                style: TextStyle(
                  color: isExpired ? Colors.red : primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(formattedDate),
        ],
      ),
    );
  }

  Widget _buildLicenseInfo() {
    final isExpired = vehicle.isLicenseExpired;
    final endDate = vehicle.licenseEndDate;
    final formattedDate =
        endDate != null ? intel.DateFormat('dd/MM/yyyy').format(endDate) : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withOpacity(0.1) : null,
        border: Border.all(
          color: isExpired ? Colors.red : Colors.grey.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.assignment_outlined,
                color: isExpired ? Colors.red : null,
              ),
              const SizedBox(width: 8),
              Text(
                isExpired ? 'انتهت رخصة المركبة' : 'تاريخ انتهاء الرخصة',
                style: TextStyle(
                  color: isExpired ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(formattedDate),
        ],
      ),
    );
  }
}
