import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _activityKey = 'activity';
  static const String _taxNumberKey = 'taxNumber';
  static const String _credentialsHistoryKey = 'credentialsHistory';

  // Constants moved from api_constants.dart
  static const String TOKEN_KEY = 'einv-token';
  static const String OTP_KEY = 'einv-otp';
  static const String REFRESH_TOKEN = 'refresh-token';
  static const String SESSION_TIMEOUT = 'tokenExpiry';
  static const String ACTIVITY_KEY = 'activity';
  static const String NAME_KEY = 'name';
  static const String PHONE_NUMBER_KEY = 'phoneNumber';
  static const String INVOICE_TYPES_KEY = 'invoiceTypes';

  // Preferred dropdown values
  static const String PREFERRED_CURRENCY_KEY = 'preferred_currency';
  static const String PREFERRED_PROVINCE_KEY = 'preferred_province';
  static const String PREFERRED_INVOICE_KIND_KEY = 'preferred_invoice_kind';
  static const String PREFERRED_PAYMENT_TYPE_KEY = 'preferred_payment_type';
  static const String PREFERRED_BUYER_ID_TYPE_KEY = 'preferred_buyer_id_type';
  static const String PREFERRED_TAX_RATE_KEY = 'preferred_tax_rate';
  static const String PREFERRED_ISIC4_KEY = 'preferred_isic4';
  static const String LANGUAGE_KEY = 'language';

  // Safely get shared preferences instance with error handling
  static Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } on PlatformException catch (e) {
      print('Failed to get shared preferences: ${e.message}');
      return null;
    } catch (e) {
      print('Error accessing shared preferences: $e');
      return null;
    }
  }

  static Future<String?> getLanguage() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      return prefs?.getString(LANGUAGE_KEY);
    } catch (e) {
      print('Error getting language: $e');
      return null;
    }
  }

  static Future<bool> setLanguage(String language) async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      if (prefs == null) return false;
      await prefs.setString(LANGUAGE_KEY, language);
      return true;
    } catch (e) {
      print('Error setting language: $e');
      return false;
    }
  }

  // Save user credentials
  static Future<bool> saveUserCredentials({
    required String username,
    required String password,
    required String activity,
    required String taxNumber,
  }) async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      if (prefs == null) return false;

      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
      await prefs.setString(_activityKey, activity);
      await prefs.setString(_taxNumberKey, taxNumber);
      return true;
    } on PlatformException catch (e) {
      print('Platform error saving credentials: ${e.message}');
      return false;
    } catch (e) {
      print('Error saving credentials: $e');
      return false;
    }
  }

  // Get username
  static Future<String?> getUsername() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      return prefs?.getString(_usernameKey);
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  // Get password
  static Future<String?> getPassword() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      return prefs?.getString(_passwordKey);
    } catch (e) {
      print('Error getting password: $e');
      return null;
    }
  }

  // Get tax number
  static Future<String?> getTaxNumber() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      return prefs?.getString(_taxNumberKey);
    } catch (e) {
      print('Error getting tax number: $e');
      return null;
    }
  }
