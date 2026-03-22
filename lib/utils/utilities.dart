import 'package:good_line_delivery/models/Shipment.dart';

import '../shared/constants.dart';
import '../main.dart';
import 'package:flutter/material.dart';

class Utilities {
  static bool checkPermission(String permission) {
    if (userPermissions == null) {
      return false;
    }

    if (!(userPermissions!.contains(permission))) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text("ليس لديك صلاحيات لتغيير حالة الطلب"),
        ),
      );
      return false;
    }
    return true;
  }

  static bool hasPermission(String permission) {
    if (userPermissions == null) {
      return false;
    }
    return userPermissions!.contains(permission);
  }

  ({double totalCollections, double totalPrice}) getTotals(
      List<Shipment> shipments) {

    double totalCollections = 0;
    double totalPrice = 0;

    for (var shipment in shipments) {
    
      switch (shipment.status) {
        case 'تم توصيلها':
          totalCollections += shipment.codAmount ?? 0;
          totalPrice += shipment.deliveryCost ?? 0;
          break;

        case 'تم تحصيلها بشكل جزئي':
          totalCollections += shipment.codAmount ?? 0;
          totalPrice += shipment.deliveryCost ?? 0;
          break;
        case 'تم إرجاعها':
   
          if (shipment.receivedMoneyFromCustomer == true) {
            totalPrice += shipment.deliveryCost ?? 0;
            totalCollections += shipment.deliveryCost ?? 0;
          } else {
            if (shipment.getMoneyFromUserPalance == true) {
              totalPrice += shipment.deliveryCost ?? 0;
            } else {
              totalPrice += 0;
            }
          }

          break;
      }
    }
 




    return (totalCollections: totalCollections, totalPrice: totalPrice);
  }

  static String normalizeArabic(String text) {
    if (text.isEmpty) return text;
    // Replace multiple spaces/tabs/newlines with a single space and trim
    String normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Normalize Alef
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');

    // Normalize Taa Marbuta
    normalized = normalized.replaceAll('ة', 'ه');

    // Normalize Ya/Alef Maqsura
    normalized = normalized.replaceAll('ى', 'ي');

    // Normalize Hamza
    normalized = normalized.replaceAll('ؤ', 'و');
    normalized = normalized.replaceAll('ئ', 'ي');

    // Remove Harakat (Diacritics)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u0652]'), '');

    return normalized.toLowerCase();
  }
}
