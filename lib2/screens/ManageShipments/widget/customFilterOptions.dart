import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../main.dart';
import 'package:flutter/material.dart';

class customFilterOptions extends StatefulWidget {
  const customFilterOptions({super.key});

  @override
  State<customFilterOptions> createState() => _customFilterOptionsState();
}

class _customFilterOptionsState extends State<customFilterOptions> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.filter_list, size: 32, color: Colors.grey),
      onPressed: showFilterOptions,
    );
  }

  String? selectedSortBy;
  String? selectedSenderRoute;
  String? selectedReceiverRoute;

  List<String> sortByOptions = [
    'تاريخ إنشاء الطرد',
    'الإرسالية تصاعدياً',
    'الإرسالية تنازلياً',
    'تاريخ فرز التحصيل',
    'تاريخ استلام التحصيل',
    'تاريخ اخر حالة'
  ];

  List<String> routeOptions = [
    'الاختيار الأول',
    'الاختيار الثاني',
    'الاختيار الثالث',
  ];

  void resetFilters() {
    setState(() {
      selectedSortBy = null;
      selectedSenderRoute = null;
      selectedReceiverRoute = null;
    });
  }

  void showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'تصنيف المعلومات حسب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'ترتيب حسب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField2(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                hint: Text('ترتيب حسب'),
                items: sortByOptions
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                value: selectedSortBy,
                onChanged: (value) {
                  setState(() {
                    selectedSortBy = value as String;
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                'خط شحن المرسل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField2(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                hint: Text('يرجى الاختيار او البحث'),
                items: routeOptions
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                value: selectedSenderRoute,
                onChanged: (value) {
                  setState(() {
                    selectedSenderRoute = value as String;
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                'خط شحن المستقبل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField2(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                hint: Text('يرجى الاختيار او البحث'),
                items: routeOptions
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                value: selectedReceiverRoute,
                onChanged: (value) {
                  setState(() {
                    selectedReceiverRoute = value as String;
                  });
                },
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    resetFilters();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'إعادة ضبط',
                    style: TextStyle(color: primary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
