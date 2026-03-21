import '../../../shared/constants.dart';

import '../../../main.dart';
import 'widget/customListTile.dart';
import 'package:flutter/material.dart';

class SideDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTileSelected;
  SideDrawer(
      {super.key, required this.selectedIndex, required this.onTileSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        elevation: 1.0,
        width: 180,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
        child: Column(children: [
          Container(
            width: double.infinity,
            height: 10,
            decoration: const BoxDecoration(
              color: primary,
            ),
          ),
          SizedBox(
            height: 180,
            child: Stack(children: [
              Positioned(
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.vertical(
                      // top: Radius.elliptical(50, 100),
                      bottom: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                  child: Align(
                      alignment: Alignment.center,
                      child: Material(
                        borderRadius: BorderRadius.circular(5),
                        elevation: 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            "assets/images/" + $KcompanyLogo,
                            width: 150,
                            height: 115,
                            //color: primary,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ))),
              Positioned.fill(
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(KcompanyName))),
            ]),
          ),
          Expanded(
            child: ListView(
              children: [
                customListTile(
                    selected: selectedIndex == 0,
                    icon: Icons.dashboard,
                    title: drawerTitles[0],
                    onTap: () => onTileSelected(0)),
                customListTile(
                  selected: selectedIndex == 1,
                  icon: Icons.local_shipping,
                  title: drawerTitles[1],
                  children: [
                    customListTile(
                      selected: selectedIndex == 1,
                      icon: Icons.list_alt,
                      title: drawerTitles[1],
                      onTap: () => onTileSelected(1),
                    ),
                    customListTile(
                      selected: selectedIndex ==
                          24, // New index for bundled shipments
                      icon: Icons.inventory_2,
                      title: drawerTitles[24],
                      onTap: () => onTileSelected(24),
                    ),
                  ],
                ),
                customListTile(
                    selected: selectedIndex == 2,
                    icon: Icons.track_changes,
                    title: drawerTitles[2],
                    onTap: () => onTileSelected(2)),
                customListTile(
                    icon: Icons.assignment_return,
                    title: 'الطلبات المرتجعة',
                    children: [
                      customListTile(
                          selected: selectedIndex == 17,
                          icon: Icons.location_city,
                          title: drawerTitles[17],
                          onTap: () => onTileSelected(17)),
                      customListTile(
                          selected: selectedIndex == 16,
                          icon: Icons.people,
                          title: drawerTitles[16],
                          onTap: () => onTileSelected(16)),
                    ]),
                customListTile(
                    selected: selectedIndex == 3,
                    icon: Icons.people,
                    title: 'إدارة المركبات',
                    onTap: () => onTileSelected(3)),
                customListTile(
                    selected: selectedIndex == 4,
                    icon: Icons.drive_eta,
                    title: drawerTitles[4],
                    onTap: () => onTileSelected(4)),
                customListTile(
                    selected: selectedIndex == 29,
                    icon: Icons.manage_accounts,
                    title: drawerTitles[29],
                    onTap: () => onTileSelected(29)),
                customListTile(
                    selected: selectedIndex == 5,
                    icon: Icons.people_outline,
                    title: drawerTitles[5],
                    onTap: () => onTileSelected(5)),
                customListTile(
                    selected: selectedIndex == 20,
                    icon: Icons.inventory,
                    title: drawerTitles[20],
                    onTap: () => onTileSelected(20)),
                customListTile(
                  icon: Icons.account_balance_wallet,
                  title: 'المحاسبة',
                  children: [
                    customListTile(
                        selected: selectedIndex == 6,
                        icon: Icons.receipt,
                        title: drawerTitles[6],
                        onTap: () => onTileSelected(6)),
                    customListTile(
                        selected: selectedIndex == 7,
                        icon: Icons.inventory,
                        title: drawerTitles[7],
                        onTap: () => onTileSelected(7)),
                    customListTile(
                        selected: selectedIndex == 8,
                        icon: Icons.send,
                        title: drawerTitles[8],
                        onTap: () => onTileSelected(8)),
                    customListTile(
                        selected: selectedIndex == 9,
                        icon: Icons.done_all,
                        title: drawerTitles[9],
                        onTap: () => onTileSelected(9)),
                    customListTile(
                        selected: selectedIndex == 19,
                        icon: Icons.receipt_long,
                        title: drawerTitles[19],
                        onTap: () => onTileSelected(19)),
                    customListTile(
                        selected: selectedIndex == 10,
                        icon: Icons.calculate,
                        title: drawerTitles[10],
                        onTap: () => onTileSelected(10)),
                    customListTile(
                        selected: selectedIndex == 21,
                        icon: Icons.car_repair,
                        title: drawerTitles[21],
                        onTap: () => onTileSelected(21)),
                    customListTile(
                        selected: selectedIndex == 11,
                        icon: Icons.bar_chart,
                        title: drawerTitles[11],
                        onTap: () => onTileSelected(11)),
                    customListTile(
                        selected: selectedIndex == 12,
                        icon: Icons.money,
                        title: drawerTitles[12],
                        onTap: () => onTileSelected(12)),
                    customListTile(
                        selected: selectedIndex == 18,
                        icon: Icons.account_balance_wallet,
                        title: drawerTitles[18],
                        onTap: () => onTileSelected(18)),
                    customListTile(
                        selected: selectedIndex == 13,
                        icon: Icons.folder,
                        title: drawerTitles[13],
                        onTap: () => onTileSelected(13)),
                    customListTile(
                        selected: selectedIndex == 25,
                        icon: Icons.receipt_long,
                        title: drawerTitles[25],
                        onTap: () => onTileSelected(25)),
                  ],
                ),
                customListTile(
                    selected: selectedIndex == 14,
                    icon: Icons.people_outline,
                    title: drawerTitles[14],
                    onTap: () => onTileSelected(14)),
                customListTile(
                    icon: Icons.warehouse,
                    title: 'المخزن',
                    children: [
                      customListTile(
                          selected: selectedIndex == 22,
                          icon: Icons.shelves,
                          title: drawerTitles[22],
                          onTap: () => onTileSelected(22)),
                      customListTile(
                          selected: selectedIndex == 26,
                          icon: Icons.shopping_basket,
                          title: drawerTitles[26],
                          onTap: () => onTileSelected(26)),
                    ]),
                customListTile(
                    icon: Icons.admin_panel_settings,
                    title: 'الادارة',
                    children: [
                      customListTile(
                          selected: selectedIndex == 15,
                          icon: Icons.location_city,
                          title: drawerTitles[15],
                          onTap: () => onTileSelected(15)),
                      customListTile(
                          selected: selectedIndex == 23,
                          icon: Icons.analytics,
                          title: drawerTitles[23],
                          onTap: () => onTileSelected(23)),
                      customListTile(
                          selected: selectedIndex == 27,
                          icon: Icons.map,
                          title: drawerTitles[27],
                          onTap: () => onTileSelected(27)),
                      customListTile(
                          selected: selectedIndex == 28,
                          icon: Icons.local_shipping_outlined,
                          title: drawerTitles[28],
                          onTap: () => onTileSelected(28)),
                    ]),

      customListTile(
                  icon: Icons.admin_panel_settings,
                  title: 'الاعدادات',
                  children: [
                    customListTile(
                        selected: selectedIndex == 30,
                        icon: Icons.import_export,
                        title: drawerTitles[30],
                        onTap: () => onTileSelected(30)),
                  ],
                ),

              ],
            ),
          )
        ]));
  }
}
