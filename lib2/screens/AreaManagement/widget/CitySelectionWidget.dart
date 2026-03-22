import '../../../main.dart';
import 'package:flutter/material.dart';

class CitySelectionWidget extends StatefulWidget {
  @override
  _CitySelectionWidgetState createState() => _CitySelectionWidgetState();
}

class _CitySelectionWidgetState extends State<CitySelectionWidget> {
  List<String> cities = [
    "مسقط",
    "ظفار",
    "البريمي",
    "الداخلية",
    "الظاهرة",
    "شمال الشرقية",
    "جنوب الشرقية",
    "شمال الباطنة",
    "جنوب الباطنة",
    "مسندم",
  ];
  List<String> selectedCities = [];
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // حقل البحث
        Row(
          children: [
            const Text('المدن', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'بحث',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cities
                  .where((city) => city.contains(searchController.text))
                  .map((city) {
                return Container(
                  margin: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: CheckboxListTile(
                    title: Text(
                      city,
                      style: const TextStyle(),
                    ),
                    activeColor: Color(0xffaf5405),
                    value: selectedCities.contains(city),
                    onChanged: (isChecked) {
                      setState(() {
                        if (isChecked!) {
                          selectedCities.add(city);
                        } else {
                          selectedCities.remove(city);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // أزرار الإضافة والحذف
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffaf5405),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )),
              onPressed: () {},
              label: const Text('إضافة'),
              icon: Icon(
                Icons.add,
                size: 20,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Color(0xffaf5405),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        width: 1.0,
                        color: Color(0xffaf5405),
                      ))),
              onPressed: () {},
              label: const Text('حذف'),
              icon: Icon(
                Icons.delete,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
