import '../../../shared/constants.dart';
import '../../../sadrad/colors.dart';
import '../../../main.dart';
import 'widget/customListTile.dart';
import 'package:flutter/material.dart';

class SideDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTileSelected;

  const SideDrawer({
    super.key,
    required this.selectedIndex,
    required this.onTileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      width: 260, // Increased width for better readability
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                customListTile(
                  selected: selectedIndex == 0,
                  icon: Icons.dashboard_outlined,
                  title: drawerTitles[0],
                  onTap: () => onTileSelected(0),
                ),
                customListTile(
                  selected: selectedIndex == 1,
                  icon: Icons.local_shipping_outlined,
                  title: drawerTitles[1],
                  children: [
                    customListTile(
                      selected: selectedIndex == 1,
                      icon: Icons.list_alt,
                      title: drawerTitles[1],
                      onTap: () => onTileSelected(1),
                    ),
                    customListTile(
                      selected: selectedIndex == 24,
                      icon: Icons.inventory_2_outlined,
                      title: drawerTitles[24],
                      onTap: () => onTileSelected(24),
                    ),
                  ],
                ),
                customListTile(
                  selected: selectedIndex == 2,
                  icon: Icons.track_changes,
                  title: drawerTitles[2],
                  onTap: () => onTileSelected(2),
                ),
                customListTile(
                  icon: Icons.assignment_return_outlined,
                  title: 'الطلبات المرتجعة',
                  children: [
                    customListTile(
                      selected: selectedIndex == 17,
                      icon: Icons.domain_outlined,
                      title: drawerTitles[17],
                      onTap: () => onTileSelected(17),
                    ),
                    customListTile(
                      selected: selectedIndex == 16,
                      icon: Icons.people_outline,
                      title: drawerTitles[16],
                      onTap: () => onTileSelected(16),
                    ),
                  ],
                ),
                customListTile(
                  selected: selectedIndex == 3,
                  icon: Icons.minor_crash_outlined,
                  title: 'إدارة المركبات',
                  onTap: () => onTileSelected(3),
                ),
                customListTile(
                  selected: selectedIndex == 4,
                  icon: Icons.badge_outlined,
                  title: drawerTitles[4],
                  onTap: () => onTileSelected(4),
                ),
                customListTile(
                  selected: selectedIndex == 29,
                  icon: Icons.manage_accounts_outlined,
                  title: drawerTitles[29],
                  onTap: () => onTileSelected(29),
                ),
                customListTile(
                  selected: selectedIndex == 5,
                  icon: Icons.groups_outlined,
                  title: drawerTitles[5],
                  onTap: () => onTileSelected(5),
                ),
                customListTile(
                  selected: selectedIndex == 20,
                  icon: Icons.inventory_outlined,
                  title: drawerTitles[20],
                  onTap: () => onTileSelected(20),
                ),
                customListTile(
                  icon: Icons.account_balance_outlined,
                  title: 'المحاسبة',
                  children: [
                    _buildSubTile(6, Icons.description_outlined),
                    _buildSubTile(7, Icons.inventory_2_outlined),
                    _buildSubTile(8, Icons.send_outlined),
                    _buildSubTile(9, Icons.check_circle_outlined),
                    _buildSubTile(19, Icons.receipt_long_outlined),
                    _buildSubTile(10, Icons.calculate_outlined),
                    _buildSubTile(21, Icons.car_rental_outlined),
                    _buildSubTile(11, Icons.analytics_outlined),
                    _buildSubTile(12, Icons.payments_outlined),
                    _buildSubTile(18, Icons.account_balance_wallet_outlined),
                    _buildSubTile(13, Icons.folder_open_outlined),
                    _buildSubTile(25, Icons.receipt_outlined),
                  ],
                ),
                customListTile(
                  selected: selectedIndex == 14,
                  icon: Icons.chat_outlined,
                  title: drawerTitles[14],
                  onTap: () => onTileSelected(14),
                ),
                customListTile(
                  icon: Icons.warehouse_outlined,
                  title: 'المخزن',
                  children: [
                    _buildSubTile(22, Icons.shelves),
                    _buildSubTile(26, Icons.shopping_basket_outlined),
                  ],
                ),
                customListTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'الإدارة',
                  children: [
                    _buildSubTile(15, Icons.map_outlined),
                    _buildSubTile(23, Icons.psychology_outlined),
                    _buildSubTile(27, Icons.route_outlined),
                    _buildSubTile(28, Icons.delivery_dining_outlined),
                  ],
                ),
                customListTile(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  children: [
                    _buildSubTile(30, Icons.import_export_outlined),
                    _buildSubTile(31, Icons.category_outlined),
                  ],
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSubTile(int index, IconData icon) {
    return customListTile(
      selected: selectedIndex == index,
      icon: icon,
      title: drawerTitles[index],
      onTap: () => onTileSelected(index),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 16, right: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "assets/images/logo.png",
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_shipping,
                size: 60,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            KcompanyName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: SadradColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "الإصدار 1.0.0",
            style: TextStyle(
              color: SadradColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
