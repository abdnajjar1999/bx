import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'webview_stub.dart';
import 'webview_windows_impl.dart';

class WhatsappWebViewFactory {
  static Widget create({
    required GlobalKey<State> addOrderFormKey,
    required Function(int, String) onUpdateFormField,
  }) {
    if (kIsWeb) {
      return WhatsappWebViewStub(
        addOrderFormKey: addOrderFormKey,
        onUpdateFormField: onUpdateFormField,
      );
    }

    // For Windows, we use the specialized webview_windows
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return WhatsappWebViewWindows(
        addOrderFormKey: addOrderFormKey,
        onUpdateFormField: onUpdateFormField,
      );
    }

    // Default stub for other platforms
    return WhatsappWebViewStub(
      addOrderFormKey: addOrderFormKey,
      onUpdateFormField: onUpdateFormField,
    );
  }
}
