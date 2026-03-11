import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'user_preferences.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_constants.dart';
import 'billing_models.dart';

/// Service for handling API requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  late http.Client _client;
  String? _languageCode;
  Logger logger = Logger();

  // Private constructor
  ApiService._internal() {
    _client = http.Client();
    _setupInterceptors();
  }

  // Factory constructor to return the same instance
  factory ApiService() {
    return _instance;
  }

  // Set language for the API requests
  void setLanguage(String languageCode) {
    _languageCode = languageCode;
  }

  // Setup HTTP interceptors
  void _setupInterceptors() {
    // Interceptors can't be implemented directly with http package
    // Flutter doesn't have built-in interceptors like axios
  }

  // Get authentication token
  Future<String?> getToken() async {
    final isExpired = await UserPreferences.isTokenExpired();
    if (isExpired) {
      final username = await UserPreferences.getUsername();
      final password = await UserPreferences.getPassword();
      final taxNumber = await UserPreferences.getTaxNumber();
      final response = await loginUser({
        "taxNumber": taxNumber,
        "username": username,
        "password": password,
      });
      return response['token'];
    }
    return UserPreferences.getToken();
  }

  // Get auth headers
  Future<Map<String, String>> _getAuthHeaders({String? activity}) async {
    final token = await getToken();
    final effectiveActivity = activity ?? await UserPreferences.getActivity();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (_languageCode != null) 'Accept-Language': _languageCode!,
      if (effectiveActivity != null && effectiveActivity.isNotEmpty)
        'Activity': effectiveActivity,
    };
    return headers;
  }

  // Get OTP header
  Future<Map<String, String>> _getOtpHeaders() async {
    final otp = await UserPreferences.getOtp();
    final headers = {
      'Content-Type': 'application/json',
      if (otp != null) 'OTP': otp,
      if (_languageCode != null) 'Accept-Language': _languageCode!,
    };
    return headers;
  }

  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      throw HttpException(
        'API Error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // API ENDPOINTS

  // Get tax number
  Future<dynamic> getTaxNumber() async {
    return get('/on-boarding/get-tax-number');
  }

  // Get next invoice number
  Future<dynamic> getNextInvoiceNumber() async {
    return get('/sme/invoices/next-tax-number');
  }

  // Get user info
  Future<dynamic> getUserInfo() async {
    final response = await get('/users/');
    await UserPreferences.saveActivity(
      response["activitiesList"][0]['activity'],
    );
    await UserPreferences.saveName(response['name']);
    await UserPreferences.savePhoneNumber(response['phoneNumber']);

    return response;
  }

  // Register user
  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> data) async {
    final response = await post('/on-boarding/register-taxpayer', data);
    return {'token': response['access_token'], 'role': response['role']};
  }

  // Login user
  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> data) async {
    dynamic response;
    // if (kIsWeb) {
    response = await _callProxy(
      method: 'POST',
      url: '$API_URL/users/auth/login',
      body: data,
      headers: {'Content-Type': 'application/json'},
    );
    // } else {
    //   final res = await _client.post(
    //     Uri.parse('$API_URL/users/auth/login'),
    //     headers: {'Content-Type': 'application/json'},
    //     body: json.encode(data),
    //   );
    //   response = _handleResponse(res);
    // }
    logger.d(response.toString());

    final int expiresIn = int.tryParse(response['expires_in'].toString()) ?? 0;
    final expiryTime = DateTime.now().millisecondsSinceEpoch + expiresIn;
    await UserPreferences.saveToken(response['access_token'], expiryTime);
    logger.d(response.toString());
    logger.d(expiryTime.toString());
    print(DateTime.now().millisecondsSinceEpoch.toString());

    return {
      'token': response['access_token'],
      'refreshToken': response['refresh_token'],
      'role': response['role'],
    };
  }

  // Get all devices
  Future<List<DeviceInfo>> getAllDevices() async {
    final devices = await get('/users/devices/');
    final devicesList = <DeviceInfo>[];

    for (var device in devices as List) {
      devicesList.add(
        DeviceInfo(
          id: device['id'] ?? '',
          clientId: device['clientId'] ?? '',
          secretKey: device['secretKey'] ?? '',
          name: device['deviceName'] ?? '',
          enabled: device['enabled'] ?? false,
          activityNumber: device['activityDTO']?['activity'] ?? '',
        ),
      );
    }

    return devicesList;
  }

  // Add device
  Future<dynamic> addDevice(Map<String, dynamic> data) async {
    return post('/users/devices/', data);
  }

  // Get user invoice
  Future<dynamic> getUserInvoice(String invoiceNumber, String activity) async {
    return get('/sme/invoices/get-uuid/$invoiceNumber', activity: activity);
  }

  // Check if user has invoices
  Future<dynamic> checkIfUserHasInvoices(String activity) async {
    return get('/sme/invoices/check-invoices', activity: activity);
  }

  // Disable device
  Future<dynamic> disableDeviceById(String deviceId) async {
    return put('/users/devices/$deviceId/status', {'enabled': false});
  }

  // Enable device
  Future<dynamic> enableDeviceById(String deviceId) async {
    return put('/users/devices/$deviceId/status', {'enabled': true});
  }

  // Get all sub-admins
  Future<List<SubAdminInfo>> getAllSubAdmins() async {
    final subAdmins = await getWithOtp('/users/sub-admins/');
    final subAdminsList = <SubAdminInfo>[];

    for (var subAdmin in subAdmins as List) {
      ActivityInfo? activityInfo;
      if (subAdmin['activityDTO'] != null) {
        activityInfo = ActivityInfo(
          activity: subAdmin['activityDTO']['activity'] ?? '',
          invoiceType: subAdmin['activityDTO']['invoiceType']?.toString(),
        );
      }

      subAdminsList.add(
        SubAdminInfo(
          id: subAdmin['id'] ?? '',
          username: subAdmin['username'] ?? '',
          notes: subAdmin['notes'] ?? '',
          enabled: subAdmin['enabled'] ?? true,
          activityNumber: activityInfo,
        ),
      );
    }

    return subAdminsList;
  }

  // Add sub-admin
  Future<dynamic> addSubAdmin(Map<String, dynamic> data) async {
    return postWithOtp('/users/sub-admins/', data);
  }

  // Update sub-admin
  Future<dynamic> updateSubAdmin(
    String adminId,
    Map<String, dynamic> data,
  ) async {
    return putWithOtp('/users/sub-admins/$adminId', data);
  }

  // Disable sub-admin
  Future<dynamic> disableSubAdminById(String adminId) async {
    return putWithOtp('/users/sub-admins/$adminId/status', {'enabled': false});
  }

  // Enable sub-admin
  Future<dynamic> enableSubAdminById(String adminId) async {
    return putWithOtp('/users/sub-admins/$adminId/status', {'enabled': true});
  }

  // Generate OTP
  Future<dynamic> generateOTP() async {
    return post('/users/otp/generate', {});
  }

  // Verify OTP
  Future<dynamic> verifyOTP(Map<String, dynamic> data) async {
    final response = await post('/users/otp/verify', data);
    await UserPreferences.saveOtp(data['otp']);
    return response;
  }

  // Get all activities
  Future<dynamic> getAllActivities() async {
    return get('/users/user/activities/');
  }

  // Get invoice type
  Future<dynamic> getInvoiceType({String? activity}) async {
    final data =
        await get('/sme/invoices/check-invoices-type', activity: activity);

    await UserPreferences.saveInvoiceTypes(data['invoiceType']);
    return data;
  }

  // Get all invoices
  Future<Map<String, dynamic>> getAllInvoices({
    Map<String, String>? params,
  }) async {
    final data = await get('/sme/invoices/', queryParams: params);
    logger.d(data);

    return data;
  }

  // Submit invoice
  Future<Map<String, dynamic>> submitInvoice(Map<String, dynamic> data) async {
    final response = await post(
      '/sme/invoices/',
      data,
      headers: {'upload-from': 'WEB'},
    );
    logger.d(response);

    return {
      'invoiceId': response['invoiceUniqueIdentifier'],
      'invoiceNumber': response['invoiceNumber'],
    };
  }

  // Cancel invoice
  Future<dynamic> cancelInvoice(String invoiceId, String invoiceNumber) async {
    return delete('/sme/invoices/$invoiceId/$invoiceNumber');
  }

  // Get original invoice by ID
  Future<dynamic> getOriginalInvoiceById(
    String invoiceId,
    String invoiceNumber,
    String activity,
  ) async {
    final invoice = await get(
      '/sme/invoices/original-invoices/$invoiceId/$invoiceNumber',
      activity: activity,
    );

    final String language = _languageCode ?? 'en';

    // Parse date manually instead of using DateFormat
    String formatDate(String dateStr) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[0]}/${parts[1]}/${parts[2]}';
      }
      return dateStr;
    }

    String countryName = '';
    if (language == 'en') {
      countryName = invoice['sellerDTO']?['countryDTO']?['countryNameEn'] ?? '';
    } else {
      countryName = invoice['sellerDTO']?['countryDTO']?['countryNameAr'] ?? '';
    }

    return {
      'id': invoice['invoiceUniqueIdentifier'],
      'invoiceType': invoice['invoiceTypeCode'],
      'invoiceStatus': invoice['invoiceStatus'],
      'invoiceNumber': invoice['invoiceNumber'],
      'invoiceKind': invoice['invoiceKind'] ?? 'LOCAL',
      'currencyType': invoice['currencyEnum'] ?? 'JOD',
      'buyerInvoiceNumber': invoice['buyerInvoiceNumber'],
      'originalInvoiceNumber': invoice['originalInvoiceNumber'],
      'originalInvoiceUUID': invoice['originalInvoiceUUID'],
      'noteType': invoice['noteType'],
      'reasonOfNote': invoice['reasonOfNote'],
      'activityDTO': invoice['activityDTO'],
      'issueDate': formatDate(invoice['issueDate']),
      'qrCodeImage': invoice['qrCodeImage'],
      'seller': {
        'name': invoice['sellerDTO']?['name'],
        'isCustomerPriceEnabled': invoice['sellerDTO']
            ?['isCustomerPriceEnabled'],
        'phoneNumber': invoice['sellerDTO']?['mobileNumber'],
        'postalCode': invoice['sellerDTO']?['postalCode'],
        'taxNumber': invoice['sellerDTO']?['taxNumber'],
        'activityNumber': invoice['activityDTO']?['activity'],
        'country': countryName,
      },
      'buyer': _parseBuyerInfo(invoice['buyerDTO'], language),
      'items': _parseInvoiceItems(invoice['invoiceItemDTOList']),
      'totalAmountExcludingTaxes': invoice['totalAmountExcludingTaxes'],
      'totalDiscountsAmount': invoice['totalDiscountsAmount'],
      'totalGeneralTaxesAmount': invoice['totalGeneralTaxesAmount'],
      'totalPayableAmount': invoice['totalPayableAmount'],
      'notes': invoice['notes'],
    };
  }

  // Get invoice by ID
  Future<dynamic> getInvoiceById(String invoiceId, String invoiceNumber) async {
    final invoice = await get('/sme/invoices/$invoiceId/$invoiceNumber');
    return invoice;
  }

  // Helper to parse buyer info
  Map<String, dynamic> _parseBuyerInfo(
    Map<String, dynamic>? buyerDTO,
    String language,
  ) {
    if (buyerDTO == null) return {};
    String provinceName = '';
    if (language == 'en') {
      provinceName = buyerDTO['provinceDTO']?['provinceNameEn'] ?? '';
    } else {
      provinceName = buyerDTO['provinceDTO']?['provinceNameAr'] ?? '';
    }

    return {
      'name': buyerDTO['buyerName'],
      'phoneNumber': buyerDTO['phoneNumber'],
      'postalCode': buyerDTO['postalCode'],
      'buyerId': buyerDTO['additionalBuyerId'],
      'buyerIdTypeCode': buyerDTO['additionalBuyerIdType'],
      'buyerIdType': _getBuyerIdTypeTextByCode(
        buyerDTO['additionalBuyerIdType'],
      ),
      'provinceCode': buyerDTO['provinceDTO']?['provinceCode'],
      'province': provinceName,
    };
  }

  // Helper to parse invoice items
  List<Map<String, dynamic>> _parseInvoiceItems(
    List<dynamic>? items, {
    bool generateId = false,
  }) {
    if (items == null) return [];

    final itemsList = <Map<String, dynamic>>[];
    for (var item in items) {
      final parsedItem = <String, dynamic>{
        'id': generateId ? _generateUuid() : item['uuid'],
        'type': item['invoiceItemType'],
        'totalAmountAfterTaxes': item['totalAmountAfterTaxes'],
        'generalTaxAmount': item['generalTaxAmount'],
        'generalTaxPercentage': item['generalTaxPercentage'],
        'generalTaxType': item['generalTaxType'],
        'totalAmountAfterDiscount': item['totalAmountAfterDiscount'],
        'discountAmount': item['discountAmount'],
        'subtotalAmount': item['subtotalAmount'],
        'specialTaxAmount': item['specialTaxAmount'],
        'unitPrice': item['unitPrice'],
        'customerPrice': item['customerPrice'],
        'quantity': item['quantity'],
        'description': item['productDescription'],
      };

      if (item['isic4'] != null) {
        parsedItem['isic4'] = item['isic4'];
      }

      itemsList.add(parsedItem);
    }

    return itemsList;
  }

  // Helper to generate UUID (simplified version)
  String _generateUuid() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + math.Random().nextInt(9000)).toString();
  }

  // Get buyer ID type text by code
  String _getBuyerIdTypeTextByCode(String? code) {
    if (code == null) return '';

    switch (code) {
      case 'NATIONAL_ID_NUMBER':
        return 'National ID';
      case 'TAX_IDENTIFICATION_NUMBER':
        return 'Tax ID';
      case 'PASSPORT':
        return 'Passport';
      default:
        return code;
    }
  }

  // Get invoice PDF
  Future<File> getInvoicePDF(String invoiceId, String invoiceNumber) async {
    try {
      final uri = Uri.parse(
        '$API_URL/sme/invoices/pdf/$invoiceId/$invoiceNumber',
      );
      final headers = await _getAuthHeaders();

      logger.d('Downloading invoice PDF: $invoiceNumber');
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        Directory? directory;

        if (Platform.isAndroid) {
          if (await _requestStoragePermission()) {
            directory = await getExternalStorageDirectory();
            final downloadsPath = '${directory!.path}/Download';
            directory = Directory(downloadsPath);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } else {
            throw Exception('Storage permission denied');
          }
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = await getTemporaryDirectory();
        }

        // Format current date for the filename
        final now = DateTime.now();
        final formattedDate =
            '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

        final fileName = 'invoice_${invoiceNumber}_$formattedDate.pdf';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        logger.d('PDF saved to: $filePath');

        if (Platform.isAndroid) {
          debugPrint('PDF saved to Downloads folder: $fileName');
        } else if (Platform.isIOS) {
          debugPrint(
              'PDF saved to Files app (On My iPhone/iPad > fafrohjo): $fileName');
        }

        await _sharePDF(file, fileName);

        return file;
      } else {
        throw HttpException('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error downloading PDF: $e');
      rethrow;
    }
  }

  // Share PDF file
  Future<void> _sharePDF(File file, String fileName) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice $fileName',
        subject: 'Invoice PDF',
      );

      if (result.status == ShareResultStatus.success) {
        logger.d('PDF shared successfully');
      }
    } catch (e) {
      logger.e('Error sharing PDF: $e');
    }
  }

  // Request storage permission for Android
  Future<bool> _requestStoragePermission() async {
    return true;
  }

  // Get user logo
  Future<File?> getUserLogo(String activityNumber) async {
    try {
      final uri = Uri.parse(
        '$API_URL/users/user/logo/?activityNumber=$activityNumber',
      );
      final headers = await _getAuthHeaders(activity: activityNumber);

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/logo_$activityNumber.png');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user logo: $e');
      }
      return null;
    }
  }

  // Upload user logo
  Future<dynamic> uploadUserLogo(Map<String, dynamic> data) async {
    return post('/users/user/logo', data);
  }

  // Get taxpayer invoices report
  Future<File?> getTaxpayerInvoicesReport(
    Map<String, String> params,
    String activityNumber,
    String lang,
  ) async {
    try {
      final uri = Uri.parse(
        '$API_URL/sme/invoices/export-excel',
      ).replace(queryParameters: params);

      final headers = {
        ...(await _getAuthHeaders()),
        'Content-Type': 'application/octet-stream',
        'activity': activityNumber,
        'lang': lang,
      };

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/invoices_report_$timestamp.xlsx');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting taxpayer invoices report: $e');
      }
      return null;
    }
  }

  // Update user data
  Future<dynamic> updateUserData(String taxNumber) async {
    return post('/users/auth/update-taxpayer-info', {'taxNumber': taxNumber});
  }

  // Check if tax number is valid
  Future<dynamic> isTaxNumberValid(String taxNumber) async {
    return get('/sme/invoices/invtxpchk/$taxNumber');
  }

  // Generate OTP for forget password
  Future<dynamic> generateOTPForForgetPassword(
    Map<String, dynamic> data,
    String captchaToken,
  ) async {
    return post(
      '/users/forget/generate-otp',
      data,
      headers: {'g-recaptcha-response': captchaToken},
    );
  }

  // Verify forget password OTP
  Future<dynamic> verifyForgetPasswordOTP(Map<String, dynamic> data) async {
    return post('/users/forget/verify-otp', data);
  }

  // Get username with OTP
  Future<dynamic> getUsername(Map<String, dynamic> data, String otp) async {
    return post('/users/forget/username', data, headers: {'OTP': otp});
  }

  // Update password with OTP
  Future<dynamic> updatePassword(Map<String, dynamic> data, String otp) async {
    return post('/users/forget/password', data, headers: {'OTP': otp});
  }

  // Logout
  Future<dynamic> logout() async {
    return post('/users/auth/logout', {});
  }

  // Change password
  Future<dynamic> changePassword(Map<String, dynamic> data) async {
    return post('/users/sub-admin/reset-password', data);
  }

  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    String? activity,
  }) async {
    final headers = await _getAuthHeaders(activity: activity);
    final fullUrl =
        Uri.parse('$API_URL$endpoint').replace(queryParameters: queryParams);

    if (kIsWeb) {
      return _callProxy(
        method: 'GET',
        url: fullUrl.toString(),
        headers: headers,
      );
    }

    final response = await _client.get(fullUrl, headers: headers);
    return _handleResponse(response);
  }

  // POST request
  Future<dynamic> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = await _getAuthHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    if (kIsWeb) {
      return _callProxy(
        method: 'POST',
        url: '$API_URL$endpoint',
        body: data,
        headers: mergedHeaders,
      );
    }

    final response = await _client.post(
      Uri.parse('$API_URL$endpoint'),
      headers: mergedHeaders,
      body: data is String ? data : json.encode(data),
    );

    return _handleResponse(response);
  }

  // PUT request
  Future<dynamic> put(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    final defaultHeaders = await _getAuthHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    if (kIsWeb) {
      return _callProxy(
        method: 'PUT',
        url: '$API_URL$endpoint',
        body: data,
        headers: mergedHeaders,
      );
    }

    final response = await _client.put(
      Uri.parse('$API_URL$endpoint'),
      headers: mergedHeaders,
      body: data is String ? data : json.encode(data),
    );

    return _handleResponse(response);
  }

  // DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    dynamic data,
  }) async {
    final defaultHeaders = await _getAuthHeaders();
    final mergedHeaders = {...defaultHeaders, ...?headers};

    if (kIsWeb) {
      return _callProxy(
        method: 'DELETE',
        url: '$API_URL$endpoint',
        body: data,
        headers: mergedHeaders,
      );
    }

    final request = http.Request('DELETE', Uri.parse('$API_URL$endpoint'));
    request.headers.addAll(mergedHeaders);

    if (data != null) {
      request.body = data is String ? data : json.encode(data);
    }

    final response = await _client.send(request).then(http.Response.fromStream);
    return _handleResponse(response);
  }

  // GET request with OTP
  Future<dynamic> getWithOtp(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final headers = await _getOtpHeaders();
    final fullUrl =
        Uri.parse('$API_URL$endpoint').replace(queryParameters: queryParams);

    if (kIsWeb) {
      return _callProxy(
        method: 'GET',
        url: fullUrl.toString(),
        headers: headers,
      );
    }

    final response = await _client.get(fullUrl, headers: headers);
    return _handleResponse(response);
  }

  // POST request with OTP
  Future<dynamic> postWithOtp(String endpoint, dynamic data) async {
    final headers = await _getOtpHeaders();

    if (kIsWeb) {
      return _callProxy(
        method: 'POST',
        url: '$API_URL$endpoint',
        body: data,
        headers: headers,
      );
    }

    final response = await _client.post(
      Uri.parse('$API_URL$endpoint'),
      headers: headers,
      body: data is String ? data : json.encode(data),
    );

    return _handleResponse(response);
  }

  // PUT request with OTP
  Future<dynamic> putWithOtp(String endpoint, dynamic data) async {
    final headers = await _getOtpHeaders();

    if (kIsWeb) {
      return _callProxy(
        method: 'PUT',
        url: '$API_URL$endpoint',
        body: data,
        headers: headers,
      );
    }

    final response = await _client.put(
      Uri.parse('$API_URL$endpoint'),
      headers: headers,
      body: data is String ? data : json.encode(data),
    );

    return _handleResponse(response);
  }

  // Cloud Proxy Helper
  Future<dynamic> _callProxy({
    required String method,
    required String url,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    logger.d('Calling Proxy: $method $url');
    // logger.d('Headers: ${headers.keys.toList()}'); // Log only keys for safety

    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('proxyRequest');
    final response = await callable.call({
      'method': method,
      'url': url,
      'body': body,
      'headers': headers,
    });

    final String resultString = response.data;
    logger.d('Proxy Response received');
    print('Proxy Response JSON: $resultString');

    final Map<String, dynamic> result = json.decode(resultString);

    final int statusCode = result['status'] ?? 200;
    final dynamic responseData = result['data'];
    print('Proxy Response Data: $responseData');

    if (statusCode >= 200 && statusCode < 300) {
      return responseData;
    } else {
      throw HttpException(
        'API Error: $statusCode - ${responseData["error"] ?? responseData["message"] ?? "Unknown error"}',
      );
    }
  }
}

// Helper function to get temporary directory
Future<Directory> getTemporaryDirectory() async {
  if (Platform.isIOS) {
    final directory = await getDownloadsDirectory();
    return directory!;
  }
  return Directory.systemTemp;
}

// Helper class for random number generation
class Random {
  static final Random _instance = Random._internal();

  factory Random() {
    return _instance;
  }

  Random._internal();

  int nextInt(int max) {
    return DateTime.now().millisecondsSinceEpoch % max;
  }
}
