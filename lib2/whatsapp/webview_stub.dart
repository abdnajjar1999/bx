import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

abstract class WhatsappWebView extends StatefulWidget {
  final GlobalKey<State> addOrderFormKey;
  final Function(int, String) onUpdateFormField;

  WhatsappWebView(
      {required this.addOrderFormKey, required this.onUpdateFormField});
}

class WhatsappWebViewStub extends WhatsappWebView {
  WhatsappWebViewStub(
      {required super.addOrderFormKey, required super.onUpdateFormField});

  @override
  _WhatsappWebViewStubState createState() => _WhatsappWebViewStubState();
}

class _WhatsappWebViewStubState extends State<WhatsappWebViewStub> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.web_asset_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('المتصفح المدمج غير مدعوم على هذه المنصة حالياً'),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Open in new tab
              html.window.open('https://web.whatsapp.com', '_blank');
            },
            icon: Icon(Icons.open_in_new),
            label: Text('فتح واتساب في نافذة جديدة'),
          ),
        ],
      ),
    );
  }
}
