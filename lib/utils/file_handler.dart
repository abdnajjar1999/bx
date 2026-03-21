import 'dart:io';
import '../models/DocmentFile.dart';
import '../models/Shipment.dart';
import '../shared/firebaseHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class FileHandler {
  static Future<String> downloadFile(Uint8List bytes, String fileName,
      {String? phoneNumber, Shipment? shipment}) async {
    try {
      final FirebaseHelper firebaseHelper = FirebaseHelper();
      final storageRef = FirebaseStorage.instance.ref();

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        final cityImageRef = storageRef
            .child('files/${DateTime.now().millisecondsSinceEpoch}_$fileName');

        // Create metadata
        final metadata = SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {'picked-file-path': fileName});

        // Upload the image bytes directly
        await cityImageRef.putData(bytes, metadata);

        // Get and return the download URL
        var firebaseUrl = await cityImageRef.getDownloadURL();
        html.Url.revokeObjectUrl(url);
        print(phoneNumber);

        if (fileName.contains(".pdf")) {
          html.window.open(firebaseUrl, '_blank');
        }
        // الملفات اسم الملف
        var file = DocumentFile(
          name: "$fileName for ${shipment?.username}",
          url: firebaseUrl,
          type: fileName.split(".").last,
          createdAt: DateTime.now().toString(),
          createdBy: FirebaseAuth.instance.currentUser!.displayName ?? "system",
        );
        if (phoneNumber != null) {
          //send link to whatsapp
          final url = Uri.encodeComponent(firebaseUrl);
          String whatsappUrl =
              "https://wa.me/$phoneNumber?text=مرحباً، تم إرسال المستند الخاص بك. يمكنك تحميله من خلال الرابط التالي:%0a$url%0aشكراً لك";
          await launchUrl(Uri.parse(whatsappUrl));
        }
        await firebaseHelper.addFile(file.toJson());

        return firebaseUrl;
      } else {
        if (phoneNumber == null) {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}\\$fileName');
          await file.writeAsBytes(bytes);
          // Open the file using the default system application

          await Process.run('explorer', [file.path]);
        }
        // Upload the image bytes directly
        final cityImageRef = storageRef
            .child('files/${DateTime.now().millisecondsSinceEpoch}_$fileName');

        // Create metadata
        final metadata = SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {'picked-file-path': fileName});
        await cityImageRef.putData(bytes, metadata);

        // Get and return the download URL
        var firebaseUrl = await cityImageRef.getDownloadURL();

        print(phoneNumber);

        var documentFile = DocumentFile(
          name: "$fileName for ${shipment?.username}",
          url: firebaseUrl,
          type: fileName.split(".").last,
          createdAt: DateTime.now().toString(),
          createdBy: FirebaseAuth.instance.currentUser!.displayName ?? "system",
        );
        if (phoneNumber != null) {
          //send link to whatsapp
          final url = Uri.encodeComponent(firebaseUrl);
          String whatsappUrl =
              "https://wa.me/$phoneNumber?text=مرحباً، تم إرسال المستند الخاص بك. يمكنك تحميله من خلال الرابط التالي:%0a$url%0aشكراً لك";
          await launchUrl(Uri.parse(whatsappUrl));
        }
        await firebaseHelper.addFile(documentFile.toJson());
        return firebaseUrl;
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  static Future<void> openFile(DocumentFile file) async {
    if (kIsWeb) {
      if (file.type.contains("pdf")) {
        html.window.open(file.url, '_blank');
      } else {
        final islandRef = FirebaseStorage.instance
            .ref("files/${file.url.split("files/")[1].split("?")[0]}");
        print(file.url.split("/o/")[1].split("?")[0]);
        const oneMb = 1024 * 1024;

        try {
          final Uint8List? bytes = await islandRef.getData(oneMb * 10);
          print(bytes);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", file.name)
            ..click();
        } catch (e) {
          print(e);
        }
      }
    } else {
      Process.run('explorer', [file.url]);
    }
  }

  openFileFromUrl(String url) {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      Process.run('explorer', [url]);
    }
  }
}
