import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../main.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsScreen({Key? key, required this.customer})
      : super(key: key);

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
                    'تفاصيل الزبون: ${customer.username}',
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
                          backgroundImage: customer.profileImage.isNotEmpty
                              ? NetworkImage(customer.profileImage)
                              : null,
                          child: customer.profileImage.isEmpty
                              ? Icon(Icons.person, size: 50, color: primary)
                              : null,
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.username,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'زبون',
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
                        _buildInfoRow(
                            Icons.email, 'البريد الإلكتروني', customer.email),
                        _buildInfoRow(
                            Icons.phone, 'رقم الهاتف', customer.phoneNumber),
                        _buildInfoRow(
                            Icons.location_on, 'العنوان', customer.address),
                        _buildInfoRow(Icons.location_city, 'المدينة',
                            customer.city ?? 'غير محدد'),
                      ],
                    ),

                    // Financial Information Section
                    _buildSection(
                      title: 'المعلومات المالية',
                      children: [
                        _buildInfoRow(
                          Icons.account_balance_wallet,
                          'الرصيد النقدي',
                          '${customer.cashBalance?.toStringAsFixed(2) ?? "0.00"} دينار',
                        ),
                      ],
                    ),

                    // Permissions Section
                    _buildSection(
                      title: 'الإعدادات والصلاحيات',
                      children: [
                        _buildPermissionRow(
                          'السماح بتعديل المشرف',
                          customer.allowAdminModification ?? false,
                        ),
                        _buildPermissionRow(
                          'السماح بتعديل المشرفين الآخرين',
                          customer.allowOtherAdminsModification ?? false,
                        ),
                        _buildPermissionRow(
                          'إظهار السعر في التطبيق',
                          customer.showPriceInApp ?? false,
                        ),
                        _buildPermissionRow(
                          'إظهار السائق في التطبيق',
                          customer.showDriverInApp ?? false,
                        ),
                        _buildPermissionRow(
                          'إظهار العنوان في التطبيق',
                          customer.showAddressInApp ?? false,
                        ),
                        _buildPermissionRow(
                          'إظهار رقم الهاتف في التطبيق',
                          customer.showPhoneInApp ?? false,
                        ),
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
            color: value ? Color(0xFFDC2626) : Colors.red,
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
