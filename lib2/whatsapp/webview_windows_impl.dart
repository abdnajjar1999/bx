import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:provider/provider.dart';
import '../shared/appProvider.dart';

class WhatsappWebViewWindows extends StatefulWidget {
  final GlobalKey<State> addOrderFormKey;
  final Function(int, String) onUpdateFormField;

  WhatsappWebViewWindows(
      {required this.addOrderFormKey, required this.onUpdateFormField});

  @override
  _WhatsappWebViewWindowsState createState() => _WhatsappWebViewWindowsState();
}

class _WhatsappWebViewWindowsState extends State<WhatsappWebViewWindows> {
  final _controller = WebviewController();
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
            setTimeout(addChatListListener, 1000);
          }
        }
        addChatListListener();
      ''');

      _controller.webMessage.listen((event) {
        if (event is Map) {
          final data = event;
          if (data['type'] == 'chatSelected') {
            final appProvider =
                Provider.of<AppProvider>(context, listen: false);
            appProvider.selectCustomerByNameOrPhone(data['name']);
          }
        }
      });
    } catch (e) {
      print('Error initializing webview_windows: $e');
    }
  }

  Future<void> toggleHeaderVisibility() async {
    if (showHeader) {
      await _controller.executeScript(
          'document.querySelector("header.xa1v5g2")?.style.display = "none";');
      await _controller.executeScript(
          'document.querySelector("div._aigw")?.style.display = "none";');
    } else {
      await _controller.executeScript(
          'document.querySelector("header.xa1v5g2")?.style.display = "flex";');
      await _controller.executeScript(
          'document.querySelector("div._aigw")?.style.display = "flex";');
    }
    setState(() => showHeader = !showHeader);
  }

  Future<String> getSelectedText() async {
    return await _controller.executeScript('window.getSelection().toString();');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Webview(
          _controller,
          permissionRequested: (url, permissionKind, isUserInitiated) async =>
              WebviewPermissionDecision.allow,
        ),
        StreamBuilder<LoadingState>(
          stream: _controller.loadingState,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == LoadingState.loading) {
              return const LinearProgressIndicator();
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}
