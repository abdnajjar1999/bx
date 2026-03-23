import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/PackageType.dart';
import '../../shared/appProvider.dart';

class PackageTypesScreen extends StatefulWidget {
  const PackageTypesScreen({Key? key}) : super(key: key);

  @override
  _PackageTypesScreenState createState() => _PackageTypesScreenState();
}

class _PackageTypesScreenState extends State<PackageTypesScreen> {
  void _showPackageTypeForm({PackageType? packageType}) {
    showDialog(
      context: context,
      builder: (context) => PackageTypeFormDialog(packageType: packageType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إدارة أنواع الطرود',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showPackageTypeForm(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة نوع جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('الاسم')),
                          DataColumn(label: Text('الطول (سم)')),
                          DataColumn(label: Text('العرض (سم)')),
                          DataColumn(label: Text('الارتفاع (سم)')),
                          DataColumn(label: Text('الوزن (كجم)')),
                          DataColumn(label: Text('الإجراءات')),
                        ],
                        rows: appProvider.packageTypes.map((pt) {
                          return DataRow(cells: [
                            DataCell(Text(pt.name)),
                            DataCell(Text(pt.length.toString())),
                            DataCell(Text(pt.width.toString())),
                            DataCell(Text(pt.height.toString())),
                            DataCell(Text(pt.weight.toString())),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showPackageTypeForm(packageType: pt),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد الحذف'),
                                        content: const Text('هل أنت متأكد من حذف هذا النوع؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('إلغاء'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      List<PackageType> updatedList = List.from(appProvider.packageTypes);
                                      updatedList.removeWhere((e) => e.id == pt.id);
                                      await appProvider.firebaseHelper.updatePackageTypes(
                                        updatedList.map((e) => e.toMap()).toList()
                                      );
                                    }
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}
}

class PackageTypeFormDialog extends StatefulWidget {
  final PackageType? packageType;
  const PackageTypeFormDialog({Key? key, this.packageType}) : super(key: key);

  @override
  _PackageTypeFormDialogState createState() => _PackageTypeFormDialogState();
}

class _PackageTypeFormDialogState extends State<PackageTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.packageType?.name ?? '');
    _lengthController = TextEditingController(text: widget.packageType?.length.toString() ?? '');
    _widthController = TextEditingController(text: widget.packageType?.width.toString() ?? '');
    _heightController = TextEditingController(text: widget.packageType?.height.toString() ?? '');
    _weightController = TextEditingController(text: widget.packageType?.weight.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      List<PackageType> updatedList = List.from(appProvider.packageTypes);

      final newPt = PackageType(
        id: widget.packageType?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        length: double.tryParse(_lengthController.text.trim()) ?? 0,
        width: double.tryParse(_widthController.text.trim()) ?? 0,
        height: double.tryParse(_heightController.text.trim()) ?? 0,
        weight: double.tryParse(_weightController.text.trim()) ?? 0,
      );

      if (widget.packageType != null) {
        int index = updatedList.indexWhere((e) => e.id == widget.packageType!.id);
        if (index != -1) updatedList[index] = newPt;
      } else {
        updatedList.add(newPt);
      }

      await appProvider.firebaseHelper.updatePackageTypes(
        updatedList.map((e) => e.toMap()).toList()
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.packageType == null ? 'إضافة نوع جديد' : 'تعديل نوع الطرد',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'اسم الطرد', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _lengthController, decoration: InputDecoration(labelText: 'الطول', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _widthController, decoration: InputDecoration(labelText: 'العرض', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _heightController, decoration: InputDecoration(labelText: 'الارتفاع', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'الوزن', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('حفظ'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
