// import 'package:durub_ali/aiAgent/aiAgentSidePanal.dart';
import 'package:good_line_delivery/aiAgent/aiAgentSidePanal.dart';
import 'package:good_line_delivery/aiAgent/tools.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

// import '../aiAgent/tools.dart';
import '../main.dart';
import '../screens/AddOrder/AddOrderForm.dart';
import '../screens/dashboard/header/showSideDrawerDialog.dart';
import '../utils/utilities.dart';
import '../utils/file_handler.dart';
import '../models/customer.dart';
import '../models/Driver.dart';
import '../models/InAppNotification.dart';
import '../models/Expense.dart';
import '../models/Inventory.dart';
import '../models/Transfer.dart';
import '../models/Shelf.dart';
import 'firebaseHelper.dart';
import 'package:flutter/material.dart';

import '../models/PriceCalculators.dart';
import '../models/Shipment.dart';
import 'NotificationService.dart';
import '../models/City.dart';
import '../models/supply_order.dart';
import '../models/PackageType.dart';

class AppProvider extends ChangeNotifier {
  List<Customer> customers = [];
  Customer? selectedCustomer;
  List<Driver> drivers = [];
  List<Driver> employees = [];
  Driver? selectedDriver;
  List<String> cities = [];
  List<Expense> expenses = [];
  List<String> expenseTypes = [];
  City? selectedCityPlace;

  List<UserShippingRoute> userShippingRoutes = [];
  UserShippingRoute? selectedShippingRoute;

  List<UserShippingRoute> driverShippingRoutes = [];
  UserShippingRoute? selectedDriverShippingRoute;
  List<Shipment> orders = [];

  FirebaseHelper firebaseHelper = FirebaseHelper();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<City> citiesAndPlaces = [];
  List<String> citiesAndPlacesNames = [];

  List<String> bankAccounts = [];
  List<Transfer> transfers = [];

  Inventory? selectedInventory;
  Driver? currentUserEmployee;

  bool isChatPanelOpen = false;

  List<Usage> aiUsages = [];
  bool autoAssignEnabled = true;
  bool autoCollectionEnabled = false;
  List<Map<String, dynamic>> excelConfigs = [];

  List<PackageType> packageTypes = [];

