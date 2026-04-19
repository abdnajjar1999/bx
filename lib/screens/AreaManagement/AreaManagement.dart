
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'dart:typed_data';

import '../../shared/appProvider.dart';
import '../../models/City.dart';
import 'widget/AddCityDialog.dart';

class AreaManagement extends StatefulWidget {
  const AreaManagement({super.key});

  @override
  State<AreaManagement> createState() => _AreaManagementState();
}

class _AreaManagementState extends State<AreaManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.getCitiesAndPlaces();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null) {
        Uint8List? bytes;
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes;
        } else {
          // Handle platform-specific file reading if necessary
          // For now assuming bytes are available (web/desktop)
        }

        if (bytes == null) return;

        var excel = excel_pkg.Excel.decodeBytes(bytes);
        Map<String, Set<String>> importedCities = {};

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          // Skip header row
          for (int i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];
            if (row.length < 2) continue;

            // Mapping based on user request: City (0), District (1 - skip), Area (2)
            // If the row has 3 or more columns, we take 0 and 2.
            // If it has only 2, we take 0 and 1.
            String cityName = row[0]?.value?.toString().trim() ?? '';
            String placeName = '';

            if (row.length >= 3) {
              placeName = row[2]?.value?.toString().trim() ?? '';
            } else if (row.length >= 2) {
              placeName = row[1]?.value?.toString().trim() ?? '';
            }

            if (cityName.isNotEmpty && placeName.isNotEmpty) {
              if (!importedCities.containsKey(cityName)) {
                importedCities[cityName] = {};
              }
              importedCities[cityName]!.add(placeName);
            }
          }
        }

        if (importedCities.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على بيانات صالحة في الملف')),
          );
          return;
        }

        final appProvider = Provider.of<AppProvider>(context, listen: false);

        // Merge with existing data
        for (var entry in importedCities.entries) {
          String cityName = entry.key;
          List<String> newPlaces = entry.value.toList();

          // Check if city already exists
          var existingCity = appProvider.citiesAndPlaces.firstWhere(
            (c) => c.name == cityName,
            orElse: () => City(name: cityName, places: []),
          );

          Set<String> allPlaces = {...existingCity.places, ...newPlaces};
          appProvider.addCity(City(name: cityName, places: allPlaces.toList()));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد ${importedCities.length} مدينة بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الاستيراد: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final filteredCities = appProvider.citiesAndPlaces
            .where((city) =>
                city.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                city.places.any((place) =>
                    place.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[100]!,
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إدارة المدن والمناطق',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffaf5405),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'إدارة وتنظيم المدن والمناطق في النظام',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _importFromExcel,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.file_upload),
                              label: const Text(
                                'استيراد من Excel',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AddCityDialog(
                                    onSave: (city) {
                                      appProvider.addCity(city);
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffaf5405),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'إضافة مدينة جديدة',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'البحث عن مدينة أو منطقة...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Cities List
                  Expanded(
                    child: filteredCities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_city_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد مدن تطابق البحث',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCities.length,
                            itemBuilder: (context, index) {
                              final city = filteredCities[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ExpansionTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(
                                    city.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffaf5405),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${city.places.length} منطقة',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Color(0xFFDC2626)),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AddCityDialog(
                                              cityToEdit: city,
                                              onSave: (updatedCity) {
                                                appProvider.updateCity(
                                                    city.name, updatedCity);
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('تأكيد الحذف'),
                                              content: Text(
                                                  'هل أنت متأكد من حذف مدينة ${city.name} وجميع مناطقها؟'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('إلغاء'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    appProvider
                                                        .deleteCity(city.name);
                                                    Navigator.pop(context);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('حذف'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'المناطق:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: city.places.map((place) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xffaf5405)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xffaf5405)
                                                            .withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Text(
                                                  place,
                                                  style: const TextStyle(
                                                    color: Color(0xffaf5405),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
