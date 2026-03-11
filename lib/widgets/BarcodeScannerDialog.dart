import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final Function(String) onScan;
  final Function(String)? onManualInput;
  final bool showManualInput;

  const BarcodeScannerDialog({
    Key? key,
    this.title = 'مسح الباركود',
    this.initialValue,
    required this.onScan,
    this.onManualInput,
    this.showManualInput = true,
  }) : super(key: key);

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.stop();
    cameraController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 500,
          height: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildScanner(),
              const SizedBox(height: 20),
              _buildInstructions(),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4C4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Color(0xFFDEB887),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildScanner() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                final String? code = capture.barcodes.first.rawValue;
                if (code != null) {
                  widget.onScan(code);

                  //add mp3 sound to the project
                

                  //play the sound
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Text(
      'وجه الكاميرا نحو الباركود للمسح',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'إلغاء',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        if (widget.showManualInput) ...[
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualInputDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA07A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إدخال يدوي'),
          ),
        ],
      ],
    );
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController(
      text: widget.initialValue,
    );

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'باركود الطرد',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            if (widget.onManualInput != null) {
                              widget.onManualInput!(controller.text);
                            } else {
                              widget.onScan(controller.text);
                            }
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA07A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('مسح'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
