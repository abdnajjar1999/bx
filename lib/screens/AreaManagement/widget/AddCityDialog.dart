import 'package:flutter/material.dart';
import '../../../models/City.dart';

class AddCityDialog extends StatefulWidget {
  final Function(City) onSave;
  final City? cityToEdit;

  const AddCityDialog({
    Key? key,
    required this.onSave,
    this.cityToEdit,
  }) : super(key: key);

  @override
  _AddCityDialogState createState() => _AddCityDialogState();
}

class _AddCityDialogState extends State<AddCityDialog> {
  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final List<String> _places = [];

  @override
  void initState() {
    super.initState();
    if (widget.cityToEdit != null) {
      _cityNameController.text = widget.cityToEdit!.name;
      _places.addAll(widget.cityToEdit!.places);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.cityToEdit != null ? 'تعديل مدينة' : 'إضافة مدينة جديدة',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المدينة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _placeController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنطقة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_placeController.text.isNotEmpty) {
                      setState(() {
                        _places.add(_placeController.text);
                        _placeController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffaf5405),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('إضافة منطقة'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _places.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_places[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _places.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_cityNameController.text.isNotEmpty) {
                      final city = City(
                        name: _cityNameController.text,
                        places: List.from(_places),
                      );
                      widget.onSave(city);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffaf5405),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 