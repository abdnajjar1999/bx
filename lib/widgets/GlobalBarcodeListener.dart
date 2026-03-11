import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../shared/ScannerProvider.dart';

class GlobalBarcodeListener extends StatefulWidget {
  final Widget child;

  const GlobalBarcodeListener({Key? key, required this.child})
      : super(key: key);

  @override
  State<GlobalBarcodeListener> createState() => _GlobalBarcodeListenerState();
}

class _GlobalBarcodeListenerState extends State<GlobalBarcodeListener> {
  final BarcodeScanDetector _detector = BarcodeScanDetector();

  @override
  void initState() {
    super.initState();
    _detector.onBarcode = (code) {
      print('DEBUG SCANNER: Global onBarcode triggered: $code');
      _handleGlobalScan(code);
    };
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  void _handleGlobalScan(String code) {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    // 1. Get current route name
    String? currentRoute;
    navState.popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });

    // 2. Add to provider
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.read<ScannerProvider>().addShipment(code);
    }

    // 3. Navigate if not already on the screen
    if (currentRoute != '/barcodescanner') {
      navState.pushNamed('/barcodescanner');
    }
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
    _detector.dispose();
    super.dispose();
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final LogicalKeyboardKey key = event.logicalKey;
    String? char = event.character;

    // Fallback for character extraction if char is null
    if (char == null || char.isEmpty) {
      if (key.keyLabel.length == 1) {
        char = key.keyLabel;
      }
    }

    print('DEBUG SCANNER: Global Key=$key, Char=$char, Label=${key.keyLabel}');

    if (key == LogicalKeyboardKey.enter) {
      print('DEBUG SCANNER: Global ENTER detected');
      _detector.handleEnter();
      return;
    }
    if (key == LogicalKeyboardKey.tab) {
      print('DEBUG SCANNER: Global TAB detected');
      _detector.handleTerminator('TAB');
      return;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _detector.handleBackspace();
      return;
    }

    if (char == null || char.isEmpty) {
      return;
    }
    if (!_isPrintable(char)) return;

    _detector.handleChar(char);
  }

  bool _isPrintable(String s) {
    final int code = s.codeUnitAt(0);
    if (code >= 32 && code <= 126) return true;
    return !RegExp(r"\s").hasMatch(s);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class BarcodeScanDetector {
  final Duration idleFlush;
  final Duration maxAvgKeyInterval;
  final int minLength;

  void Function(String code)? onBarcode;

  final List<int> _timestamps = <int>[];
  final StringBuffer _buffer = StringBuffer();
  Timer? _idleTimer;

  BarcodeScanDetector({
    this.idleFlush = const Duration(milliseconds: 100),
    this.maxAvgKeyInterval = const Duration(milliseconds: 80),
    this.minLength = 6,
  });

  void handleChar(String char) {
    _appendChar(char);
    _scheduleFlush();
  }

  void handleBackspace() {
    if (_buffer.isNotEmpty) {
      _clearIdleTimer();
      _buffer.clear();
      _timestamps.clear();
      _scheduleFlush();
    }
  }

  void handleEnter() {
    _finishBurst(force: true);
  }

  void handleTerminator(String _label) {
    _finishBurst(force: true);
  }

  void _appendChar(String char) {
    _buffer.write(char);
    _timestamps.add(DateTime.now().millisecondsSinceEpoch);
  }

  void _scheduleFlush() {
    _clearIdleTimer();
    _idleTimer = Timer(idleFlush, _finishBurst);
  }

  void _clearIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  double getCurrentAvg() {
    if (_timestamps.length < 2) return 0;
    int totalIntervals = 0;
    for (int i = 1; i < _timestamps.length; i++) {
      totalIntervals += (_timestamps[i] - _timestamps[i - 1]);
    }
    return totalIntervals / (_timestamps.length - 1);
  }

  void _finishBurst({bool force = false}) {
    _clearIdleTimer();
    final text = _buffer.toString();
    if (text.isEmpty) return;

    double avg = getCurrentAvg();
    bool isBarcode = (avg > 0 && avg <= maxAvgKeyInterval.inMilliseconds) &&
        (text.length >= minLength);

    if (force) {
      isBarcode = text.length >= minLength && (isBarcode || true);
    }

    print('DEBUG SCANNER: Burst Text="$text", Avg=$avg ms, IsBarcode=$isBarcode');

    if (isBarcode) {
      print('DEBUG SCANNER: TRIGGERING onBarcode for "$text"');
      onBarcode?.call(text);
    }

    _buffer.clear();
    _timestamps.clear();
  }

  void dispose() {
    _clearIdleTimer();
  }
}