  void listenToPackageTypes() {
    firebaseHelper.packageTypesStream().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        if (snapshot.data()!.containsKey('types')) {
          packageTypes = List<Map<String, dynamic>>.from(snapshot.data()!['types'])
              .map((e) => PackageType.fromMap(e))
              .toList();
          notifyListeners();
        }
      }
    });
  }

  void listenToExcelConfigs() {
    firebaseHelper.getExcelConfigsStream().listen((configs) {
      excelConfigs = configs;
      notifyListeners();
    });
  }

  Future<void> addExcelConfig(Map<String, dynamic> config) async {
    await firebaseHelper.addExcelConfig(config);
  }

  Future<void> updateExcelConfig(String id, Map<String, dynamic> config) async {
    await firebaseHelper.updateExcelConfig(id, config);
  }

  Future<void> deleteExcelConfig(String id) async {
    await firebaseHelper.deleteExcelConfig(id);
  }

  Future<String> addOrder(Map<String, dynamic> data) async {
    String orderId = await firebaseHelper.addOrder(data,
        autoAssign: autoAssignEnabled, autoCollection: autoCollectionEnabled);
    notifyListeners();
    return orderId;
  }

  void getCustomers() {
    firebaseHelper.getCustomersStream().listen((customersList) {
      customers = customersList;
      notifyListeners();
    });
  }

  void setSelectedCustomer(Customer value) {
    selectedCustomer = value;
    notifyListeners();
  }

  void selectCustomerByNameOrPhone(String nameOrPhone) {
    try {
      selectedCustomer = customers.firstWhere((customer) =>
          customer.username == nameOrPhone ||
          customer.phoneNumber == nameOrPhone);
      notifyListeners();
    } catch (e) {
      print('Error selecting customer: $e');
    }
  }

  getDrivers() async {
    drivers = await firebaseHelper.getDrivers();
    //selectedDriver = drivers[0];
    notifyListeners();
  }

  getEmployees() async {
    employees = await firebaseHelper.getEmployees();
    notifyListeners();
  }

  getOrder(String orderId) async {
    return await firebaseHelper.getOrder(orderId);
  }

  assignDriver(String orderId, Driver driver) {
    firebaseHelper.assignDriver(orderId, driver);
    notifyListeners();
  }

  assignCollectionDriver(String orderId, Driver driver) {
    firebaseHelper.assignCollectionDriver(orderId, driver);
    notifyListeners();
  }

  updateOrderStatus(String orderId, String status, Driver? driver, String? note,
      {bool? receivedMoneyFromCustomer,
      bool? getMoneyFromUserPalance,
      bool? returnedAfterDelivery,
      Shelf? shelf,
      OrderPossession? orderPossession,
      DateTime? postponementDate}) {
    if (!Utilities.checkPermission("تغير الحاله")) {
      return;
    }
    firebaseHelper.updateOrderStatus(orderId, status, driver, note,
        receivedMoneyFromCustomer: receivedMoneyFromCustomer,
        getMoneyFromUserPalance: getMoneyFromUserPalance,
        returnedAfterDelivery: returnedAfterDelivery,
        shelf: shelf,
        orderPossession: orderPossession,
        postponementDate: postponementDate);
  }

  removeDriver(String orderId) {
    firebaseHelper.removeDriver(orderId);
    notifyListeners();
  }

  updateOrderPrice(
      String orderId, double oldPrice, double price, String? userId) {
    if (!Utilities.checkPermission("تغير السعر")) {
      return;
    }
    firebaseHelper.updateOrderPrice(orderId, oldPrice, price, userId);
  }

  addArea(String data) {
    firebaseHelper.addArea(data);
  }

  removeArea(String data) {
    firebaseHelper.removeArea(data);
  }

  getAreas() async {
    firebaseHelper.areasStream().listen((event) {
      if (event.exists &&
          event.data() != null &&
          event.data()!.containsKey('expenseTypes')) {
        expenseTypes = List<String>.from(event.get('expenseTypes'));
      } else {
        expenseTypes = [];
      }
      notifyListeners();
    });
  }

  getPriceCalculator({bool isDriver = false}) async {
    firebaseHelper.priceCalculatorStream(isDriver).listen((event) {
      if (isDriver) {
        final oldSelectedId = selectedDriverShippingRoute?.userId;
        driverShippingRoutes = event.docs
            .map((e) => UserShippingRoute.fromJson(e.data()))
            .toList();

        if (driverShippingRoutes.isNotEmpty) {
          final sameDriverRoute = driverShippingRoutes
              .where((e) => e.userId == oldSelectedId)
              .firstOrNull;
          if (sameDriverRoute != null) {
            selectedDriverShippingRoute = sameDriverRoute;
          } else {
            selectedDriverShippingRoute = driverShippingRoutes
                    .where((e) => e.userId == 'main')
                    .firstOrNull ??
                driverShippingRoutes.first;
          }
        } else {
          selectedDriverShippingRoute = null;
        }
      } else {
        print("this is event ${event.docs}");
        final oldSelectedId = selectedShippingRoute?.userId;
        userShippingRoutes = event.docs
            .map((e) => UserShippingRoute.fromJson(e.data()))
            .toList();

        if (userShippingRoutes.isNotEmpty) {
          // Try to keep the same user selected if possible
          final sameUserRoute = userShippingRoutes
              .where((e) => e.userId == oldSelectedId)
              .firstOrNull;
          if (sameUserRoute != null) {
            selectedShippingRoute = sameUserRoute;
          } else {
            // Fallback to main if old selection is gone or was main anyway
            selectedShippingRoute = userShippingRoutes
                    .where((e) => e.userId == 'main')
                    .firstOrNull ??
                userShippingRoutes.first;
          }
        } else {
          selectedShippingRoute = null;
        }
      }
      notifyListeners();
    });
  }

  updatePriceCalculator(ShippingRoute shippingRoute, {bool isDriver = false}) {
    if (isDriver) {
      if (selectedDriverShippingRoute != null) {
        firebaseHelper.updatePriceCalculator(
            selectedDriverShippingRoute!.userId, shippingRoute, isDriver);
      } else {
        firebaseHelper.addPriceCalculator(
            selectedDriver!.userid!, shippingRoute, isDriver);
      }
    } else {
      if (selectedShippingRoute != null) {
        firebaseHelper.updatePriceCalculator(
            selectedShippingRoute!.userId, shippingRoute, isDriver);
      } else {
        firebaseHelper.addPriceCalculator(
            selectedCustomer!.userid, shippingRoute, isDriver);
      }
    }
  }

  deleteShippingRoute(ShippingRoute shippingRoute, {bool isDriver = false}) {
    firebaseHelper.deleteShippingRoute(
        selectedShippingRoute!.userId, shippingRoute, isDriver);
  }

  replaceShippingRoute(ShippingRoute oldRoute, ShippingRoute newRoute,
      {bool isDriver = false}) {
    String? userId = isDriver
        ? selectedDriverShippingRoute?.userId
        : selectedShippingRoute?.userId;

    if (userId != null) {
      // First delete the old route
      firebaseHelper.deleteShippingRoute(userId, oldRoute, isDriver);
      // Then add the new route
      firebaseHelper.updatePriceCalculator(userId, newRoute, isDriver);
    }
  }

  Future<void> importPricesFromExcel(BuildContext context,
      {bool isDriver = false}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result != null) {
        Uint8List? bytes;
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes;
        } else if (result.files.single.path != null) {
          // In some platforms like web, path is null and bytes are provided
          // In desktop, path is provided. File(path).readAsBytes() would be needed.
          // Since this app uses universal_html and seems to target multiple platforms,
          // we should handle both.
          // For now, let's assume result.files.single.bytes is available or we use a cross-platform way.
        }

        bytes ??= result.files.single.bytes;

        if (bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على محتوى الملف')),
          );
          return;
        }

        List<ShippingRoute> newRoutes = [];
        String fileName = result.files.single.name.toLowerCase();

        if (fileName.endsWith('.csv')) {
          String content = utf8.decode(bytes);
          List<String> lines = content.split('\n');
          // Skip header row
          for (int i = 1; i < lines.length; i++) {
            String line = lines[i].trim();
            if (line.isEmpty) continue;

            List<String> columns = line.split(',');
            if (columns.length < 3) continue;

            newRoutes.add(ShippingRoute(
              from: columns[0].trim(),
              to: columns[1].trim(),
              deliveryPrice: double.tryParse(columns[2].trim()) ?? 0.0,
              returnPrice: columns.length > 3
                  ? (double.tryParse(columns[3].trim()) ?? 0.0)
                  : 0.0,
              returnBeforeDeliveryPrice: columns.length > 4
                  ? (double.tryParse(columns[4].trim()) ?? 0.0)
                  : 0.0,
            ));
          }
        } else if (fileName.endsWith('.xlsx')) {
          var excel = Excel.decodeBytes(bytes);
          for (var table in excel.tables.keys) {
            var sheet = excel.tables[table];
            if (sheet == null) continue;

            // Skip header row
            for (int i = 1; i < sheet.maxRows; i++) {
              var row = sheet.rows[i];
              if (row.length < 3) continue;

              newRoutes.add(ShippingRoute(
                from: row[0]?.value?.toString() ?? '',
                to: row[1]?.value?.toString() ?? '',
                deliveryPrice:
                    double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0,
                returnPrice:
                    double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0.0,
                returnBeforeDeliveryPrice:
                    double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0.0,
              ));
            }
          }
        }

        if (newRoutes.isNotEmpty) {
          String? id;
          if (isDriver) {
            id = selectedDriver?.userid ?? 'main';
          } else {
            id = selectedCustomer?.userid ?? 'main';
          }

          await firebaseHelper.updatePriceCalculatorBatch(
              id, newRoutes, isDriver);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استيراد الأسعار بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('لم يتم العثور على بيانات صالحة في الملف')),
          );
        }
      }
    } catch (e) {
      print('Error importing file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في استيراد الملف: $e')),
      );
    }
  }

  Future<void> exportPricesToExcel(BuildContext context,
      {bool isDriver = false}) async {
    try {
      List<ShippingRoute> routes = isDriver
          ? (selectedDriverShippingRoute?.shippingRoute ?? [])
          : (selectedShippingRoute?.shippingRoute ?? []);

      if (routes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات لتصديرها')),
        );
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['الأسعار'];
      excel.delete('Sheet1'); // Delete default sheet

      // Add Headers
      sheetObject.appendRow([
        TextCellValue('من المنطقة'),
        TextCellValue('إلى المنطقة'),
        TextCellValue('سعر التوصيل'),
        TextCellValue('سعر الإرجاع'),
        TextCellValue('سعر الإرجاع قبل التوصيل')
      ]);

      // Add Data
      for (var route in routes) {
        sheetObject.appendRow([
          TextCellValue(route.from),
          TextCellValue(route.to),
          DoubleCellValue(route.deliveryPrice),
          DoubleCellValue(route.returnPrice),
          DoubleCellValue(route.returnBeforeDeliveryPrice),
        ]);
      }

      var bytes = excel.save();
      if (bytes != null) {
        String fileName = isDriver
            ? 'driver_prices_${selectedDriver?.username ?? "all"}.xlsx'
            : 'customer_prices_${selectedCustomer?.username ?? "all"}.xlsx';

        await FileHandler.downloadFile(Uint8List.fromList(bytes), fileName);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير الملف بنجاح')),
        );
      }
    } catch (e) {
      print('Error exporting excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تصدير الملف: $e')),
      );
    }
  }

  void setSelectedDriver(Driver value) {
    selectedDriver = value;
    notifyListeners();
  }

  //notification__________________________________________________________________________________________
  List<InAppNotification> notifications = [];
  int unreadNotifications = 0;

  final NotificationService _notificationService = NotificationService();
  getNotifications() async {
    _notificationService.getNotifications().listen((event) {
      notifications = event;
      unreadNotifications =
          notifications.where((element) => !element.isRead).length;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead(notifications);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(notificationId);
  }

  Future<void> deleteAllNotifications() async {
    await _notificationService.deleteAllNotifications(notifications);
  }

  void updateOrder(Map<String, dynamic> data) {
    firebaseHelper.updateOrder(data);
    notifyListeners();
  }

  // Expense Methods
  void listenToExpenses() {
    firebaseHelper.getExpensesStream().listen((snapshot) {
      expenses = snapshot.docs
          .map((doc) =>
              Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    });
  }

  Future<String> addExpense(Map<String, dynamic> data) async {
    return await firebaseHelper.addExpense(data);
  }

  void listenToBankAccounts() {
    print("Starting to listen to bank accounts");
    firebaseHelper.getBankAccountsStream().listen((accounts) {
      print("Received bank accounts in AppProvider: $accounts");
      bankAccounts = accounts;
      notifyListeners();
    }, onError: (error) {
      print("Error listening to bank accounts: $error");
    });
  }

  Future<void> addAccountName(String name) async {
    try {
      await firebaseHelper.addAccountName(name);
      print("Account added through AppProvider: $name");
    } catch (e) {
      print("Error adding account through AppProvider: $e");
      rethrow;
    }
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    await firebaseHelper.updateExpense(id, data);
  }

  Future<void> deleteExpense(String id) async {
    await firebaseHelper.deleteExpense(id);
  }

  Future<void> addExpenseType(String name) async {
    await firebaseHelper.addExpenseType(name);
  }

  Future<void> deleteExpenseType(String id) async {
    await firebaseHelper.deleteExpenseType(id);
  }

  Future<void> addTransfer(Map<String, dynamic> data) async {
    await firebaseHelper.addTransfer(data);
    notifyListeners();
  }

  Future<void> init() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await getCurrentUserEmployee();
    getNotifications();
    getPriceCalculator();
    getPriceCalculator(isDriver: true);
    getCitiesAndPlaces();
    getAreas();
    getCustomers();
    getDrivers();
    getEmployees();
    listenToExpenses();
    listenToBankAccounts();
    listenToTransfers();
    listenToShelves(); // Add this line
    listenToSettings();
    listenToPackageTypes();
    // listenToAiUsages();
  }

  void listenToSettings() {
    firebaseHelper.getSettingsStream().listen((settings) {
      if (settings.containsKey('autoAssignEnabled')) {
        autoAssignEnabled = settings['autoAssignEnabled'];
      }
      if (settings.containsKey('autoCollectionEnabled')) {
        autoCollectionEnabled = settings['autoCollectionEnabled'];
      }
      notifyListeners();
    });
  }

  Future<void> updateAutoAssign(bool value) async {
    Map<String, dynamic> updates = {'autoAssignEnabled': value};
    if (value) {
      updates['autoCollectionEnabled'] = false;
    }
    await firebaseHelper.updateSettings(updates);
  }

  Future<void> updateAutoCollection(bool value) async {
    Map<String, dynamic> updates = {'autoCollectionEnabled': value};
    if (value) {
      updates['autoAssignEnabled'] = false;
    }
    await firebaseHelper.updateSettings(updates);
  }

  getCurrentUserEmployee() async {
    try {
      currentUserEmployee = await firebaseHelper.getCurrentUserEmployee();
      notifyListeners();
    } catch (e) {
      print('Error getting current user employee: $e');
      // Handle the case where user is not found in drivers collection
      // You might want to redirect to login or show an error message
      currentUserEmployee = null;
      notifyListeners();
    }
  }

  void addCity(City city) {
    firebaseHelper.addCity(city);
    notifyListeners();
  }

  void updateCity(String oldCityName, City city) {
    firebaseHelper.updateCity(oldCityName, city);
    notifyListeners();
  }

  void deleteCity(String cityName) {
    firebaseHelper.deleteCity(cityName);
    notifyListeners();
  }

  void getCitiesAndPlaces() {
    firebaseHelper.citiesStream().listen((data) {
      citiesAndPlaces.clear();
      cities = List<String>.from(data.keys);

      data.forEach((cityName, places) {
        citiesAndPlaces.add(City(
          name: cityName,
          places: List<String>.from(places),
        ));
      });
      citiesAndPlacesNames.clear();
      Set<String> uniqueNames = {};
      for (var city in citiesAndPlaces) {
        for (var place in city.places) {
          uniqueNames.add(city.name + " " + place);
        }
      }
      citiesAndPlacesNames = uniqueNames.toList();

      notifyListeners();
    });
  }

  void listenToTransfers() {
    firebaseHelper.getTransfersStream().listen((transfersList) {
      transfers = transfersList;
      notifyListeners();
    });
  }

  double getAccountBalance(String accountName) {
    double balance = 0;
    for (Transfer transfer in transfers) {
      if (transfer.toAccountDisplay == accountName) {
        balance += transfer.amount;
      }
      if (transfer.fromAccountDisplay == accountName) {
        balance -= transfer.amount;
      }
    }
    return balance;
  }

  // Inventory Management Methods
  Future<Inventory?> getCustomerInventory(String userId) async {
    return await firebaseHelper.getCustomerInventory(userId);
  }

  Stream<Inventory> getCustomerInventoryStream(String userId) {
    return firebaseHelper.getCustomerInventoryStream(userId);
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    if (selectedCustomer == null) return;

    await firebaseHelper.addInventoryItem(
        selectedCustomer!.userid, selectedCustomer!.username, item);
    notifyListeners();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    if (selectedCustomer == null) return;

    await firebaseHelper.updateInventoryItem(selectedCustomer!.userid, item);
    notifyListeners();
  }

  Future<void> deleteInventoryItem(String itemId) async {
    if (selectedCustomer == null) return;

    await firebaseHelper.deleteInventoryItem(selectedCustomer!.userid, itemId);
    notifyListeners();
  }

  Future<void> updateInventoryItemQuantity(
      String userId, String itemId, int quantity) async {
    final inventory = await getCustomerInventory(userId);
    if (inventory == null) return;

    final item = inventory.items.firstWhere((item) => item.id == itemId);
    final updatedItem = InventoryItem(
      id: item.id,
      name: item.name,
      quantity: item.quantity - quantity,
      price: item.price,
      description: item.description,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await firebaseHelper.updateInventoryItem(userId, updatedItem);
    notifyListeners();
  }

  // Get shipments for customer with selectedItems in date range
  Future<List<Shipment>> getCustomerShipmentsWithItems(
      String userId, DateTime startDate, DateTime endDate) async {
    return await firebaseHelper.getCustomerShipmentsWithItems(
        userId, startDate, endDate);
  }

  void deleteOrders(Set<String> selectedOrderIds) {
    firebaseHelper.deleteOrders(selectedOrderIds);
  }

  double calculateDeliveryCostForCity(String cityName, String userId, {String packageTypeName = 'العادية'}) {
    if (cityName.isEmpty || userId.isEmpty) return 0;

    String normalizedInput = Utilities.normalizeArabic(cityName);

    // Identify parent city if the input is a sub-region or contains sub-region info
    String? parentCity;
    for (var city in citiesAndPlaces) {
      String normCityName = Utilities.normalizeArabic(city.name);
      if (normalizedInput.contains(normCityName)) {
        parentCity = normCityName;
        break;
      }
      for (var place in city.places) {
        if (normalizedInput.contains(Utilities.normalizeArabic(place))) {
          parentCity = normCityName;
          break;
        }
      }
      if (parentCity != null) break;
    }

    String cleanCityName = normalizedInput;
    String? normParentCity = parentCity;

    // Find customer
    final customer = customers.where((c) => c.userid == userId).firstOrNull;
    if (customer == null) return 0;

    String? customerCity = customer.city != null
        ? Utilities.normalizeArabic(customer.city!)
        : null;

    try {
      // Find customer-specific shipping route or fallback to main
      UserShippingRoute? customerRoute = userShippingRoutes.firstWhere(
        (route) => route.userId == userId,
        orElse: () => userShippingRoutes.firstWhere(
          (route) => route.userId == 'main',
          orElse: () => UserShippingRoute(userId: 'none', shippingRoute: []),
        ),
      );

      if (customerRoute.shippingRoute.isEmpty) {
        customerRoute = userShippingRoutes
            .where((route) => route.userId == 'main')
            .firstOrNull;
      }

      if (customerRoute == null || customerRoute.shippingRoute.isEmpty)
        return 0;

      // Find matching route for selected city
      ShippingRoute? matchingRoute = customerRoute.shippingRoute.firstWhere(
        (route) {
          String routeTo = Utilities.normalizeArabic(route.to);
          String routeFrom = Utilities.normalizeArabic(route.from);

          bool typeMatch = (route.packageTypeName ?? 'العادية') == packageTypeName;
          if (!typeMatch) return false;

          bool toMatch = routeTo == cleanCityName ||
              (normParentCity != null && routeTo == normParentCity);
          bool fromMatch = customerCity != null && routeFrom == customerCity;

          if (toMatch && fromMatch) return true;

          // Inverse match check
          bool inverseToMatch = routeFrom == cleanCityName ||
              (normParentCity != null && routeFrom == normParentCity);
          bool inverseFromMatch =
              customerCity != null && routeTo == customerCity;

          return inverseToMatch && inverseFromMatch;
        },
        orElse: () {
          // If no direct match, try fuzzy matching as a fallback
          try {
            if (customerRoute!.shippingRoute.isEmpty) throw "Empty routes";

            int highestScore = 0;
            int bestRouteIndex = -1;

            for (int i = 0; i < customerRoute.shippingRoute.length; i++) {
              var route = customerRoute.shippingRoute[i];
              String routeTo = Utilities.normalizeArabic(route.to);
              String routeFrom = Utilities.normalizeArabic(route.from);

              bool typeMatch = (route.packageTypeName ?? 'العادية') == packageTypeName;
              if (!typeMatch) continue;

              int scoreTo = ratio(routeTo, cleanCityName);
              int scoreFrom = ratio(routeFrom, cleanCityName);

              if (normParentCity != null) {
                int pScoreTo = ratio(routeTo, normParentCity);
                int pScoreFrom = ratio(routeFrom, normParentCity);
                scoreTo = scoreTo > pScoreTo ? scoreTo : pScoreTo;
                scoreFrom = scoreFrom > pScoreFrom ? scoreFrom : pScoreFrom;
              }

              int currentMax = scoreTo > scoreFrom ? scoreTo : scoreFrom;

              if (currentMax > highestScore) {
                highestScore = currentMax;
                bestRouteIndex = i;
              }
            }

            if (highestScore > 80 && bestRouteIndex != -1) {
              return customerRoute.shippingRoute[bestRouteIndex];
            }
          } catch (e) {
            print("Fuzzy matching error: $e");
          }

          // Final Fallback: try main routes destination only
          UserShippingRoute? mainRoute = userShippingRoutes
              .where((route) => route.userId == 'main')
              .firstOrNull;
          if (mainRoute == null) {
            return ShippingRoute(
                from: '',
                to: '',
                deliveryPrice: 0,
                returnPrice: 0,
                returnBeforeDeliveryPrice: 0);
          }

          return mainRoute.shippingRoute.firstWhere(
            (route) {
              String rtTo = Utilities.normalizeArabic(route.to);
              String rtFrom = Utilities.normalizeArabic(route.from);
              bool typeMatch = (route.packageTypeName ?? 'العادية') == packageTypeName;
              if (!typeMatch) return false;
              return rtTo == cleanCityName ||
                  rtFrom == cleanCityName ||
                  (normParentCity != null &&
                      (rtTo == normParentCity || rtFrom == normParentCity));
            },
            orElse: () => ShippingRoute(
                from: '',
                to: '',
                deliveryPrice: 0,
                returnPrice: 0,
                returnBeforeDeliveryPrice: 0),
          );
        },
      );

      return matchingRoute.deliveryPrice;
    } catch (e) {
      print("Error calculating cost: $e");
      return 0;
    }
  }

  // //ai agent__________________________________________________________________________________________
  Future<GenerateContentResponse?> handleAiAgentFunctionCall(
      List<FunctionCall> functionCalls, ChatSession chat) async {
    GenerateContentResponse? response;
    String message = '';
    for (FunctionCall functionCall in functionCalls) {
      if (functionCall.name.contains(addShipmentToolName)) {
        Map<String, dynamic>? driver =
            functionCall.args['driver'] as Map<String, dynamic>?;
        Map<String, dynamic> customer =
            functionCall.args['customer'] as Map<String, dynamic>;
        double deliveryCost = calculateDeliveryCostForCity(
            functionCall.args['city'].toString(), customer['userId']);
        double? deliveryCostFromFunction =
            functionCall.args["deliveryCost"] as double?;
        print("deliveryCostFromFunction: $deliveryCostFromFunction");
        print("deliveryCost: $deliveryCost");

        Shipment shipment = Shipment.fromMap(functionCall.args).copyWith(
          orderId: DateTime.now()
              .millisecondsSinceEpoch
              .toString()
              .replaceRange(0, 2, ''),
          userId: customer['userId'],
          deliveryCost: deliveryCostFromFunction ?? deliveryCost,
          username: customer['username'],
          userphone: customer['userphone'],
          status: driver != null ? 'بانتظار موافقة السائق' : "الطلبات الجديدة",
          driverId: driver?['driverId'],
          driverName: driver?['driverName'],
          driver:
              drivers.where((e) => e.userid == driver?['driverId']).firstOrNull,
        );
        print(shipment.toMap());
        if (functionCall.name == addShipmentToolName) {
          String orderId = await addOrder(shipment.toMap());
          message += "\nتم اضافة الشحنة بنجاح والرقم التعريفي للشحنة: $orderId";
        } else {
          showSideDrawerDialog(
              context: navigatorKey.currentContext!,
              child: AddOrderForm(isEditMode: false, shipment: shipment));
        }
        continue;
      }
      switch (functionCall.name) {
        case assignDriverToolName:
          String orderId = functionCall.args['orderId'] as String;
          Map<String, dynamic> driver =
              functionCall.args['driver'] as Map<String, dynamic>;
          Driver? driverObject =
              drivers.where((e) => e.userid == driver['driverId']).firstOrNull;

          await assignDriver(orderId, driverObject!);

          message += "\nتم تعيين السائق بنجاح";
          break;
        case getOrdersInfoToolName:
          String? status = functionCall.args['status'] as String?;
          List<Shipment> orders =
              await firebaseHelper.getOrders(status: status);
          message += "\n${orders.map((e) => {
                "orderId": e.orderId,
                "status": e.status,
                "driverName": e.driverName,
                "driverId": e.driverId,
                "customerName": e.username,
                "customerId": e.userId,
                "city": e.city,
                "recipientName": e.recipientName,
                "phoneNumber": e.userphone,
              }).toList()}";
          break;
      }
    }
    if (message.isNotEmpty) {
      response = await chat.sendMessage(Content.text(message));
    }
    return response;
  }

  void listenToAiUsages() {
    firebaseHelper.getAiUsageStream().listen((usages) {
      aiUsages = usages.map((e) => Usage.fromJson(e)).toList();
      notifyListeners();
    });
  }

  Future<void> saveAiUsage(Map<String, dynamic> usage) async {
    await firebaseHelper.saveAiUsage(usage);
    notifyListeners();
  }

  // Shelf Management Methods
  List<Shelf> shelves = [];

  void listenToShelves() {
    firebaseHelper.getShelvesStream().listen((shelvesList) {
      shelves = shelvesList;
      notifyListeners();
    });
  }

  Future<void> addShelf(Shelf shelf) async {
    try {
      await firebaseHelper.addShelf(shelf.toMap());
      // Add to local list immediately for better UX
      shelves.add(shelf);
      notifyListeners();
    } catch (e) {
      print('Error adding shelf: $e');
      // You might want to show a user-friendly error message here
      throw e; // Re-throw so the UI can handle it
    }
  }

  Future<void> updateShelf(Shelf shelf) async {
    try {
      await firebaseHelper.updateShelf(shelf.id!, shelf.toMap());
      // Update local list immediately for better UX
      final index = shelves.indexWhere((s) => s.id == shelf.id);
      if (index != -1) {
        shelves[index] = shelf;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating shelf: $e');
      throw e;
    }
  }

  Future<void> deleteShelf(String shelfId) async {
    try {
      await firebaseHelper.deleteShelf(shelfId);
      // Remove from local list immediately for better UX
      shelves.removeWhere((shelf) => shelf.id == shelfId);
      notifyListeners();
    } catch (e) {
      print('Error deleting shelf: $e');
      throw e;
    }
  }

  // Get shipments on a specific shelf
  Future<List<Shipment>> getShipmentsOnShelf(Shelf shelf) async {
    // return orders.where((shipment) {
    //   if (shipment.shelfId == null) return false;
    // return shipment.shelfId==shelf.id;
    // }).toList();
    return firebaseHelper.getOrdersByShelfId(shelf.id!);
  }

  Future<String> createBundledShipment(Set<String> selectedOrderIds) async {
    return await firebaseHelper.createBundledShipment(selectedOrderIds);
  }

  Future<List<SupplyOrder>> checkSupplyOrders(String userId) async {
    return await firebaseHelper.getSupplyOrdersForUser(userId);
  }

  Future<void> reciveReturnOrder(String orderId) async {
    return await firebaseHelper.reciveReturnOrder(orderId);
  }

  Future<void> updateIsCompanyDeliveryFeePaid(
      Shipment shipment, bool bool) async {
    return await firebaseHelper.updateIsCompanyDeliveryFeePaid(shipment, bool);
  }
}
