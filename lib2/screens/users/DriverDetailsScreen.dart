import 'package:flutter/material.dart';
import '../../models/Driver.dart';
import '../../main.dart';

class DriverDetailsScreen extends StatelessWidget {
  final Driver driver;

  const DriverDetailsScreen({Key? key, required this.driver}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: 800, // Fixed width for web dialog
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'تفاصيل السائق: ${driver.username ?? ""}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: primary.withOpacity(0.2),
                          backgroundImage: driver.profileImage != null
                              ? NetworkImage(driver.profileImage!)
                              : null,
                          child: driver.profileImage == null
                              ? Icon(Icons.person, size: 50, color: primary)
                              : null,
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.username ?? 'غير محدد',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                driver.jobRole ?? 'سائق',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Contact Information Section
                    _buildSection(
                      title: 'معلومات الاتصال',
                      children: [
                        _buildInfoRow(Icons.email, 'البريد الإلكتروني',
                            driver.email ?? 'غير محدد'),
                        _buildInfoRow(Icons.phone, 'رقم الهاتف',
                            driver.phone ?? 'غير محدد'),
                        _buildInfoRow(Icons.location_on, 'العنوان',
                            driver.address ?? 'غير محدد'),
                        _buildInfoRow(Icons.location_city, 'العنوان التفصيلي',
                            driver.detailedAddress ?? 'غير محدد'),
                      ],
                    ),

                    // Work Information Section
                    _buildSection(
                      title: 'معلومات العمل',
                      children: [
                        _buildInfoRow(Icons.business, 'الشركة',
                            driver.company ?? 'غير محدد'),
                        _buildInfoRow(Icons.account_tree, 'الفرع',
                            driver.branch ?? 'غير محدد'),
                        _buildInfoRow(Icons.category, 'الفئة',
                            driver.category ?? 'غير محدد'),
                        // _buildInfoRow(Icons.credit_card, 'الرصيد النقدي',
                        //     '${driver.cashBalance?.toStringAsFixed(2) ?? "0.00"} ريال'),
                      ],
                    ),

                    // Permissions Section
                    _buildSection(
                      title: 'الصلاحيات',
                      children: [
                        _buildPermissionRow(
                            'السماح بتسليم الطرود', driver.allowDeliveryParcel),
                        _buildPermissionRow('السماح بالتسليم المتأخر',
                            driver.allowDelayedDelivery),
                        _buildPermissionRow(
                            'السماح بالمرتجعات', driver.allowReturns),
                        _buildPermissionRow(
                            'التسليم للمستودع', driver.deliverToWarehouse),
                        _buildPermissionRow(
                            'إخفاء معلومات السائق', driver.hideDriverInfo),
                        _buildPermissionRow(
                            'إخفاء معلومات المستلم', driver.hideRecipientInfo),
                        _buildPermissionRow(
                            'طلب التوقيع', driver.requireSignature),
                        _buildPermissionRow(
                            'السماح برفض السائق', driver.allowDriverRefuse),
                        _buildPermissionRow(
                            'إخفاء الباركود', driver.hideBarcode),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primary.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Color(0xFF4F46E5) : Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
