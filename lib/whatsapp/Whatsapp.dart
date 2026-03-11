import '../screens/AddOrder/AddOrderForm.dart';
import '../shared/appProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:flutter/gestures.dart';

class Whatsapp extends StatefulWidget {
  @override
  _WhatsappState createState() => _WhatsappState();
}

class _WhatsappState extends State<Whatsapp> {
  final _controller = WebviewController();
  final _addOrderFormKey = GlobalKey<AddOrderFormState>();
  String src = 'https://web.whatsapp.com';
  bool showHeader = true;
  bool showSecondHeader = true;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      await _controller.loadUrl('https://web.whatsapp.com');

      // Add listener for chat list item selections
      await _controller.executeScript('''
        function addChatListListener() {
          const chatList = document.querySelector('div[role="grid"]');
          if (chatList) {
            chatList.addEventListener('click', function(event) {
              const listItem = event.target.closest('div[role="listitem"]');
              if (listItem) {
                const nameElement = listItem.querySelector('span[title]');
                const name = nameElement ? nameElement.title : '';
                window.chrome.webview.postMessage({
                  type: 'chatSelected',
                  name: name
                });
              }
            });
          } else {
            setTimeout(addChatListListener, 1000); // Retry if list not found
          }
        }
        addChatListListener();
      ''');
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      _controller.webMessage.listen((event) {
        print('event: $event');
        if (event is Map) {
          final data = event;
          if (data['type'] == 'chatSelected') {
            print('Selected chat: ${data['name']}');

            appProvider.selectCustomerByNameOrPhone(data['name']);
          }
        }
      });
    } catch (e) {
      print('Error initializing webview: $e');
    }
  }

  Future<void> toggleHeaderVisibility() async {
    if (showHeader) {
      await _controller.executeScript(
          'document.querySelector("header.xa1v5g2").style.display = "none";');
      await _controller.executeScript(
          'document.querySelector("div._aigw").style.display = "none";');
    } else {
      await _controller.executeScript(
          'document.querySelector("header.xa1v5g2").style.display = "flex";');
      await _controller.executeScript(
          'document.querySelector("div._aigw").style.display = "flex";');
    }
    setState(() {
      showHeader = !showHeader;
    });
  }

  Future<void> toggleSecondHeaderVisibility() async {
    if (showSecondHeader) {
      await _controller.executeScript(
          'document.querySelector("#app > div > div.x78zum5.xdt5ytf.x5yr21d > div > div._aigw.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.x1w8yi2h.x78zum5.xdt5ytf.xa1v5g2.x1plvlek.xryxfnj.xd32934").style.display = "none";');
    } else {
      await _controller.executeScript(
          'document.querySelector("#app > div > div.x78zum5.xdt5ytf.x5yr21d > div > div._aigw.x9f619.x1n2onr6.x5yr21d.x17dzmu4.x1i1dayz.x2ipvbc.x1w8yi2h.x78zum5.xdt5ytf.xa1v5g2.x1plvlek.xryxfnj.xd32934").style.display = "flex";');
    }
    setState(() {
      showSecondHeader = !showSecondHeader;
    });
  }

  Future<String> getSelectedText() async {
    var text =
        await _controller.executeScript('window.getSelection().toString();');
    print(text);
    return text;
  }

  Future<void> clickMessageYourselfButton() async {
    await _controller.executeScript(
        "document.getElementsByClassName('x1c4vz4f x2lah0s xdl72j9 x1i4ejaq x1y332i5')[0].click()");
    var number = await _controller.executeScript(
        "document.querySelector('#app > div > div.x78zum5.xdt5ytf.x5yr21d > div > div._aig-.x9f619.x1n2onr6.xyw6214.x5yr21d.x6ikm8r.x10wlt62.x17dzmu4.x1i1dayz.x2ipvbc.x1w8yi2h.xy80clv.x26u7qi.x1ux35ld > span > div > span > div > div > section > div.x13mwh8y.x1q3qbx4.x1wg5k15.x1bnvlk4.x1n2onr6.x1c4vz4f.x2lah0s.xdl72j9.xyorhqc.x13x2ugz.x7sb2j6.x6x52a7.x1i2zvha.xxpdul3 > div.x1c4vz4f.xs83m0k.xdl72j9.x1g77sc7.x78zum5.xozqiw3.x1oa3qoh.x12fk4p8.xeuugli.x2lwn1j.x1nhvcw1.xdt5ytf.x6s0dn4 > div > span > span').textContent;");
    print(number);
    await _controller.executeScript(
        "document.querySelector('#app > div > div.x78zum5.xdt5ytf.x5yr21d > div > div._aig-.x9f619.x1n2onr6.xyw6214.x5yr21d.x6ikm8r.x10wlt62.x17dzmu4.x1i1dayz.x2ipvbc.x1w8yi2h.xy80clv.x26u7qi.x1ux35ld > span > div > span > div > header > div > div.x1okw0bk.x1fxk84t > div > span').click();");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Selected chat: $number'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> scrollWebview(
      double mouseX, double mouseY, double dx, double dy) {
    return _controller.executeScript("""
            function eleCanScroll(ele) {
              if (ele.scrollTop > 0) { return ele; }
              else {
                ele.scrollTop++;
                const top = ele.scrollTop;
                top && (ele.scrollTop = 0);
                if(top > 0){
                  return ele;
                } else {
                  return eleCanScroll(ele.parentElement);
                }
              }
            }
            var el = document.elementFromPoint($mouseX,$mouseY);
            var el2 = eleCanScroll(el);
            el2.scrollBy($dx,$dy);
            """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: clickMessageYourselfButton,
            tooltip: 'رقم التلفون',
            child: Icon(Icons.phone),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: toggleSecondHeaderVisibility,
            tooltip: showSecondHeader ? 'Hide Header' : 'Show Header',
            child: Icon(
                showSecondHeader ? Icons.visibility : Icons.visibility_off),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: toggleHeaderVisibility,
            tooltip: showHeader ? 'Hide Header' : 'Show Header',
            child: Icon(showHeader ? Icons.visibility : Icons.visibility_off),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: AddOrderForm(key: _addOrderFormKey, isWhatsapp: true),
          ),
          Expanded(
            flex: 2,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerPanZoomUpdate: (event) {
                final Offset panDelta = event.panDelta;
                final Offset position = event.position;
                scrollWebview(
                    position.dx, position.dy, panDelta.dx, panDelta.dy);
              },
              onPointerSignal: (signal) {
                if (signal is PointerScrollEvent) {
                  final Offset scrollDelta = signal.scrollDelta;
                  final Offset position = signal.position;
                  scrollWebview(
                      position.dx, position.dy, scrollDelta.dx, scrollDelta.dy);
                }
              },
              child: Stack(
                children: [
                  Webview(
                    _controller,
                    permissionRequested:
                        (url, permissionKind, isUserInitiated) async =>
                            WebviewPermissionDecision.allow,
                  ),
                  StreamBuilder<LoadingState>(
                    stream: _controller.loadingState,
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data == LoadingState.loading) {
                        return const LinearProgressIndicator();
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateFormField(int menuItem, String text) {
    Clipboard.setData(ClipboardData(text: text));

    final formState = _addOrderFormKey.currentState;
    if (formState != null) {
      switch (menuItem) {
        case 1:
          formState.recipientNameController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم تحديث اسم المستلم'),
            behavior: SnackBarBehavior.floating,
          ));
          break;
        case 2:
          formState.addressDescController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث وصف العنوان'),
              behavior: SnackBarBehavior.floating));
          break;
        case 3:
          formState.deliveryCostController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث سعر التوصيل المحصل'),
              behavior: SnackBarBehavior.floating));
          break;
        case 4:
          formState.codAmountController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث التحصيل شامل التوصيل'),
              behavior: SnackBarBehavior.floating));
          break;
        case 5:
          formState.notesController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث الملاحظات'),
              behavior: SnackBarBehavior.floating));
          break;
        case 6:
          formState.phoneController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث رقم الهاتف'),
              behavior: SnackBarBehavior.floating));
          break;
        case 7:
          formState.contentController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث محتوى الطرد'),
              behavior: SnackBarBehavior.floating));
          break;
        case 8:
          formState.weightController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث الوزن'),
              behavior: SnackBarBehavior.floating));
          break;
        case 9:
          formState.trackingNumberController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تحديث رقم التتبع'),
              behavior: SnackBarBehavior.floating));
          break;
        default:
      }
    }
  }

  /// Callback when mouse clicked on `Listener` wrapped widget.
  Future<void> _onPointerDown(PointerDownEvent event) async {
    // Check if right mouse button clicked
    String text = await getSelectedText();
    print(text);

    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kSecondaryMouseButton &&
        text.isNotEmpty) {
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final menuItem = await showMenu<int>(
          context: context,
          items: [
            PopupMenuItem(child: Text('اسم المستلم'), value: 1),
            PopupMenuItem(child: Text('وصف العنوان'), value: 2),
            PopupMenuItem(child: Text('سعر التوصيل المحصل'), value: 3),
            PopupMenuItem(child: Text('التحصيل شامل التوصيل'), value: 4),
            PopupMenuItem(child: Text('الملاحظات'), value: 5),
            PopupMenuItem(child: Text('رقم الهاتف'), value: 6),
            PopupMenuItem(child: Text('محتوى الطرد'), value: 7),
            PopupMenuItem(child: Text('الوزن'), value: 8),
            PopupMenuItem(child: Text('رقم التتبع'), value: 9),
          ],
          position: RelativeRect.fromSize(
              event.position & Size(48.0, 48.0), overlay.size));

      if (menuItem != null) {
        _updateFormField(menuItem, text);
      }
    }
  }
}
