import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  final Function(int) onTabChanged;
  const CustomTabBar({Key? key, required this.onTabChanged}) : super(key: key);

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int? selectedIndex;

  final List<TabItem> tabs = [
    TabItem(title: "طلب تغير الدفع", icon: Icons.currency_exchange),
    TabItem(title: "الطلبات الجديدة", icon: Icons.fiber_new),
    TabItem(title: "بانتظار تعيين السائق", icon: Icons.person_add),
    TabItem(title: "ملغاة", icon: Icons.cancel),
    TabItem(title: "تم توصيلها", icon: Icons.check_circle),
    TabItem(title: "تم إرجاعها", icon: Icons.reply),
    TabItem(title: "تم إرجاعها مع السائق", icon: Icons.person_add),
    TabItem(title: "تم إرجاعها مع الفرع", icon: Icons.location_city),
    TabItem(title: "تم إرجاعها مع الزبون", icon: Icons.person),
    TabItem(title: "الطرود حسب مدينة المستقبل", icon: Icons.location_city),
    TabItem(title: "الطلبات المتاخرة", icon: Icons.access_time),
    TabItem(title: "الطرود المحذوفة", icon: Icons.delete),
    TabItem(title: "مرجع مؤجل", icon: Icons.inventory_2),
    TabItem(title: "في المركبة", icon: Icons.local_shipping),
    TabItem(title: "تم تعديلها", icon: Icons.edit),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Row(
              children: List.generate(
                tabs.length,
                (index) => Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                        widget.onTabChanged(index);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: selectedIndex == index
                            ? const Color(0xFFFF9800)
                            : const Color(0xFFFFC107).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: selectedIndex == index
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF9800).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[index].icon,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tabs[index].title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: List.generate(
                tabs.length,
                (index) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selectedIndex == index
                          ? const Color(0xFFFF5722)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TabItem {
  final String title;
  final IconData icon;

  TabItem({required this.title, required this.icon});
}
