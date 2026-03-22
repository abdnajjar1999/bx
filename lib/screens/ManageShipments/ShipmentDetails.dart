import 'package:good_line_delivery/screens/AddOrder/AddOrderFormOne.dart';
import 'package:good_line_delivery/screens/ManageShipments/widget/OrderChat.dart';
import 'package:universal_html/html.dart' as html;

import '../../main.dart';
import '../../models/Shipment.dart';
import '../dashboard/header/showSideDrawerDialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_barcodes/barcodes.dart' as barcode;
import '../../shared/PrintHelper.dart';

class ShipmentDetails extends StatefulWidget {
  final Shipment? shipment;

  const ShipmentDetails({Key? key, required this.shipment}) : super(key: key);

  @override
  State<ShipmentDetails> createState() => _ShipmentDetailsState();
}

class _ShipmentDetailsState extends State<ShipmentDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isMobile = width < 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: background,
        child: Container(
          width: isMobile ? width : 850,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDialogHeader(),
              _buildActionButtons(),
              Expanded(
                child: isMobile
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLeftPanel(isScrollable: false),
                            _buildRightPanel(isScrollable: false),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _buildLeftPanel(isScrollable: true),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildRightPanel(isScrollable: true),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'تفاصيل الشحنة',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: primary),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel({bool isScrollable = true}) {
    Widget content = Column(
      children: [
        _buildModernShipmentCard(),
        const SizedBox(height: 20),
        _buildTabSwitcher(),
        const SizedBox(height: 10),
        _buildLogsTimeline(),
      ],
    );

    if (isScrollable) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: content,
    );
  }

  Widget _buildRightPanel({bool isScrollable = true}) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'تاريخ وحركات الطرد',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildTimelineInfoSection(
          title: 'معلومات المرسل',
          icon: Icons.store_outlined,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.shipment?.senderName ?? widget.shipment?.username ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(widget.shipment?.city ?? '-'),
              const SizedBox(height: 10),
              _whatsappButton(widget.shipment?.userphone ?? ''),
            ],
          ),
          isFirst: true,
        ),
        _buildTimelineInfoSection(
          title: 'معلومات المستلم',
          icon: Icons.person_pin_circle_outlined,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.shipment?.recipientName ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(widget.shipment?.addressDescription ?? ''),
              const SizedBox(height: 10),
              _whatsappButton(widget.shipment?.phoneNumber ?? ''),
            ],
          ),
          isLast: true,
        ),
      ],
    );

    if (isScrollable) {
      return Container(
        color: Colors.black.withValues(alpha: 0.02),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: content,
        ),
      );
    }
    return Container(
      color: Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: content,
      ),
    );
  }

  Widget _buildTimelineInfoSection({
    required String title,
    required IconData icon,
    required Widget content,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: primary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 15, 0, 30),
                  child: content,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whatsappButton(String phone) {
    return InkWell(
      onTap: () {
        if (phone.isNotEmpty) {
          String url = "https://wa.me/${phone.replaceAll('+', '')}";
          html.window.open(url, "_blank");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF25D366)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android, color: Color(0xFF25D366), size: 18),
            const SizedBox(width: 8),
            Text(
              phone,
              style: const TextStyle(
                color: Color(0xFF25D366),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernShipmentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: secprimary, size: 48),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _barcodeWidget(widget.shipment?.orderId ?? '', 'رقم الطرد'),
                    const SizedBox(height: 20),
                    if (widget.shipment?.trackingNumber != null &&
                        widget.shipment!.trackingNumber.isNotEmpty &&
                        widget.shipment!.trackingNumber !=
                            widget.shipment!.orderId)
                      _barcodeWidget(
                          widget.shipment!.trackingNumber, 'رقم الإرسالية'),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _cardInfoRow('رقم الطرد', '#${widget.shipment?.orderId}'),
                    _cardInfoRow(
                        'تاريخ الحجز',
                        _formatDate(
                            widget.shipment?.createdAt ?? DateTime.now())),
                    _cardInfoRow(
                        'قيمة التحصيل', '${widget.shipment?.codAmount} JOD'),
                    _cardInfoRow(
                        'السعر', '${widget.shipment?.deliveryCost} JOD'),
                    _cardInfoRow('رقم الإرسالية',
                        widget.shipment?.trackingNumber ?? '-'),
                    _cardInfoRow('ملاحظات', widget.shipment?.notes ?? '-'),
                    _cardInfoRow('الحالة', widget.shipment?.status ?? '',
                        isStatus: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barcodeWidget(String value, String label) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 80,
          width: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: barcode.SfBarcodeGenerator(
            value: value.isEmpty ? 'N/A' : value,
            symbology: barcode.Code128(),
            showValue: true,
          ),
        ),
      ],
    );
  }

  Widget _cardInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Row(
      children: [
        _tabButton('الحركات', 0),
        const SizedBox(width: 10),
        _tabButton('تتبع الحالات', 1),
        const SizedBox(width: 10),
        _tabButton('المحادثة', 2),
      ],
    );
  }

  Widget _tabButton(String text, int index) {
    bool isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? secprimary : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLogsTimeline() {
    if (_tabController.index == 2) {
      return SizedBox(
        height: 500,
        child: OrderChat(shipment: widget.shipment!),
      );
    }

    final logs = _tabController.index == 0
        ? widget.shipment?.logs ?? []
        : widget.shipment?.logs.where((e) => e.status != null).toList() ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs.reversed.toList()[index];
        return _buildTimelineItem(log);
      },
    );
  }

  Widget _buildTimelineItem(ShipmentLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              log.status ?? 'إشعار',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Text(
                log.text,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                intl.DateFormat('dd/MM/yyyy').format(log.date),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                intl.DateFormat('HH:mm').format(log.date),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                log.userName ?? '',
                style: const TextStyle(fontSize: 10, color: primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _actionButton(
              text: 'تعديل',
              icon: Icons.edit_outlined,
              onPressed: () {
                showSideDrawerDialog(
                    context: context,
                    child: AddOrderFormOne(
                      shipment: widget.shipment,
                      isEditMode: true,
                    ));
              },
            ),
            _actionButton(
              text: 'طباعة',
              icon: Icons.print_outlined,
              onPressed: () async {
                showDialog(
                    context: context,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()));
                await PrintHandler().printShipmentReceipt([widget.shipment!]);
                Navigator.pop(context);
              },
            ),
            _actionButton(
              text: 'طباعة مع الحركات',
              icon: Icons.receipt_long_outlined,
              onPressed: () async {
                showDialog(
                    context: context,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()));
                await PrintHandler()
                    .printShipmentReceiptWithLogs([widget.shipment!]);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? primary,
          side: BorderSide(color: (color ?? primary).withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return intl.DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
