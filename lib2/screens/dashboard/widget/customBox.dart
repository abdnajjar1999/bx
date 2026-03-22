import 'package:sadrad/sadrad/colors.dart';

import '../../../main.dart';
import 'package:flutter/material.dart';

class customBox extends StatelessWidget {
  final String title;
  final bool is_color;
  final String count;
  final IconData? icon;

  const customBox({
    super.key,
    required this.title,
    this.is_color = false,
    this.count = '0',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    IconData displayIcon = icon ?? _getIconForTitle(title);

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Stack(
        children: [
          // Background Decorative Shape
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (is_color ? primary : Colors.grey.shade400)
                    .withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (is_color ? primary : Colors.grey.shade100)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    displayIcon,
                    color: is_color ? primary : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: SadradColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count,
                        style: TextStyle(
                          color: SadradColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('الجديدة')) return Icons.new_releases_outlined;
    if (title.contains('تعيين')) return Icons.person_add_alt_1_outlined;
    if (title.contains('المركبة')) return Icons.local_shipping_outlined;
    if (title.contains('إرجاع')) return Icons.assignment_return_outlined;
    if (title.contains('مؤجلة')) return Icons.access_time;
    if (title.contains('مغلقة')) return Icons.check_circle_outline;
    return Icons.inventory_2_outlined;
  }
}
