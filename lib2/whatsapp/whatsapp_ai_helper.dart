import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

import '../shared/appProvider.dart';

class WhatsappAIHelper {
  static Future<Map<String, String>> parseMessage(
      String message, AppProvider appProvider) async {
    try {
      final model = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-1.5-flash',
      );

      final citiesList = appProvider.citiesAndPlacesNames.join(', ');

      final prompt = '''
      Extract delivery information from this WhatsApp message for "Sadrad" delivery system.
      Return JSON with these keys: 
      "recipientName", "phone", "city", "address", "codAmount", "deliveryCost", "content", "weight", "notes"
      
      Phone normalization: ensure it starts with 07 and is 10 digits long if possible.
      City matching: try to match from this list if possible: $citiesList.
      
      Message:
      $message
      
      Output ONLY JSON.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final text = response.text;
      if (text != null) {
        final cleaned =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> decoded = json.decode(cleaned);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (e) {
      print('AI Parse Error: $e');
    }
    return {};
  }
}