// Get activity
  static Future<String?> getActivity() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      return prefs?.getString(_activityKey);
    } catch (e) {
      print('Error getting activity: $e');
      return null;
    }
  }
  // Check if user credentials exist
  static Future<bool> hasCredentials() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      if (prefs == null) return false;

      return prefs.containsKey(_usernameKey) &&
          prefs.containsKey(_passwordKey) &&
          prefs.containsKey(_taxNumberKey);
    } catch (e) {
      print('Error checking credentials: $e');
      return false;
    }
  }

  // Clear user credentials
  static Future<bool> clearCredentials() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      if (prefs == null) return false;

      await prefs.remove(_usernameKey);
      await prefs.remove(_passwordKey);
      await prefs.remove(_taxNumberKey);
      return true;
    } catch (e) {
      print('Error clearing credentials: $e');
      return false;
    }
  }

  // Get token methods moved from ApiService
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(TOKEN_KEY);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Check token expiry
  static Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int expiryTime = prefs.getInt(SESSION_TIMEOUT) ?? 0;
      return expiryTime < DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      print('Error checking token expiry: $e');
      return true;
    }
  }

  // Save token
  static Future<bool> saveToken(String token, int expiryTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TOKEN_KEY, token);
      await prefs.setInt(SESSION_TIMEOUT, expiryTime);
      return true;
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  // clear token
  static Future<bool> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(TOKEN_KEY);
      return true;
    } catch (e) {
      print('Error clearing token: $e');
      return false;
    }
  }

  // Get OTP
  static Future<String?> getOtp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(OTP_KEY);
    } catch (e) {
      print('Error getting OTP: $e');
      return null;
    }
  }

  // Save OTP
  static Future<bool> saveOtp(String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(OTP_KEY, otp);
      return true;
    } catch (e) {
      print('Error saving OTP: $e');
      return false;
    }
  }

  // Save user activity
  static Future<bool> saveActivity(String activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ACTIVITY_KEY, activity);
      return true;
    } catch (e) {
      print('Error saving activity: $e');
      return false;
    }
  }

  // Get user activity
  // static Future<String?> getActivity() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getString(ACTIVITY_KEY);
  //   } catch (e) {
  //     print('Error getting activity: $e');
  //     return null;
  //   }
  // }

  // Save user name
  static Future<bool> saveName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(NAME_KEY, name);
      return true;
    } catch (e) {
      print('Error saving name: $e');
      return false;
    }
  }

  // Get user name
  static Future<String?> getName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(NAME_KEY);
    } catch (e) {
      print('Error getting name: $e');
      return null;
    }
  }

  // Save phone number
  static Future<bool> savePhoneNumber(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PHONE_NUMBER_KEY, phoneNumber);
      return true;
    } catch (e) {
      print('Error saving phone number: $e');
      return false;
    }
  }

  // Get phone number
  static Future<String?> getPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PHONE_NUMBER_KEY);
    } catch (e) {
      print('Error getting phone number: $e');
      return null;
    }
  }

  // Save preferred currency
  static Future<bool> savePreferredCurrency(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFERRED_CURRENCY_KEY, currency);
      return true;
    } catch (e) {
      print('Error saving preferred currency: $e');
      return false;
    }
  }

  // Get preferred currency
  static Future<String?> getPreferredCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREFERRED_CURRENCY_KEY) ?? 'JOD';
    } catch (e) {
      print('Error getting preferred currency: $e');
      return 'JOD';
    }
  }

  // Save preferred province
  static Future<bool> savePreferredProvince(String province) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFERRED_PROVINCE_KEY, province);
      return true;
    } catch (e) {
      print('Error saving preferred province: $e');
      return false;
    }
  }

  // Get preferred province
  static Future<String?> getPreferredProvince() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREFERRED_PROVINCE_KEY) ?? 'JO-AM';
    } catch (e) {
      print('Error getting preferred province: $e');
      return 'JO-AM';
    }
  }

  // Save preferred invoice kind
  static Future<bool> savePreferredInvoiceKind(String invoiceKind) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFERRED_INVOICE_KIND_KEY, invoiceKind);
      return true;
    } catch (e) {
      print('Error saving preferred invoice kind: $e');
      return false;
    }
  }

  // Get preferred invoice kind
  static Future<String?> getPreferredInvoiceKind() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREFERRED_INVOICE_KIND_KEY) ?? 'LOCAL';
    } catch (e) {
      print('Error getting preferred invoice kind: $e');
      return 'LOCAL';
    }
  }

  // Save preferred payment type
  static Future<bool> savePreferredPaymentType(String paymentType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFERRED_PAYMENT_TYPE_KEY, paymentType);
      return true;
    } catch (e) {
      print('Error saving preferred payment type: $e');
      return false;
    }
  }

  // Get preferred payment type
  static Future<String?> getPreferredPaymentType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREFERRED_PAYMENT_TYPE_KEY) ?? 'cash';
    } catch (e) {
      print('Error getting preferred payment type: $e');
      return 'cash';
    }
  }

  // Save preferred buyer ID type
  static Future<bool> savePreferredBuyerIdType(String buyerIdType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFERRED_BUYER_ID_TYPE_KEY, buyerIdType);
      return true;
    } catch (e) {
      print('Error saving preferred buyer ID type: $e');
      return false;
    }
  }

  // Get preferred buyer ID type
  static Future<String?> getPreferredBuyerIdType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREFERRED_BUYER_ID_TYPE_KEY) ??
          'NATIONAL_ID_NUMBER';
    } catch (e) {
      print('Error getting preferred buyer ID type: $e');
      return 'NATIONAL_ID_NUMBER';
    }
  }

  // Save preferred tax rate
  static Future<bool> savePreferredTaxRate(String taxRate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFERRED_TAX_RATE_KEY, taxRate);
      return true;
    } catch (e) {
      print('Error saving preferred tax rate: $e');
      return false;
    }
  }

  // Get preferred tax rate
  static Future<String?> getPreferredTaxRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREFERRED_TAX_RATE_KEY) ?? 'SIXTEEN';
    } catch (e) {
      print('Error getting preferred tax rate: $e');
      return 'SIXTEEN';
    }
  }

  // Save preferred ISIC4 code
  static Future<bool> savePreferredIsic4(String isic4) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREFERRED_ISIC4_KEY, isic4);
      return true;
    } catch (e) {
      print('Error saving preferred ISIC4 code: $e');
      return false;
    }
  }

  // Get preferred ISIC4 code
  static Future<String?> getPreferredIsic4() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PREFERRED_ISIC4_KEY) ?? '0111';
    } catch (e) {
      print('Error getting preferred ISIC4 code: $e');
      return '0111';
    }
  }

  static Future<bool> saveInvoiceTypes(String invoiceTypes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(INVOICE_TYPES_KEY, invoiceTypes);
      return true;
    } catch (e) {
      print('Error saving invoice types: $e');
      return false;
    }
  }

  static Future<String?> getInvoiceTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(INVOICE_TYPES_KEY);
    } catch (e) {
      print('Error getting invoice types: $e');
      return null;
    }
  }

  // Save credentials history - a list of tax numbers and passwords
  static Future<bool> saveCredentialsHistory(
      List<Map<String, String>> credentialsList) async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      if (prefs == null) return false;

      List<String> encodedList = credentialsList
          .map((credentials) =>
              '${credentials['taxNumber']}:${credentials['password']}')
          .toList();

      return await prefs.setStringList(_credentialsHistoryKey, encodedList);
    } catch (e) {
      print('Error saving credentials history: $e');
      return false;
    }
  }

  // Get credentials history
  static Future<List<Map<String, String>>> getCredentialsHistory() async {
    try {
      final SharedPreferences? prefs = await _getPrefs();
      if (prefs == null) return [];

      List<String>? encodedList = prefs.getStringList(_credentialsHistoryKey);
      if (encodedList == null) return [];

      return encodedList
          .map((encoded) {
            List<String> parts = encoded.split(':');
            if (parts.length == 2) {
              return {
                'taxNumber': parts[0],
                'password': parts[1],
              };
            }
            return <String, String>{}; // Return empty map for invalid entries
          })
          .where((map) => map.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error getting credentials history: $e');
      return [];
    }
  }

  // Add credentials to history
  static Future<bool> addToCredentialsHistory(
      String taxNumber, String password) async {
    try {
      // Get current history
      List<Map<String, String>> history = await getCredentialsHistory();

      // Check if entry already exists
      int existingIndex =
          history.indexWhere((item) => item['taxNumber'] == taxNumber);

      // If exists, remove it (we'll add it to the front)
      if (existingIndex != -1) {
        history.removeAt(existingIndex);
      }

      // Add new entry to the front
      history.insert(0, {'taxNumber': taxNumber, 'password': password});

      // Limit history to 10 entries
      if (history.length > 10) {
        history = history.sublist(0, 10);
      }

      // Save updated history
      return await saveCredentialsHistory(history);
    } catch (e) {
      print('Error adding to credentials history: $e');
      return false;
    }
  }
}
