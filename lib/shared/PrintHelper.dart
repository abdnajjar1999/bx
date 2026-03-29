import 'dart:math';

import 'package:good_line_delivery/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as a;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/Inventory.dart';
import '../models/UserAccount.dart';
import '../utils/file_handler.dart';
import 'dart:ui' as ui;

import '../models/DriverDeliveryData.dart';
import '../models/Shipment.dart';
import '../models/Expense.dart';
import '../models/Transfer.dart';

// Extension method for Iterables to add mapIndexed functionality
extension IterableExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E item) f) {
    var index = 0;
    return map((item) => f(index++, item));
  }
}

class PrintHandler {
  // Add class-level variable to store the loaded image
  pw.MemoryImage? _logoImage;

  // Add method to lazily load the image
  Future<pw.MemoryImage> _getLogoImage() async {
    if (_logoImage == null) {
      try {
        _logoImage = pw.MemoryImage(
          (await rootBundle.load('assets/images/' + $KcompanyLogo))
              .buffer
              .asUint8List(),
        );
      } catch (e) {
        // Create a default placeholder image if no logo is found
        debugPrint('No logo found. Using default placeholder.');
        // Create a simple colored rectangle as placeholder
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()..color = const Color(0xFF2196F3);
        canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 50), paint);
        final picture = recorder.endRecording();
        final img = await picture.toImage(100, 50);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        _logoImage = pw.MemoryImage(byteData!.buffer.asUint8List());
      }
    }

    return _logoImage!;
  }

  Future<void> printShipmentsDocument(List<Shipment> shipments,
      {String pageFormatString = "a5",
      String? driverName,
      String? bundleId}) async {
    _logoImage ??= await _getLogoImage();
    PdfPageFormat pageFormat;
    if (pageFormatString == "a5") {
      pageFormat = PdfPageFormat.a5;
    } else {
      pageFormat = PdfPageFormat.a4;
    }
    double totalAmount =
        shipments.fold(0, (sum, shipment) => sum + shipment.codAmount);
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();

    // First page shows 10 items, subsequent pages show 13 items each

    int firstPageItems = 18;
    int itemsPerPage = 22;

    if (pageFormatString == "a5") {
      firstPageItems = 13;
      itemsPerPage = 18;
    }

    // Calculate total pages needed
    int remainingItems = shipments.length - firstPageItems;
    int additionalPages =
        remainingItems > 0 ? (remainingItems / itemsPerPage).ceil() : 0;
    int totalPages = 1 + additionalPages;

    // Create first page outside the loop
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header for first page
              pw.Container(
                padding: const pw.EdgeInsets.all(1),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(_logoImage!, width: 50),
                    if (bundleId == null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'التاريخ: ${a.DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: arabicFont, fontSize: 8),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'عدد الطلبات: ${shipments.length}',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(font: arabicFont, fontSize: 8),
                          ),
                          if (driverName != null) ...[
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'اسم السائق: $driverName',
                              textDirection: pw.TextDirection.rtl,
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ],
                        ],
                      ),
                    if (bundleId != null)
                      pw.Row(
                        children: [
                          pw.BarcodeWidget(
                            data: bundleId,
                            barcode: pw.Barcode.qrCode(),
                            width: 70,
                            height: 70,
                          ),
                          pw.SizedBox(width: 10),
                          pw.BarcodeWidget(
                            data: bundleId,
                            barcode: pw.Barcode.code128(),
                            width: 70,
                            height: 70,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: const {
                    // Flipped columns, so comments are not updated here
                  },
                  children: [
                    // Table header for first page (flipped)
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.brown),
                      children: [
                        'COD',
                        //'تاريخ الحجز',
                        'الملاحظات',
                        'العنوان',
                        'الهاتف',
                        //'اسم المستلم',
                        //'هاتف المرسل',
                        'المرسل',
                        'رقم',
                        'م',
                      ]
                          .map((text) => _buildHeaderCell(text, arabicFont))
                          .toList(),
                    ),
                    // First page shipments - show first 10 items with index (flipped)
                    ...List.generate(shipments.take(firstPageItems).length,
                        (index) {
                      final shipment = shipments[index];
                      return pw.TableRow(
                        children: [
                          _buildPdfCell2(
                              shipment.codAmount.toString(), arabicFont),
                          // _buildPdfCell2(
                          // a.DateFormat('dd/MM/yyyy\nHH:mm')
                          //     .format(shipment.createdAt),
                          //arabicFont),
                          _buildPdfCell2(shipment.notes, arabicFont,
                              isFlex: false),
                          _buildPdfCell2(
                              shipment.city +
                                  ", " +
                                  shipment.addressDescription,
                              arabicFont),
                          _buildPdfCell2(shipment.phoneNumber, arabicFont),
                          // _buildPdfCell2(shipment.recipientName, arabicFont),
                          //_buildPdfCell2(shipment.userphone ?? '', arabicFont),
                          _buildPdfCell2(shipment.username ?? '', arabicFont),
                          _buildPdfCell2(shipment.orderId, arabicFont),
                          _buildPdfCell2((index + 1).toString(), arabicFont),
                        ],
                      );
                    }),
                    // Show total row only if there's just one page (flipped)
                    if (totalPages == 1)
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildPdfCell2(totalAmount.toString(), arabicFont),
                          _buildPdfCell2('المجموع', arabicFont),
                          ...List.generate(
                              4, (_) => _buildPdfCell2('', arabicFont)),
                          _buildPdfCell2('', arabicFont),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Create remaining pages in the loop (starting from page 2)
    if (shipments.length > firstPageItems) {
      for (int i = 0; i < additionalPages; i++) {
        // Get items for current page
        int start = firstPageItems + (i * itemsPerPage);
        int end = start + itemsPerPage;
        if (end > shipments.length) end = shipments.length;

        final pageShipments = shipments.sublist(start, end);

        doc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: const {
                        // Flipped columns, so comments are not updated here
                      },
                      children: [
                        // Table header for each page (flipped)
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.brown),
                          children: [
                            'COD',
                            //'العدد',
                            //'محتوى الطرد',
                            //'تاريخ الحجز',
                            'الملاحظات',
                            'العنوان',
                            'هاتف المستلم',
                            // 'اسم المستلم',
                            //'هاتف المرسل',
                            'اسم المرسل',
                            'رقم الطرد',
                            'م',
                          ]
                              .map((text) => _buildHeaderCell(text, arabicFont))
                              .toList(),
                        ),
                        // Current page shipments with sequential numbering (flipped)
                        ...List.generate(pageShipments.length, (index) {
                          final shipment = pageShipments[index];
                          return pw.TableRow(
                            children: [
                              _buildPdfCell2(
                                  shipment.codAmount.toString(), arabicFont),
                              //_buildPdfCell2(
                              //shipment.parcelCount.toString(), arabicFont),
                              //_buildPdfCell2(shipment.contents, arabicFont),
                              // _buildPdfCell2(
                              //     a.DateFormat('dd/MM/yyyy\nHH:mm')
                              //         .format(shipment.createdAt),
                              //   arabicFont),
                              _buildPdfCell2(shipment.notes, arabicFont,
                                  isFlex: false),
                              _buildPdfCell2(
                                  shipment.city +
                                      ", " +
                                      shipment.addressDescription,
                                  arabicFont),
                              _buildPdfCell2(shipment.phoneNumber, arabicFont),
                              //_buildPdfCell2(
                              //  shipment.recipientName, arabicFont),
                              //_buildPdfCell2(
                              //shipment.userphone ?? '', arabicFont),
                              _buildPdfCell2(
                                  shipment.username ?? '', arabicFont),
                              _buildPdfCell2(shipment.orderId, arabicFont),
                              _buildPdfCell2(
                                  (start + index + 1).toString(), arabicFont),
                            ],
                          );
                        }),
                        // Show total row only on the last page (flipped)
                        if (i == additionalPages - 1)
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                                color: PdfColors.grey200),
                            children: [
                              _buildPdfCell2(
                                  totalAmount.toString(), arabicFont),
                              _buildPdfCell2('المجموع', arabicFont),
                              ...List.generate(
                                  4, (_) => _buildPdfCell2('', arabicFont)),
                              _buildPdfCell2('', arabicFont),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    await Printing.layoutPdf(
      format: pageFormat,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  pw.Widget _buildHeaderCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(color: PdfColors.white),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        // softWrap: true,
        maxLines: 1,
        style: pw.TextStyle(
          font: font,
          color: PdfColors.black,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildPdfCell2(String text, pw.Font font, {bool isFlex = true}) {
    // todo: make it dynamic
    double fontSize = 7;
    if (text.length > 11) {
      fontSize = 4;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(color: PdfColors.white),
      child: pw.Text(
        text,
        // softWrap: true,
        maxLines: 1,
        style: pw.TextStyle(
          font: font,
          color: PdfColors.black,
          fontSize: fontSize,
          fontWeight: fontSize == 4 ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  Future<String?> printDriverDeliveryDataDocument(
      DriverDeliveryData deliveryData,
      {bool? isDownload,
      bool? isMessage}) async {
    try {
      _logoImage ??= await _getLogoImage();
      final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
      final arabicBoldFont = await PdfGoogleFonts.notoNaskhArabicRegular();
      final doc = pw.Document();
      int itemsPerPage = 9;
      int pages = (deliveryData.shipments.length / itemsPerPage).ceil();

      for (int i = 0; i < pages; i++) {
        int start = i * itemsPerPage;
        int end = start + itemsPerPage;
        if (end > deliveryData.shipments.length)
          end = deliveryData.shipments.length;

        final pageShipments = deliveryData.shipments.sublist(start, end);
        doc.addPage(
          pw.Page(
            // pageFormat: PdfPageFormat.a4.landscape,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  if (i == 0) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(_logoImage!, width: 100, height: 50),
                        pw.Text(
                          KcompanyName,
                          style: pw.TextStyle(font: arabicFont, fontSize: 18),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'تاريخ الطباعة: ${a.DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                                style: pw.TextStyle(
                                    font: arabicFont, fontSize: 18),
                                textDirection: pw.TextDirection.rtl,
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'تقرير إستلام التحصيلات',
                                style: pw.TextStyle(
                                    font: arabicFont, fontSize: 18),
                                textDirection: pw.TextDirection.rtl,
                              ),
                              pw.Text(
                                'إسم المحصل: ${deliveryData.driverName}',
                                style: pw.TextStyle(font: arabicFont),
                                textDirection: pw.TextDirection.rtl,
                              ),
                              pw.Text(
                                'عدد الشحنات: ${deliveryData.parcelCount}',
                                style: pw.TextStyle(font: arabicFont),
                                textDirection: pw.TextDirection.rtl,
                              ),
                              pw.Text(
                                'تاريخ الاستلام: ${a.DateFormat('dd/MM/yyyy HH:mm').format(deliveryData.deliveryDate)}',
                                style: pw.TextStyle(font: arabicFont),
                                textDirection: pw.TextDirection.rtl,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(1),
                      3: pw.FlexColumnWidth(1.5),
                      4: pw.FlexColumnWidth(2),
                      5: pw.FlexColumnWidth(1.5),
                      6: pw.FlexColumnWidth(1.5),
                      7: pw.FlexColumnWidth(1.5),
                      8: pw.FlexColumnWidth(1.5),
                      9: pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey),
                        children: [
                          'السعر',
                          'نصيب السائق',
                          'COD',

                          //'أجرة النقل',
                          //'رقم الإرسالية',
                          'العنوان التفصيلي',
                          'الملاحظات',
                          "رقم المستلم",
                          'اسم المستلم',

                          'تاريخ التوصيل',
                          'اسم المرسل',
                          'باركود'
                        ]
                            .map((text) => pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(text,
                                      style: pw.TextStyle(font: arabicBoldFont),
                                      textDirection: pw.TextDirection.rtl),
                                ))
                            .toList(),
                      ),
                      ...pageShipments.map((shipment) => pw.TableRow(
                            children: [
                              shipment.deliveryCost.toString(),
                              shipment.driverPrice.toString(),
                              (shipment.status != 'تم إرجاعها'
                                      ? shipment.codAmount
                                      : 0)
                                  .toString(),

                              // shipment.trackingNumber,
                              // shipment.orderId,
                              shipment.addressDescription,
                              shipment.notes,
                              shipment.phoneNumber,
                              shipment.recipientName,
                              a.DateFormat('dd/MM/yyyy')
                                  .format(shipment.createdAt),
                              shipment.username ?? '',
                              shipment.orderId,
                            ]
                                .map((text) => pw.Container(
                                      alignment: pw.Alignment.center,
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Text(text,
                                          maxLines: 1,
                                          style: pw.TextStyle(font: arabicFont),
                                          textDirection: pw.TextDirection.rtl),
                                    ))
                                .toList(),
                          )),
                      if (i == pages - 1) ...[
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(deliveryData.price.toString(),
                                  style: pw.TextStyle(font: arabicFont)),
                            ),
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  deliveryData.driverPrice.toString(),
                                  style: pw.TextStyle(font: arabicFont)),
                            ),
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  deliveryData.totalCollections.toString(),
                                  style: pw.TextStyle(font: arabicFont)),
                            ),
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text('المجموع',
                                  style: pw.TextStyle(font: arabicBoldFont),
                                  textDirection: pw.TextDirection.rtl),
                            ),
                            ...List.generate(
                                6,
                                (_) => pw.Container(
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Text('',
                                          style:
                                              pw.TextStyle(font: arabicFont)),
                                    )),
                          ],
                        ),
                      ]
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
      print("done printing");

      if (isDownload != true) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => doc.save(),
        );
        return null;
      } else {
        Uint8List pdfBytes = await doc.save();
        String? firebaseUrl;

        if (deliveryData.shipments.isNotEmpty) {
          firebaseUrl = await FileHandler.downloadFile(pdfBytes,
              'driver_receipt_${deliveryData.driverName}_${a.DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.pdf',
              phoneNumber:
                  isMessage == true && deliveryData.shipments.isNotEmpty
                      ? deliveryData.shipments.first.phoneNumber
                      : null,
              shipment: deliveryData.shipments.first);
        } else {
          firebaseUrl = await FileHandler.downloadFile(pdfBytes,
              'driver_receipt_${deliveryData.driverName}_${a.DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.pdf');
        }

        return firebaseUrl;
      }
    } catch (e) {
      debugPrint('Error generating driver receipt PDF: $e');
      return null;
    }
  }

  Future<String?> printUserAccountDocument(UserAccount account,
      {bool? isDownload, bool? isMessage}) async {
    try {
      final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
      final doc = pw.Document();
      _logoImage ??= await _getLogoImage();

      int itemsPerPage = 13;
      int pages = (account.shipments.length / itemsPerPage).ceil();

      for (int i = 0; i < pages; i++) {
        // Get items for current page
        int start = i * itemsPerPage;
        int end = start + itemsPerPage;
        if (end > account.shipments.length) end = account.shipments.length;

        final pageShipments = account.shipments.sublist(start, end);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Logo and company name
                  if (i == 0) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          children: [
                            pw.Image(_logoImage!, width: 100, height: 50),
                            pw.SizedBox(height: 10),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 20),

                    // Print date and client info
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'تاريخ الطباعة: ${a.DateFormat('HH:mm yyyy/MM/dd').format(DateTime.now())}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 18),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'اسم الزبون: ${account.client}',
                              style: pw.TextStyle(font: arabicFont),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.Text(
                              '${account.client} ${account.id}',
                              style: pw.TextStyle(font: arabicFont),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.Text(
                              account.location ?? 'عمان',
                              style: pw.TextStyle(font: arabicFont),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 20),

                    pw.Text(
                      'تقرير التحصيلات',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: arabicFont, fontSize: 18),
                      textDirection: pw.TextDirection.rtl,
                    ),

                    pw.SizedBox(height: 10),

                    pw.Text(
                      'عدد الشحنات: ${account.shipments.length}',
                      style: pw.TextStyle(font: arabicFont),
                      textDirection: pw.TextDirection.rtl,
                    ),

                    pw.Text(
                      '(مجموع سعر التوصيل: ${account.servicesFees} / عمولة التحويل: 0)',
                      style: pw.TextStyle(font: arabicFont),
                      textDirection: pw.TextDirection.rtl,
                    ),

                    pw.SizedBox(height: 20),
                  ],
                  // Shipments table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    defaultVerticalAlignment:
                        pw.TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.0), // COD
                      1: pw.FlexColumnWidth(1.0), // السعر
                      2: pw.FlexColumnWidth(1.0), // الإجمالي
                      3: pw.FlexColumnWidth(1.5), // الحالة
                      4: pw.FlexColumnWidth(1.5), // متحمل التكلفه
                      5: pw.FlexColumnWidth(2.0), // اسم المستلم
                      6: pw.FlexColumnWidth(2.5), // هاتف المستلم (أوسع)
                      7: pw.FlexColumnWidth(1.2), // التاريخ
                      8: pw.FlexColumnWidth(1.5), // مدينة المستلم
                      9: pw.FlexColumnWidth(2.2), // باركود (أوسع)
                    },
                    children: [
                      // Table header
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          'COD',
                          'السعر',
                          'الإجمالي',
                          'الحالة',
                          "متحمل التكلفه",
                          'اسم المستلم',
                          'هاتف المستلم',
                          'التاريخ',
                          'مدينة المستلم',
                          'باركود',
                        ]
                            .map((text) => pw.Container(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    text,
                                    style: pw.TextStyle(
                                        font: arabicFont, fontSize: 7),
                                    textDirection: pw.TextDirection.rtl,
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ))
                            .toList(),
                      ),
                      // Shipment rows
                      ...pageShipments.map((shipment) => pw.TableRow(
                            children: [
                              _buildPdfCell(
                                  '${shipment.status != 'تم إرجاعها' ? (shipment.codAmount ?? 0) : 0}',
                                  arabicFont),
                              _buildPdfCell(
                                  shipment.status == 'تم إرجاعها'
                                      ? (shipment.getMoneyFromUserPalance
                                          ? shipment.deliveryCost.toString()
                                          : "0")
                                      : '-',
                                  arabicFont),
                              _buildPdfCell(
                                  '${(shipment.status != 'تم إرجاعها' ? ((shipment.codAmount ?? 0) - (shipment.deliveryCost ?? 0)) : (shipment.deliveryCost ?? 0)).toStringAsFixed(2)}',
                                  arabicFont),
                              _buildPdfCell(
                                  shipment.status ?? 'غير معروف', arabicFont),
                              _buildPdfCell(
                                  shipment.status == 'تم إرجاعها'
                                      ? (shipment.getMoneyFromUserPalance
                                          ? "الزبون"
                                          : "الشركه")
                                      : '-',
                                  arabicFont),
                              _buildPdfCell(
                                  shipment.recipientName ?? "", arabicFont),
                              _buildPdfCell(
                                  shipment.phoneNumber ?? "", arabicFont),
                              _buildPdfCell(
                                  a.DateFormat('dd/MM/yy')
                                      .format(shipment.createdAt),
                                  arabicFont),
                              _buildPdfCell(
                                  shipment.city ?? "عمان", arabicFont),
                              _buildPdfCell(shipment.orderId ?? "", arabicFont),
                            ],
                          )),
                      // Total row
                      if (i == pages - 1) ...[
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _buildPdfCell(
                              '${account.totalAmount.toStringAsFixed(2)}',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              '${account.servicesFees.toStringAsFixed(2)}',
                              arabicFont,
                            ),
                            _buildPdfCell(
                              '${(account.totalAmount - account.servicesFees).toStringAsFixed(2)}',
                              arabicFont,
                            ),
                            _buildPdfCell('المجموع', arabicFont),
                            ...List.generate(
                                6, (_) => _buildPdfCell('', arabicFont)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
      // Second page - سند صرف
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Logo and header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Image(_logoImage!, width: 100, height: 50),
                        pw.SizedBox(height: 10),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          account.client,
                          style: pw.TextStyle(font: arabicFont, fontSize: 16),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          account.location ?? 'عمان',
                          style: pw.TextStyle(font: arabicFont, fontSize: 16),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Barcode

                pw.SizedBox(height: 20),

                // Receipt text
                pw.Text(
                  'سند صرف',
                  style: pw.TextStyle(font: arabicFont, fontSize: 20),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl,
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'استلمت انا الموقع ادناه ${account.client} من $KcompanyName مبلغ وقدره ${account.totalAmount - account.servicesFees} نقدا، وذلك',
                  style: pw.TextStyle(font: arabicFont, fontSize: 14),
                  textDirection: pw.TextDirection.rtl,
                ),

                pw.Text(
                  'عن تحصيلات الطرود المذكورة في كشف التحصيل رقم ${account.id}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 14),
                  textDirection: pw.TextDirection.rtl,
                ),

                pw.Spacer(),

                // Signature fields
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'المستلم:____________',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          'التاريخ:____________',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          'التوقيع:____________',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      if (isDownload != true) {
        await Printing.layoutPdf(
          onLayout: (format) => doc.save(),
        );
        return null;
      } else {
        Uint8List pdfBytes = await doc.save();
        String firebaseUrl = await FileHandler.downloadFile(
            pdfBytes, 'account.pdf',
            phoneNumber:
                isMessage == true ? account.shipments.first.userphone : null,
            shipment: account.shipments.first);
        print(firebaseUrl);
        return firebaseUrl;
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      // We can't show UI errors here without a context, so just log the error
    }
  }

  pw.Widget _buildPdfCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        maxLines: 3,
        text,
        style: pw.TextStyle(font: font, fontSize: 7),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  Future<void> printShipmentReceipt(List<Shipment> shipments) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();
    _logoImage ??= await _getLogoImage();

    for (var shipment in shipments) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Customer Copy
                pw.Expanded(
                  child: _buildReceiptSection(
                    shipment: shipment,
                    arabicFont: arabicFont,
                    title: 'نسخة العميل',
                  ),
                ),

                // Divider
                pw.Container(
                  height: 2,
                  color: PdfColors.grey400,
                  margin: const pw.EdgeInsets.symmetric(vertical: 10),
                ),

                // Company Copy
                pw.Expanded(
                  child: _buildReceiptSection(
                    shipment: shipment,
                    arabicFont: arabicFont,
                    title: 'نسخة الشركة',
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> printShipmentReceiptWithLogs(List<Shipment> shipments) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();
    _logoImage ??= await _getLogoImage();

    for (var shipment in shipments) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildReceiptSection(
                shipment: shipment,
                arabicFont: arabicFont,
                title: 'نسخة الشحنة مع الحركات',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'سجل الحركات (Logs)',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'الملاحظة',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'الحالة',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'التاريخ',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                  ...shipment.logs.reversed.map((log) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            log.text,
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            log.status ?? '-',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            a.DateFormat('yyyy/MM/dd HH:mm').format(log.date),
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  pw.Widget _buildReceiptSection({
    required Shipment shipment,
    required pw.Font arabicFont,
    required String title,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Image(_logoImage!, width: 80, height: 40),
                  pw.SizedBox(height: 5),
                  pw.BarcodeWidget(
                    data: shipment.orderId,
                    barcode: pw.Barcode.qrCode(),
                    width: 100,
                    height: 100,
                  ),
                  pw.SizedBox(height: 5),
                  pw.BarcodeWidget(
                    data: shipment.orderId,
                    barcode: pw.Barcode.code128(),
                    width: 100,
                    height: 100,
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'رقم الشحنة: ${shipment.orderId}',
                    style: pw.TextStyle(font: arabicFont, fontSize: 14),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'تاريخ الإنشاء: ${a.DateFormat('dd/MM/yyyy HH:mm').format(shipment.createdAt)}',
                    style: pw.TextStyle(font: arabicFont, fontSize: 12),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'اسم المستلم: ${shipment.recipientName}',
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'رقم الهاتف: ${shipment.phoneNumber}',
                    style: pw.TextStyle(font: arabicFont, fontSize: 16),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'قيمة الطرد: ${shipment.codAmount} دينار',
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'أجرة التوصيل: ${shipment.deliveryCost ?? 0} دينار',
                    style: pw.TextStyle(font: arabicFont, fontSize: 14),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'المجموع: ${(shipment.codAmount + (shipment.deliveryCost ?? 0))} دينار',
                    style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'العنوان: ${shipment.city}, ${shipment.addressDescription}',
                    style: pw.TextStyle(font: arabicFont, fontSize: 12),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          // Content Sections in a Row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Column - Sender and Order Info
              pw.Expanded(
                child: pw.Column(
                  children: [
                    // Order Info
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'معلومات الطلب',
                            style: pw.TextStyle(
                                font: arabicFont,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'رقم الطلب: ${shipment.orderId}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'حالة الطلب: ${shipment.status ?? ""}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'نوع الخدمة: ${shipment.serviceType ?? "عادي"}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'عدد القطع: ${shipment.parcelCount}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    // Sender Info
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'معلومات المرسل',
                            style: pw.TextStyle(
                                font: arabicFont,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'الاسم: ${shipment.username ?? ""}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'رقم الهاتف: ${shipment.userphone ?? ""}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(width: 10),

              // Right Column - Recipient Info
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'معلومات المستلم',
                        style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      if (shipment.notes != null && shipment.notes!.isNotEmpty)
                        pw.Text(
                          'ملاحظات: ${shipment.notes}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          textDirection: pw.TextDirection.rtl,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          // Bottom Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Left side - Barcode
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.BarcodeWidget(
                    data: shipment.orderId,
                    barcode: pw.Barcode.code128(),
                    width: 100,
                    height: 30,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    shipment.orderId,
                    style: pw.TextStyle(font: arabicFont, fontSize: 8),
                  ),
                ],
              ),
              // Right side - Signatures
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'توقيع المستلم: ________________',
                    style: pw.TextStyle(font: arabicFont, fontSize: 10),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'توقيع المندوب: ________________',
                    style: pw.TextStyle(font: arabicFont, fontSize: 10),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 5),

          // Disclaimer
          pw.Text(
            'تعتبر هذه الإرسالية وصل استلام وتسليم للطرد، والشركة لا تتحمل أي مسؤولية عن محتوى الطرد',
            style: pw.TextStyle(font: arabicFont, fontSize: 6),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> print10x9Receipt(List<Shipment> shipments) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();

    // Load logo image
    _logoImage ??= await _getLogoImage();

    // Adjust page format with smaller margins
    final receiptPageFormat = PdfPageFormat(
      10.0 * PdfPageFormat.cm, // 10cm width
      9.0 * PdfPageFormat.cm, // 9cm height
      marginAll: 0.2 * PdfPageFormat.cm, // Reduced margins to 2mm
    );

    for (var shipment in shipments) {
      doc.addPage(
        pw.Page(
          pageFormat: receiptPageFormat,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min, // Add this to minimize spacing
              children: [
                // Header with logo and title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Logo, QR Code and Barcode
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Image(_logoImage!, width: 50, height: 25),
                        pw.SizedBox(height: 3),
                        // QR Code
                        pw.BarcodeWidget(
                          data: shipment.orderId,
                          barcode: pw.Barcode.qrCode(),
                          width: 50,
                          height: 50,
                        ),
                        pw.Text('QR',
                            style: pw.TextStyle(font: arabicFont, fontSize: 6)),
                        pw.SizedBox(height: 1),
                        // Small Barcode
                        pw.BarcodeWidget(
                          data: shipment.orderId,
                          barcode: pw.Barcode.code128(),
                          width: 70,
                          height: 20,
                        ),
                        pw.Text('Barcode',
                            style: pw.TextStyle(font: arabicFont, fontSize: 6)),
                      ],
                    ),
                    // Right side - Title and info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'المشتغل المرخص',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          'رقم الطرد ${shipment.orderId}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          shipment.username ?? '',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          "رقم هاتف الزبون ${shipment.userphone ?? ''}",
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 5), // Reduce spacing

                // Parcel Count
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          shipment.parcelCount.toString(),
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'العدد',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    pw.Text(
                      '${shipment.recipientName}', // Dot separator as shown in image
                      style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),

                // COD Amount
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${shipment.codAmount} JOD',
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          ' التحصيل شامل التوصيل',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    // Right side - Recipient info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          shipment.phoneNumber,
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                        ),
                        pw.Text(
                          'تاريخ الحجز: ${a.DateFormat('HH:mm yyyy/MM/dd').format(shipment.createdAt)}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          '${shipment.city} - ${shipment.addressDescription}',
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 12,
                              color: PdfColors.blue),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 5), // Reduce spacing

                // Main Barcode Section
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'الباركود الرئيسي',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 3),
                      pw.BarcodeWidget(
                        data: shipment.orderId,
                        barcode: pw.Barcode.code128(),
                        width: 240,
                        height: 60,
                        color: PdfColors.white,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        shipment.orderId,
                        style: pw.TextStyle(
                          font: arabicFont,
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // Footer text with smaller font
                pw.Text(
                  'تعتبر هذه الإرسالية وصل استلام وتسليم للطرد، والشركة لا تتحمل أي مسؤولية عن محتوى الطرد',
                  style: pw.TextStyle(
                      font: arabicFont, fontSize: 6), // Smaller font
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 5), // Reduce spacing

                // Bottom barcode section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Bottom Barcode
                        pw.Text(
                          'باركود إضافي',
                          style: pw.TextStyle(font: arabicFont, fontSize: 6),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.BarcodeWidget(
                          data: shipment.orderId,
                          barcode: pw.Barcode.code128(),
                          width: 100,
                          height: 30,
                        ),
                        pw.Text(
                          shipment.orderId,
                          style: pw.TextStyle(font: arabicFont, fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'رقم الطرد',
                          style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      format: PdfPageFormat.a4,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> printEmpty10x9Receipt(
      {required int times, required Customer customer}) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();

    // Load logo image
    _logoImage ??= await _getLogoImage();

    // Adjust page format with smaller margins
    final receiptPageFormat = PdfPageFormat(
      10.0 * PdfPageFormat.cm, // 10cm width
      9.0 * PdfPageFormat.cm, // 9cm height
      marginAll: 0.2 * PdfPageFormat.cm, // Reduced margins to 2mm
    );

    for (int i = 0; i < times; i++) {
      String orderId = Random().nextInt(1000000).toString();
      doc.addPage(
        pw.Page(
          pageFormat: receiptPageFormat,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min, // Add this to minimize spacing
              children: [
                // Header with logo and title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - Logo, QR Code and Barcode
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Image(_logoImage!, width: 50, height: 25),
                        pw.SizedBox(height: 3),
                        // QR Code
                        pw.BarcodeWidget(
                          data: orderId,
                          barcode: pw.Barcode.qrCode(),
                          width: 50,
                          height: 50,
                        ),
                        pw.Text('QR',
                            style: pw.TextStyle(font: arabicFont, fontSize: 6)),
                        pw.SizedBox(height: 1),
                        // Small Barcode
                        pw.BarcodeWidget(
                          data: orderId,
                          barcode: pw.Barcode.code128(),
                          width: 70,
                          height: 20,
                        ),
                        pw.Text('Barcode',
                            style: pw.TextStyle(font: arabicFont, fontSize: 6)),
                      ],
                    ),
                    // Right side - Title and info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // pw.Text(
                        //   'المشتغل المرخص',
                        //   style: pw.TextStyle(font: arabicFont, fontSize: 14),
                        //   textDirection: pw.TextDirection.rtl,
                        // ),
                        pw.Text(
                          'رقم الطرد ${orderId}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          customer.username ?? '',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        // pw.Text(
                        //   "رقم هاتف الزبون ${customer.phoneNumber ?? ''}",
                        //   style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        //   textDirection: pw.TextDirection.rtl,
                        // ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 5), // Reduce spacing

                // Parcel Count
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '....',
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'العدد',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    pw.Text(
                      '................', // Dot separator as shown in image
                      style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),

                // COD Amount
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '..... JOD',
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          ' التحصيل شامل التوصيل',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    // Right side - Recipient info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '................',
                          style: pw.TextStyle(font: arabicFont, fontSize: 14),
                        ),
                        pw.Text(
                          'تاريخ الحجز: ................',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          '................ - ................',
                          style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 12,
                              color: PdfColors.blue),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 5), // Reduce spacing

                // Main Barcode Section
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'الباركود الرئيسي',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 3),
                      pw.BarcodeWidget(
                        data: orderId,
                        barcode: pw.Barcode.code128(),
                        width: 240,
                        height: 60,
                        color: PdfColors.white,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        orderId,
                        style: pw.TextStyle(
                          font: arabicFont,
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // Footer text with smaller font
                pw.Text(
                  'تعتبر هذه الإرسالية وصل استلام وتسليم للطرد، والشركة لا تتحمل أي مسؤولية عن محتوى الطرد',
                  style: pw.TextStyle(
                      font: arabicFont, fontSize: 6), // Smaller font
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 5), // Reduce spacing

                // Bottom barcode section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Bottom Barcode
                        pw.Text(
                          'باركود إضافي',
                          style: pw.TextStyle(font: arabicFont, fontSize: 6),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.BarcodeWidget(
                          data: orderId,
                          barcode: pw.Barcode.code128(),
                          width: 100,
                          height: 30,
                        ),
                        pw.Text(
                          orderId,
                          style: pw.TextStyle(font: arabicFont, fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'رقم الطرد',
                          style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      format: PdfPageFormat.a4,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> print6x4Receipt(List<Shipment> shipments) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();

    // Load logo image
    _logoImage ??= await _getLogoImage();

    // 6x4 inch format in centimeters (15.24 x 10.16 cm)
    final receiptPageFormat = PdfPageFormat(
      15.24 * PdfPageFormat.cm, // 6 inches
      10.16 * PdfPageFormat.cm, // 4 inches
      marginAll: 0.3 * PdfPageFormat.cm, // 3mm margins
    );

    for (var shipment in shipments) {
      doc.addPage(
        pw.Page(
          pageFormat: receiptPageFormat,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Top Row - Basic Info
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(_logoImage!, width: 50, height: 25),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'رقم الشحنة: ${shipment.orderId}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'المرسل: ${shipment.username ?? ""}',
                            style: pw.TextStyle(
                                font: arabicFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            a.DateFormat('dd/MM/yyyy')
                                .format(shipment.createdAt),
                            style: pw.TextStyle(font: arabicFont, fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Main Content Row
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        // Left Side - QR Code
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.BarcodeWidget(
                                  data: shipment.orderId,
                                  barcode: pw.Barcode.qrCode(),
                                  width: 200,
                                  height: 200,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Side - Barcode and Info
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                // Recipient Name
                                pw.Text(
                                  shipment.recipientName,
                                  style: pw.TextStyle(
                                      font: arabicFont,
                                      fontSize: 20,
                                      fontWeight: pw.FontWeight.bold),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 5),
                                // Phone and Address
                                pw.Text(
                                  shipment.phoneNumber,
                                  style: pw.TextStyle(
                                      font: arabicFont, fontSize: 16),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.Text(
                                  '${shipment.city} - ${shipment.addressDescription}',
                                  style: pw.TextStyle(
                                      font: arabicFont, fontSize: 12),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.SizedBox(height: 10),
                                // Large Barcode
                                pw.BarcodeWidget(
                                  data: shipment.orderId,
                                  barcode: pw.Barcode.code128(),
                                  width: 200,
                                  height: 100,
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  shipment.orderId,
                                  style: pw.TextStyle(
                                      font: arabicFont, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> print15x10Receipt(List<Shipment> shipments) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();

    _logoImage ??= await _getLogoImage();

    // 15x10 cm format
    final receiptPageFormat = PdfPageFormat(
      15.0 * PdfPageFormat.cm,
      10.0 * PdfPageFormat.cm,
      marginAll: 0.3 * PdfPageFormat.cm,
    );

    for (var shipment in shipments) {
      doc.addPage(
        pw.Page(
          pageFormat: receiptPageFormat,
          build: (pw.Context context) {
            return pw.Container(
              color: PdfColors.white,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Top Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left Column - Logo, QR Code, Barcode and Phone
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Image(_logoImage!, width: 80, height: 40),
                          pw.SizedBox(height: 3),
                          // QR Code
                          pw.BarcodeWidget(
                            data: shipment.orderId,
                            barcode: pw.Barcode.qrCode(),
                            width: 120,
                            height: 120,
                            color: PdfColors.black,
                          ),
                          pw.Text('QR Code',
                              style: pw.TextStyle(
                                  color: PdfColors.black, fontSize: 10)),
                          pw.SizedBox(height: 2),
                          // Small Barcode
                          pw.BarcodeWidget(
                            data: shipment.orderId,
                            barcode: pw.Barcode.code128(),
                            width: 120,
                            height: 30,
                            color: PdfColors.black,
                          ),
                          pw.Text('Barcode',
                              style: pw.TextStyle(
                                  color: PdfColors.black, fontSize: 10)),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            shipment.userphone ?? '',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      // Right Column - Arabic Text
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            shipment.serviceType,
                            style: pw.TextStyle(
                              font: arabicFont,
                              color: PdfColors.black,
                              fontSize: 18,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            'المشتغل المرخص',
                            style: pw.TextStyle(
                              font: arabicFont,
                              color: PdfColors.black,
                              fontSize: 18,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            shipment.orderId,
                            style: pw.TextStyle(
                              font: arabicFont,
                              color: PdfColors.black,
                              fontSize: 18,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  // Booking Date
                  pw.Text(
                    'تاريخ الحجز: ${a.DateFormat('HH:mm yyyy/MM/dd').format(shipment.createdAt)}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      color: PdfColors.black,
                      fontSize: 16,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.right,
                  ),

                  // Recipient Name
                  pw.Text(
                    shipment.username ?? '',
                    style: pw.TextStyle(
                      font: arabicFont,
                      color: PdfColors.black,
                      fontSize: 26,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                  ),

                  // Address and Phone
                  pw.Text(
                    '${shipment.city}, ${shipment.addressDescription}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      color: PdfColors.black,
                      fontSize: 20,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.Text(
                    shipment.phoneNumber,
                    style: pw.TextStyle(
                      font: arabicFont,
                      color: PdfColors.black,
                      fontSize: 24,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 20),

                  // Amount and Count
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - Amount
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${shipment.codAmount} JOD',
                            style: pw.TextStyle(
                              font: arabicFont,
                              color: PdfColors.black,
                              fontSize: 26,
                            ),
                          ),
                          pw.Text(
                            'التحصيل شامل التوصيل',
                            style: pw.TextStyle(
                              font: arabicFont,
                              color: PdfColors.black,
                              fontSize: 18,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                      // Right side - Count
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            shipment.parcelCount.toString(),
                            style: pw.TextStyle(
                              font: arabicFont,
                              color: PdfColors.black,
                              fontSize: 26,
                            ),
                          ),
                          pw.Text(
                            'العدد',
                            style: pw.TextStyle(
                              font: arabicFont,
                              color: PdfColors.black,
                              fontSize: 18,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // Barcode section
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.BarcodeWidget(
                          data: shipment.orderId,
                          barcode: pw.Barcode.code128(),
                          width: 240,
                          height: 60,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'باركود',
                          style: pw.TextStyle(
                            font: arabicFont,
                            color: PdfColors.black,
                            fontSize: 14,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Disclaimer
                  pw.Text(
                    'تعتبر هذه الإرسالية وصل استلام وتسليم للطرد، والشركة لا تتحمل أي مسؤولية عن محتوى الطرد',
                    style: pw.TextStyle(
                      font: arabicFont,
                      color: PdfColors.black,
                      fontSize: 8,
                    ),
                    textDirection: pw.TextDirection.rtl,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> printExpensesReport(List<Expense> expenses) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();
    _logoImage ??= await _getLogoImage();
    // Calculate total amount
    double totalAmount =
        expenses.fold(0, (sum, expense) => sum + expense.amount);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Image(_logoImage!, width: 100, height: 50),
                      pw.SizedBox(height: 10),
                      // QR Code
                      pw.BarcodeWidget(
                        data:
                            'تقرير المصروفات ${a.DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        barcode: pw.Barcode.qrCode(),
                        width: 120,
                        height: 120,
                      ),
                      pw.SizedBox(height: 10),
                      // Barcodex
                      pw.BarcodeWidget(
                        data:
                            'تقرير المصروفات ${a.DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        barcode: pw.Barcode.code128(),
                        width: 200,
                        height: 40,
                      ),
                    ],
                  ),
                ],
              ),
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'تقرير المصروفات',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 20,
                            color: PdfColors.brown,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'تاريخ الطباعة: ${a.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 14,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'اسم المستخدم: $KcompanyName',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 14,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Table
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2.5), // نوع المصروف
                    1: pw.FlexColumnWidth(2.0), // اسم المستخدم
                    2: pw.FlexColumnWidth(2.0), // المستفيد
                    3: pw.FlexColumnWidth(1.5), // اسم الفرع
                    4: pw.FlexColumnWidth(1.5), // القيمة
                    5: pw.FlexColumnWidth(2.0), // تاريخ الإدخال
                    6: pw.FlexColumnWidth(3.0), // الملاحظات
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.brown,
                      ),
                      children: [
                        'نوع المصروف',
                        'اسم المستخدم',
                        'المستفيد',
                        'اسم الفرع',
                        'القيمة',
                        'تاريخ الإدخال',
                        'الملاحظات',
                      ]
                          .map((text) => pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  text,
                                  style: pw.TextStyle(
                                    font: arabicFont,
                                    color: PdfColors.white,
                                    fontSize: 7,
                                  ),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.center,
                                ),
                              ))
                          .toList(),
                    ),

                    // Data Rows
                    ...expenses.map((expense) => pw.TableRow(
                          children: [
                            _buildPdfCell(expense.type, arabicFont),
                            _buildPdfCell(expense.userName, arabicFont),
                            _buildPdfCell(expense.beneficiary, arabicFont),
                            _buildPdfCell(expense.branch, arabicFont),
                            _buildPdfCell(
                                expense.amount.toString(), arabicFont),
                            _buildPdfCell(
                                a.DateFormat('yyyy/MM/dd')
                                    .format(expense.creationDate),
                                arabicFont),
                            _buildPdfCell(expense.notes, arabicFont),
                          ],
                        )),

                    // Total Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildPdfCell('المجموع', arabicFont),
                        _buildPdfCell('', arabicFont),
                        _buildPdfCell('', arabicFont),
                        _buildPdfCell('', arabicFont),
                        _buildPdfCell('', arabicFont),
                        _buildPdfCell(totalAmount.toString(), arabicFont),
                        _buildPdfCell('', arabicFont),
                        _buildPdfCell('', arabicFont),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> printInventoryAndShipmentsDocument(
      List<InventoryItem> inventoryItems,
      List<Shipment> shipments,
      String customerName,
      {String pageFormatString = "a4"}) async {
    _logoImage ??= await _getLogoImage();
    PdfPageFormat pageFormat;
    if (pageFormatString == "a5") {
      pageFormat = PdfPageFormat.a5;
    } else {
      pageFormat = PdfPageFormat.a4;
    }

    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();

    // First, add inventory pages
    if (inventoryItems.isNotEmpty) {
      int inventoryItemsPerPage = 15;
      int inventoryPages =
          (inventoryItems.length / inventoryItemsPerPage).ceil();

      for (int i = 0; i < inventoryPages; i++) {
        int start = i * inventoryItemsPerPage;
        int end = start + inventoryItemsPerPage;
        if (end > inventoryItems.length) end = inventoryItems.length;

        final pageItems = inventoryItems.sublist(start, end);

        doc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  // Header for inventory pages
                  if (i == 0) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(1),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Image(_logoImage!, width: 50),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'تقرير مخزون العميل: $customerName',
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    font: arabicFont, fontSize: 14),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'التاريخ: ${a.DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.right,
                                style:
                                    pw.TextStyle(font: arabicFont, fontSize: 8),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'عدد المنتجات: ${inventoryItems.length}',
                                textDirection: pw.TextDirection.rtl,
                                style:
                                    pw.TextStyle(font: arabicFont, fontSize: 8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Table header for inventory
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.brown),
                          children: [
                            'م',
                            'اسم المنتج',
                            'الكمية',
                            'السعر',
                            'الوصف',
                          ]
                              .map((text) => _buildHeaderCell(text, arabicFont))
                              .toList(),
                        ),
                        // Inventory items
                        ...List.generate(pageItems.length, (index) {
                          final item = pageItems[index];
                          return pw.TableRow(
                            children: [
                              _buildPdfCell2(
                                  (start + index + 1).toString(), arabicFont),
                              _buildPdfCell2(item.name, arabicFont),
                              _buildPdfCell2(
                                  item.quantity.toString(), arabicFont),
                              _buildPdfCell2(
                                  item.price?.toString() ?? '-', arabicFont),
                              _buildPdfCell2(
                                  item.description ?? '-', arabicFont),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    // Then, add shipments pages
    if (shipments.isNotEmpty) {
      double totalAmount =
          shipments.fold(0, (sum, shipment) => sum + shipment.codAmount);
      int shipmentsPerPage = 15;
      int shipmentPages = (shipments.length / shipmentsPerPage).ceil();

      for (int i = 0; i < shipmentPages; i++) {
        int start = i * shipmentsPerPage;
        int end = start + shipmentsPerPage;
        if (end > shipments.length) end = shipments.length;

        final pageShipments = shipments.sublist(start, end);

        doc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  // Header for shipments pages
                  if (i == 0) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(1),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Image(_logoImage!, width: 50),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'شحنات العميل: $customerName',
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    font: arabicFont, fontSize: 14),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'التاريخ: ${a.DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.right,
                                style:
                                    pw.TextStyle(font: arabicFont, fontSize: 8),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'عدد الشحنات: ${shipments.length}',
                                textDirection: pw.TextDirection.rtl,
                                style:
                                    pw.TextStyle(font: arabicFont, fontSize: 8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Table(
                      border: pw.TableBorder.all(),
                      children: [
                        // Table header for shipments
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.brown),
                          children: [
                            'م',
                            'رقم الطلب',
                            'المستلم',
                            'الهاتف',
                            'العنوان',
                            'الحالة',
                            "المنتجات",
                            "تم خصمها",
                            'COD',
                          ]
                              .map((text) => _buildHeaderCell(text, arabicFont))
                              .toList(),
                        ),
                        // Shipments
                        ...List.generate(pageShipments.length, (index) {
                          final shipment = pageShipments[index];
                          String selectedItemsDescription = "";
                          if (shipment.selectedItems != null) {
                            for (var key in shipment.selectedItems!.keys) {
                              selectedItemsDescription += inventoryItems
                                      .firstWhere(
                                          (element) => element.id == key)
                                      .name +
                                  " - " +
                                  shipment.selectedItems![key].toString() +
                                  "/";
                            }
                          }
                          return pw.TableRow(
                            children: [
                              _buildPdfCell2(
                                  (start + index + 1).toString(), arabicFont),
                              _buildPdfCell2(shipment.orderId, arabicFont),
                              _buildPdfCell2(
                                  shipment.recipientName, arabicFont),
                              _buildPdfCell2(shipment.phoneNumber, arabicFont),
                              _buildPdfCell2(
                                  shipment.addressDescription, arabicFont),
                              _buildPdfCell2(shipment.status, arabicFont),
                              _buildPdfCell2(
                                  selectedItemsDescription, arabicFont),
                              _buildPdfCell2(
                                  shipment.cashPossession ==
                                          CashPossession.customer
                                      ? "نعم"
                                      : "لا",
                                  arabicFont),
                              _buildPdfCell2(
                                  shipment.codAmount.toString(), arabicFont),
                            ],
                          );
                        }),
                        // Total row
                        pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _buildPdfCell2('', arabicFont),
                            _buildPdfCell2('', arabicFont),
                            _buildPdfCell2('', arabicFont),
                            _buildPdfCell2('', arabicFont),
                            _buildPdfCell2('', arabicFont),
                            _buildPdfCell2('المجموع', arabicFont),
                            _buildPdfCell2(totalAmount.toString(), arabicFont),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    await Printing.layoutPdf(
      format: pageFormat,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> printTransfersReport(List<Transfer> transfers,
      {DateTime? fromDate,
      DateTime? toDate,
      String pageFormatString = "a4"}) async {
    _logoImage ??= await _getLogoImage();
    PdfPageFormat pageFormat;
    if (pageFormatString == "a5") {
      pageFormat = PdfPageFormat.a5;
    } else {
      pageFormat = PdfPageFormat.a4;
    }

    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final doc = pw.Document();
    // Calculate totals
    double totalDeposits = transfers
        .where((t) => t.type == 'deposit')
        .fold(0, (sum, t) => sum + t.amount);
    double totalWithdrawals = transfers
        .where((t) => t.type == 'withdrawal')
        .fold(0, (sum, t) => sum + t.amount);
    double netAmount = totalDeposits - totalWithdrawals;

    // Split transfers into pages (20 transfers per page)
    int transfersPerPage = 20;
    int pages = (transfers.length / transfersPerPage).ceil();

    for (int i = 0; i < pages; i++) {
      int start = i * transfersPerPage;
      int end = start + transfersPerPage;
      if (end > transfers.length) end = transfers.length;

      final pageTransfers = transfers.sublist(start, end);

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(1),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Image(_logoImage!, width: 50),
                          pw.SizedBox(height: 10),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'تقرير الحوالات',
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: arabicFont, fontSize: 14),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'التاريخ: ${a.DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: arabicFont, fontSize: 8),
                          ),
                          if (fromDate != null && toDate != null) ...[
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'من: ${a.DateFormat('dd/MM/yyyy').format(fromDate)} إلى: ${a.DateFormat('dd/MM/yyyy').format(toDate)}',
                              textDirection: pw.TextDirection.rtl,
                              textAlign: pw.TextAlign.right,
                              style:
                                  pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ],
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'عدد الحوالات: ${transfers.length}',
                            textDirection: pw.TextDirection.rtl,
                            style: pw.TextStyle(font: arabicFont, fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(0.6), // مسلسل
                      1: pw.FlexColumnWidth(1.5), // نوع الحوالة
                      2: pw.FlexColumnWidth(2.0), // الحساب
                      3: pw.FlexColumnWidth(1.5), // المبلغ
                      4: pw.FlexColumnWidth(1.5), // التاريخ
                      5: pw.FlexColumnWidth(2.0), // الملاحظات
                    },
                    children: [
                      // Table header
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.brown),
                        children: [
                          'م',
                          'نوع الحوالة',
                          'الحساب',
                          'المبلغ',
                          'التاريخ',
                          'الملاحظات',
                        ]
                            .map((text) => _buildHeaderCell(text, arabicFont))
                            .toList(),
                      ),
                      // Transfers
                      ...List.generate(pageTransfers.length, (index) {
                        final transfer = pageTransfers[index];
                        return pw.TableRow(
                          children: [
                            _buildPdfCell2(
                                (start + index + 1).toString(), arabicFont),
                            _buildPdfCell2(
                                transfer.type == 'deposit' ? 'إيداع' : 'سحب',
                                arabicFont),
                            _buildPdfCell2(transfer.account, arabicFont),
                            _buildPdfCell2(
                                transfer.amount.toString(), arabicFont),
                            _buildPdfCell2(
                                a.DateFormat('dd/MM/yyyy')
                                    .format(transfer.date),
                                arabicFont),
                            _buildPdfCell2(transfer.notes ?? '', arabicFont),
                          ],
                        );
                      }),
                      // Summary rows
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2('إجمالي الإيداعات', arabicFont),
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2(totalDeposits.toString(), arabicFont),
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2('', arabicFont),
                        ],
                      ),
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2('إجمالي السحوبات', arabicFont),
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2(
                              totalWithdrawals.toString(), arabicFont),
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2('', arabicFont),
                        ],
                      ),
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2('صافي المبلغ', arabicFont),
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2(netAmount.toString(), arabicFont),
                          _buildPdfCell2('', arabicFont),
                          _buildPdfCell2('', arabicFont),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      format: pageFormat,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
