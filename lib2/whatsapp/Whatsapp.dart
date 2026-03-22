import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sadrad/whatsapp/webview_factory.dart';
import 'package:sadrad/whatsapp/whatsapp_ai_helper.dart';
import '../screens/AddOrder/AddOrderForm.dart';
import '../shared/appProvider.dart';
import '../main.dart';
import 'package:universal_html/html.dart' as html;

class Whatsapp extends StatefulWidget {
  @override
  _WhatsappState createState() => _WhatsappState();
}

class _WhatsappState extends State<Whatsapp>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AddOrderFormState> _addOrderFormKey =
      GlobalKey<AddOrderFormState>();
  final TextEditingController _aiInputController = TextEditingController();
  late TabController _tabController;
  bool _isProcessingAI = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _aiInputController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateFormField(String key, String value) {
    if (value.isEmpty || value == "null") return;

    final formState = _addOrderFormKey.currentState;
    if (formState == null) return;

    // The AddOrderForm has a list of shipments and also some top-level controllers.
    // We update the current active shipment if available.
    final currentShipment = formState.shipments.isNotEmpty
        ? formState.shipments[formState.currentShipmentIndex]
        : null;

    void setControllerText(TextEditingController controller) {
      controller.text = value;
    }

    setState(() {
      switch (key) {
        case 'recipientName':
          if (currentShipment != null)
            setControllerText(currentShipment.recipientNameController);
          setControllerText(formState.recipientNameController);
          break;
        case 'phone':
          if (currentShipment != null)
            setControllerText(currentShipment.phoneController);
          setControllerText(formState.phoneController);
          break;
        case 'address':
        case 'addressDescription':
          if (currentShipment != null)
            setControllerText(currentShipment.addressDescController);
          setControllerText(formState.addressDescController);
          break;
        case 'codAmount':
          if (currentShipment != null)
            setControllerText(currentShipment.codAmountController);
          setControllerText(formState.codAmountController);
          break;
        case 'deliveryCost':
          if (currentShipment != null)
            setControllerText(currentShipment.deliveryCostController);
          setControllerText(formState.deliveryCostController);
          break;
        case 'city':
          if (currentShipment != null) {
            currentShipment.selectedCity = value;
            currentShipment.citySearchController.text = value;
          }
          break;
        case 'content':
        case 'contents':
          if (currentShipment != null)
            setControllerText(currentShipment.contentController);
          setControllerText(formState.contentController);
          break;
        case 'weight':
          if (currentShipment != null)
            setControllerText(currentShipment.weightController);
          setControllerText(formState.weightController);
          break;
        case 'notes':
          if (currentShipment != null)
            setControllerText(currentShipment.notesController);
          setControllerText(formState.notesController);
          break;
      }
    });
  }

  Future<void> _processAiInput() async {
    if (_aiInputController.text.trim().isEmpty) return;

    setState(() => _isProcessingAI = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final results = await WhatsappAIHelper.parseMessage(
          _aiInputController.text, appProvider);

      results.forEach((key, value) {
        _updateFormField(key, value);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم استخراج البيانات وتعبئة النموذج بنجاح ✨'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _aiInputController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء معالجة النص: $e')),
      );
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Left Side: The Form
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: primary.withOpacity(0.05),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, color: primary),
                        const SizedBox(width: 12),
                        const Text(
                          'نموذج الطلب السريع',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primary),
                        ),
                        const Spacer(),
                        if (kIsWeb)
                          IconButton(
                            onPressed: () => html.window
                                .open('https://web.whatsapp.com', '_blank'),
                            icon: const Icon(Icons.launch,
                                size: 20, color: primary),
                            tooltip: 'فتح واتساب في صفحة جديدة',
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        AddOrderForm(key: _addOrderFormKey, isWhatsapp: true),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: WhatsApp / AI Tools
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primary,
                    indicatorWeight: 3,
                    tabs: [
                      const Tab(
                          icon: Icon(Icons.auto_awesome),
                          text: 'المستورد الذكي (AI)'),
                      Tab(
                          icon: const Icon(Icons.web),
                          text: kIsWeb ? 'واتساب' : 'واتساب المدمج'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAISmartImport(),
                      _buildWhatsAppView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISmartImport() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'استيراد ذكي من واتساب 🪄',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'انسخ نص الرسالة من واتساب وألصقه هنا، وسيقوم النظام بتعبئة الحقول أوتوماتيكياً.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: TextField(
                controller: _aiInputController,
                maxLines: null,
                expands: true,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText:
                      'ألصق محادثة الواتساب هنا...\nمثال: زبون جديد من عمان، شارع المدينة الجاردنز، هاتف 079... المبلغ 30 دينار والمحتويات ملابس.',
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: _isProcessingAI ? null : _processAiInput,
              icon: _isProcessingAI
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_fix_high),
              label: Text(
                _isProcessingAI
                    ? 'جاري استخراج البيانات...'
                    : 'تحليل النص وتعبئة النموذج',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppView() {
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.web, size: 100, color: Color(0xFF25D366)),
            const SizedBox(height: 32),
            const Text(
              'واتساب ويب (WhatsApp Web)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'بسبب سياسات الأمان في المتصفحات، يفضل فتح واتساب في نافذة منبثقة لضمان أفضل أداء وتواصل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => html.window.open('https://web.whatsapp.com',
                  'whatsapp', 'width=1100,height=800'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح في نافذة جانبية منبثقة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 60),
            _buildWebSecurityNote(),
          ],
        ),
      );
    }

    return WhatsappWebViewFactory.create(
      addOrderFormKey: _addOrderFormKey,
      onUpdateFormField: (item, text) =>
          _updateFormField(_getMenuKey(item), text),
    );
  }

  Widget _buildWebSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
              const SizedBox(width: 12),
              Text(
                'نصيحة للمحترفين:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'إذا كنت ترغب في رؤية واتساب "داخل" هذه الصفحة مباشرة، يمكنك تثبيت إضافة Chrome: "Ignore X-Frame-Options". هذا سيسمح للنظام بدمج واتساب بالكامل هنا.',
            style: TextStyle(fontSize: 14, color: Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }

  String _getMenuKey(int index) {
    switch (index) {
      case 1:
        return 'recipientName';
      case 2:
        return 'address';
      case 3:
        return 'deliveryCost';
      case 4:
        return 'codAmount';
      case 5:
        return 'notes';
      case 6:
        return 'phone';
      case 7:
        return 'content';
      case 8:
        return 'weight';
      default:
        return '';
    }
  }
}
