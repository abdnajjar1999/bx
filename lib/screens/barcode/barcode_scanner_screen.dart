import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Shipment.dart';
import '../../shared/ScannerProvider.dart';
import '../../shared/appProvider.dart';
import '../ManageShipments/ShipmentDetails.dart';
import '../dashboard/header/showSideDrawerDialog.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Outfit')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _viewShipmentDetails(Shipment shipment) {
    showSideDrawerDialog(
      context: context,
      side: DrawerSide.left,
      width: MediaQuery.of(context).size.width > 850
          ? 850
          : MediaQuery.of(context).size.width,
      child: ShipmentDetails(shipment: shipment),
    );
  }

  void _showChangeStatusDialog() {
    final provider = context.read<ScannerProvider>();
    final count = provider.selectedIds.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاستلام في الفرع',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من استلام ($count) طلبات في الفرع؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final appProvider = context.read<AppProvider>();
              final userName =
                  appProvider.currentUserEmployee?.username ?? "مجهول";
              Navigator.pop(context);
              await provider.bulkUpdateStatus('في الفرع', userName);
              _showSnackBar('تم استلام $count طلبات بنجاح', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الاستلام'),
          ),
        ],
      ),
    );
  }

  void _showReceiveReturnsDialog() {
    final provider = context.read<ScannerProvider>();
    final count = provider.selectedIds.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد استلام المرتجعات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من استلام ($count) طرود مرتجعة من السائق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final appProvider = context.read<AppProvider>();
              final userName =
                  appProvider.currentUserEmployee?.username ?? "مجهول";
              Navigator.pop(context);
              await provider.bulkReceiveReturns(userName);
              _showSnackBar('تم استلام $count مرتجعات بنجاح', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الاستلام'),
          ),
        ],
      ),
    );
  }

  void _showAssignDriverDialog() {
    final appProvider = context.read<AppProvider>();
    final scannerProvider = context.read<ScannerProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعيين سائق للطلبات المحددة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text('ختر السائق لتخصيصه لهذه الشحنات:',
                    style: TextStyle(color: Colors.grey)),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: appProvider.drivers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final driver = appProvider.drivers[index];
                    return ListTile(
                      leading:
                          const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(driver.username.toString()),
                      onTap: () async {
                        final userName =
                            appProvider.currentUserEmployee?.username ??
                                "مجهول";
                        Navigator.pop(context);
                        await scannerProvider.bulkAssignDriver(
                            driver, userName);
                        _showSnackBar(
                            'تم تعيين السائق للطلبات المختارة', Colors.green);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerProvider = context.watch<ScannerProvider>();
    final scannedShipments = scannerProvider.scannedShipments;
    final selectedIds = scannerProvider.selectedIds;
    final lastScanned = scannerProvider.lastScannedBarcode;
    final isLoading = scannerProvider.isLoading;
    final allSelected = scannedShipments.isNotEmpty &&
        selectedIds.length == scannedShipments.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text(
          'نظام إدارة الماسح المتعدد',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: false,
        actions: [
          _buildActionChip(
            '${scannedShipments.length} إجمالي',
            const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            '${selectedIds.length} محدد',
            const Color(0xFF4F46E5),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar: Scanner Status & Guidance
          _buildLeftSidebar(isLoading, lastScanned),

          // Right Main Content: Data Table
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTableHeader(scannerProvider, allSelected),
                  Expanded(
                    child: scannedShipments.isEmpty
                        ? _buildEmptyState()
                        : _buildDataTable(
                            scannerProvider, scannedShipments, selectedIds),
                  ),
                  if (selectedIds.isNotEmpty) _buildTableFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildLeftSidebar(bool isLoading, String? lastScanned) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: const Color(0xFF4F46E5).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'جاهز للمسح',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          const Text(
            'استخدم جهاز الماسح الضوئي لإضافة الشحنات تلقائياً',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 48),
          if (isLoading)
            const Column(
              children: [
                CircularProgressIndicator(
                    strokeWidth: 3, color: Color(0xFF4F46E5)),
                SizedBox(height: 16),
                Text('جاري التحميل...',
                    style: TextStyle(
                        color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              ],
            )
          else if (lastScanned != null && lastScanned.isNotEmpty)
            _buildScanningPreview(lastScanned)
          else
            _buildInstructionCard(),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'تحديث تلقائي للنظام',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          // Manual Entry Field
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'أدخل الرقم يدوياً...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon:
                    const Icon(Icons.edit_note, color: Color(0xFF4F46E5)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4F46E5), width: 2),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<ScannerProvider>().addShipment(value.trim());
                  // Optional: Clear the text field after submission
                  // For simple usage, user can just delete.
                  // If we want auto-clear, we need a controller.
                  // If a user wants to submit multiple quickly, clearing is good.
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningPreview(String barcode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        children: [
          const Text('آخر مسح:',
              style: TextStyle(fontSize: 12, color: Color(0xFF9F1239))),
          const SizedBox(height: 8),
          Text(
            barcode,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4F46E5)),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
              SizedBox(width: 8),
              Text('نصيحة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'امسح عدة باركودات متتالية'),
          const SizedBox(height: 8),
          _buildInstructionStep('2', 'استخدم "تحديد الكل" للمعالجة الجماعية'),
          const SizedBox(height: 8),
          _buildInstructionStep('3', 'اختر الإجراء من أسفل الجدول'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$step.',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
      ],
    );
  }

  Widget _buildTableHeader(ScannerProvider provider, bool allSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (val) =>
                val == true ? provider.selectAll() : provider.deselectAll(),
            activeColor: const Color(0xFF4F46E5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          const Text(
            'تحديد الكل',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const Spacer(),
          if (provider.scannedShipments.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => provider.clearAll(),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('إفراغ القائمة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            'https://cdn-icons-png.flaticon.com/512/5089/5089736.png',
            height: 120,
            opacity: const AlwaysStoppedAnimation(0.5),
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد شحنات ممسوحة حالياً',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          const Text('ابدأ بمسح الأكواد الضوئية لتظهر هنا',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDataTable(ScannerProvider provider, List<Shipment> shipments,
      Set<String> selectedIds) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        showCheckboxColumn: false,
        columnSpacing: 32,
        horizontalMargin: 24,
        headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            fontSize: 13),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('رقم الطلب')),
          DataColumn(label: Text('رقم التتبع')),
          DataColumn(label: Text('المستلم')),
          DataColumn(label: Text('رقم الهاتف')),
          DataColumn(label: Text('المنطقة')),
          DataColumn(label: Text('سعر التوصيل')),
          DataColumn(label: Text('الحالة')),
          DataColumn(label: Text('الإجراءات')),
        ],
        rows: List<DataRow>.generate(shipments.length, (index) {
          final shipment = shipments[index];
          final selected = provider.isSelected(shipment.orderId);

          return DataRow(
            selected: selected,
            onSelectChanged: (_) => provider.toggleSelection(shipment.orderId),
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(shipment.orderId,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(shipment.trackingNumber)),
              DataCell(Text(shipment.recipientName)),
              DataCell(Text(shipment.phoneNumber)),
              DataCell(Text(shipment.city)),
              DataCell(Text('${shipment.deliveryCost} د.أ')),
              DataCell(_buildStatusBadge(shipment.status)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: () => _viewShipmentDetails(shipment),
                    tooltip: 'التفاصيل',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: Colors.red),
                    onPressed: () => provider.removeShipment(shipment.orderId),
                    tooltip: 'حذف',
                  ),
                ],
              )),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'في الفرع') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'إجراءات جماعية:',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: _showAssignDriverDialog,
            icon: const Icon(Icons.local_shipping_rounded),
            label: const Text('تعيين سائق للكل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showReceiveReturnsDialog,
            icon: const Icon(Icons.assignment_return_rounded),
            label: const Text('استلام مرتجع'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showChangeStatusDialog,
            icon: const Icon(Icons.published_with_changes_rounded),
            label: const Text('استلام في الفرع'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
