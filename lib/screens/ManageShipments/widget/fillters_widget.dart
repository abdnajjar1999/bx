import '../../../main.dart';
import 'package:flutter/material.dart';

import 'CustomTextField.dart';

class fillters_widget extends StatefulWidget {
  const fillters_widget({super.key});

  @override
  State<fillters_widget> createState() => _fillters_widgetState();
}

class _fillters_widgetState extends State<fillters_widget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5.0,
        runSpacing: 5.0,
        children: [
          Container(
            width: 100,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedValue = newValue!;
                });
              },
            ),
          ),
          CustomTextField(
            labelText: "رقم الطرد",
            hintText: "ادخل رقم الطرد",
            prefixIcon: Icons.numbers,
            controller: TextEditingController(),
          ),
          CustomTextField(
            labelText: "السعر",
            hintText: "ادخل السعر",
            prefixIcon: Icons.monetization_on_outlined,
            controller: TextEditingController(),
          ),
          CustomTextField(
            labelText: "الوزن",
            hintText: "ادخل الوزن",
            prefixIcon: Icons.scale,
            controller: TextEditingController(),
          ),
          CustomTextField(
            width: 200,
            labelText: "هاتف المستلم",
            hintText: "ادخل هاتف المستلم",
            prefixIcon: Icons.phone,
            controller: TextEditingController(),
          ),
          Container(
            width: 100,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: selectedValue2,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              items: items2.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedValue2 = newValue!;
                });
              },
            ),
          ),
          TextButton(
              onPressed: () {
                return showFutureDetailsBottomSheet();
              },
              child: Text("المستقبل"))
        ],
      ),
    );
  }

  String selectedValue = 'All';
  String selectedValue2 = 'All';
  List<String> items = [
    'All',
    'koko',
    'ahmad',
    'petra',
    'shein',
    'zeroone',
    'alshe5',
    'sobhi',
    'bader',
    'alnajjar',
    'sodod'
  ];
  List<String> items2 = [
    'All',
    'تم الارسال',
    'تالفة',
    'تم التوصيل',
  ];

  void showFutureDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'تخصيص معلومات المستقبل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ادخل اسم العميل',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.person, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'يرجى الاختيار أو البحث',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'region1',
                          child: Text('المنطقة 1',
                              style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'region2',
                          child: Text('المنطقة 2',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) {},
                      dropdownColor: Colors.grey[850],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'تم',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
