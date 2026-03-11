import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/appProvider.dart';
import '../../models/Driver.dart';

class DriverAssignmentPopup extends StatefulWidget {
 final List<Driver> drivers;

  DriverAssignmentPopup({Key? key, required this.drivers}) : super(key: key);

  @override
  State<DriverAssignmentPopup> createState() => _DriverAssignmentPopupState();
}

class _DriverAssignmentPopupState extends State<DriverAssignmentPopup> {

  List<Driver> filteredDrivers = [];
  @override
  void initState() {
    filteredDrivers = widget.drivers;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return  Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'تعيين للسائق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    //controller: searchController,
                    onChanged: (String v) {
                      print(v);
                      setState(() {
                        filteredDrivers = widget.drivers.where((driver) {
                          final searchQuery = v.toLowerCase();
                          return driver.username?.toLowerCase().contains(searchQuery) ?? false;

                        }).toList();
                      });
                      print(filteredDrivers.length);

                    },
                    decoration: const InputDecoration(
                      hintText: 'بحث...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      Driver driver =filteredDrivers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: driver.profileImage != null
                              ? NetworkImage(driver.profileImage!)
                              : null,
                          child: driver.profileImage == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(driver.username ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver.phone ?? ''),
                            if (driver.location != null && driver.location!.isNotEmpty)
                              Text('الموقع: ${driver.location}'),
                          ],
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(driver);
                          },
                          child: const Text('تعيين'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),


      ),
    );
  }
}

// Function to show the dialog
Future<Driver?> showDriverAssignmentDialog(BuildContext context,List<Driver> drivers) {
  return showDialog<Driver>(
    context: context,
    builder: (BuildContext context) => DriverAssignmentPopup(drivers: drivers),
  );
}