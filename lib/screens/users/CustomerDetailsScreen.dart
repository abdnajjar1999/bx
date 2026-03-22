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
                              Row(
                                children: [
                                  _buildBadge(
                                    _getCustomerTypeLabel(
                                        customer.customerType),
                                    Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  _buildBadge(
                                    customer.status,
                                    customer.status == 'نشط'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Contact Information Section
                    _buildSection(
                      title: 'معلومات الاتصال والهوية',
                      children: [
                        _buildInfoRow(
                            Icons.email, 'البريد الإلكتروني', customer.email),
                        _buildInfoRow(
                            Icons.phone, 'رقم الهاتف', customer.phoneNumber),
                        _buildInfoRow(Icons.badge, 'الرقم الوطني',
                            customer.nationalId ?? 'غير متوفر'),
                        _buildInfoRow(Icons.location_on, 'العنوان الرئيسي',
                            customer.address),
                        _buildInfoRow(Icons.location_city, 'المدينة',
                            customer.city ?? 'غير محدد'),
                        if (customer.promotionalName != null &&
                            customer.promotionalName!.isNotEmpty)
                          _buildInfoRow(Icons.star, 'الاسم',
                              customer.promotionalName!),
                      ],
                    ),

                    // Loyalty and Rating Section
                    _buildSection(
                      title: 'النقاط والتقييم',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                Icons.favorite,
                                'نقاط الولاء',
                                customer.loyaltyPoints.toStringAsFixed(0),
                              ),
                            ),
                            Expanded(
                              child: _buildInfoRow(
                                Icons.star,
                                'التقييم الحالي',
                                '${customer.userRating.toStringAsFixed(1)} (${customer.ratingCount} تقييم)',
                              ),
                            ),
                          ],
                        ),
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

                    // Verification Status Section
                    _buildSection(
                      title: 'التوثيق وحالة الحساب',
                      children: [
                        _buildVerificationRow(
                          'توثيق الهوية',
                          customer.isIdVerified,
                        ),
                        _buildVerificationRow(
                          'التوثيق التجاري',
                          customer.isCommercialVerified,
                        ),
                        _buildVerificationRow(
                          'توثيق الهاتف',
                          customer.isPhoneVerified,
                        ),
                      ],
                    ),

                    // Saved Addresses Section
                    if (customer.savedAddresses.isNotEmpty)
                      _buildSection(
                        title: 'العناوين المحفوظة',
                        children: customer.savedAddresses
                            .map((addr) => _buildInfoRow(
                                  Icons.bookmark_border,
                                  addr.address,
                                  '${addr.latitude.toStringAsFixed(4)}, ${addr.longitude.toStringAsFixed(4)}',
                                ))
                            .toList(),
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
            color: value ? Colors.green : Colors.red,
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

  Widget _buildVerificationRow(String label, bool value) {
    return _buildPermissionRow(label, value);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getCustomerTypeLabel(CustomerType type) {
    switch (type) {
      case CustomerType.passenger:
        return 'مسافر';
      case CustomerType.restaurant:
        return 'مطعم';
      case CustomerType.buyer:
        return 'مشتري';
      case CustomerType.shop:
        return 'محل';
      default:
        return 'غير معروف';
    }
  }
}
