import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Shelf.dart';
import 'constants.dart';
import '../models/DocmentFile.dart';
import '../models/Inventory.dart';
import '../models/Shipment.dart';
import '../models/Transfer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/ChatMessage.dart';
import '../models/customer.dart';
import '../models/Driver.dart';
import '../models/DriverDeliveryData.dart';
import '../models/PriceCalculators.dart';
import '../models/UserAccount.dart';
import 'NotificationService.dart';
import '../models/City.dart';
import '../models/supply_order.dart';

class FirebaseHelper {
  final _fireStore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();

  CollectionReference get users => _fireStore.collection('users');
  CollectionReference get products => _fireStore.collection('drivers');
  CollectionReference get orders => _fireStore.collection('orders');
  CollectionReference get expenses => _fireStore.collection('expenses');
  CollectionReference get accounts => _fireStore.collection('accounts');
  CollectionReference get expenseTypes => _fireStore.collection('expenseTypes');
  CollectionReference get configs => _fireStore.collection('configs');
  CollectionReference get inventory =>
      _fireStore.collection('inventoryManagement');
  CollectionReference get settings => _fireStore.collection('settings');
  CollectionReference<Map<String, dynamic>> get excelConfigs =>
      _fireStore.collection('excelConfigs');
  Stream<Map<String, dynamic>> getSettingsStream() {
    return settings.doc('general').snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    });
  }

  Stream<List<Map<String, dynamic>>> getExcelConfigsStream() {
    return excelConfigs.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> addExcelConfig(Map<String, dynamic> config) async {
    await excelConfigs.add(config);
  }

  Future<void> updateExcelConfig(String id, Map<String, dynamic> config) async {
    await excelConfigs.doc(id).update(config);
  }

  Future<void> deleteExcelConfig(String id) async {
    await excelConfigs.doc(id).delete();
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await settings.doc('general').set(data, SetOptions(merge: true));
  }

  Future<void> addCustomer(Customer customer) async {
    await users.doc(customer.userid).set(
      {
        ...customer.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  static Future<UserCredential?> registerUserAsAdmin(
      String email, String password) async {
    FirebaseApp? app;
    try {
      // Generate a unique name for each secondary app instance
      String uniqueName = 'Secondary${DateTime.now().millisecondsSinceEpoch}';
      app = await Firebase.initializeApp(
          name: uniqueName, options: Firebase.app().options);

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: app)
          .createUserWithEmailAndPassword(email: email, password: password);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    } finally {
      // Ensure app is always deleted in the finally block
      if (app != null) {
        await app.delete();
      }
    }
  }

  Future<List<String>> getDriversList() async {
    try {
      final drivers = await getDrivers();
      return drivers
          .where(
              (driver) => driver.category != null) // أو أي شرط للسائقين النشطين
          .map((driver) => driver.username ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error loading drivers: $e');
      return [];
    }
  }

// جلب الطلبات المرجعة التي لم يتم إعادة تعيينها
  Stream<List<Shipment>> getReturnedShipments() {
    return _fireStore
        .collection('orders')
        .where('status', isEqualTo: 'تم إرجاعها')
        .where('reassignedToDriver', isEqualTo: false)
        .orderBy('returnOrderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Shipment.fromMap(doc.data())).toList();
    });
  }

// تعيين الطلبات المرجعة للسائق
  Future<void> assignReturnedShipmentsToDriver({
    required List<String> shipmentIds,
    required String driverName,
  }) async {
    try {
      final WriteBatch batch = _fireStore.batch();
      final DateTime now = DateTime.now();

      // البحث عن معرف السائق من اسمه
      final driversSnapshot = await _fireStore
          .collection('drivers')
          .where('username', isEqualTo: driverName)
          .limit(1)
          .get();

      String? driverId;
      if (driversSnapshot.docs.isNotEmpty) {
        driverId = driversSnapshot.docs.first.id;
      }

      for (String shipmentId in shipmentIds) {
        final DocumentReference shipmentRef =
            _fireStore.collection('orders').doc(shipmentId);

        batch.update(shipmentRef, {
          'driverId': driverId,
          'driverName': driverName,
          'status': 'تم إرجاعها',
          'reassignedToDriver': true,
          'orderPossession': 'driver',
          'reassignedDate': now.toIso8601String(),
          'reassignedBy': user?.displayName ?? 'admin',
          'lastUpdated': now.toIso8601String(),
          'logs': FieldValue.arrayUnion([
            {
              'date': now.toIso8601String(),
              'text': 'تم إعادة تعيين الطرد المرجع للسائق $driverName',
              'status': 'بانتظار موافقة السائق',
              'userName': user?.displayName ?? 'مجهول',
            }
          ]),
        });
      }

      await batch.commit();

      // إرسال إشعار للسائق
      if (driverId != null) {
        _notificationService.createNotification(
          title: 'تم تعيين ${shipmentIds.length} طرد مرجع لك',
          message: 'تم إعادة تعيين طرود مرجعة لتوصيلها',
          type: 'order',
          recipientId: driverId,
          orderId: shipmentIds.first,
        );
      }
    } catch (e) {
      print('Error assigning returned shipments: $e');
      throw Exception('فشل تعيين الطلبات للسائق: $e');
    }
  }

  getCurrentUserEmployee() async {
    var snapshot = await _fireStore.collection('drivers').doc(user?.uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Driver document not found or data is null');
    }
    var driver = Driver.fromJson(snapshot.data()!);
    userPermissions = driver.permissions;
    if (driver.category == "مدير النظام") {
      userPermissions = permissions;
    }
    return driver;
  }

  Future<List<Shipment>> getOrders(
      {String? status,
      String? driverId,
      String? customerId,
      String? phoneNumber}) async {
    Query query = _fireStore.collection('orders');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (driverId != null) {
      query = query.where('driverId', isEqualTo: driverId);
    }
    if (customerId != null) {
      query = query.where('userId', isEqualTo: customerId);
    }
    if (phoneNumber != null) {
      query = query.where('phoneNumber', isEqualTo: phoneNumber);
    }
    var snapshot = await query.get();
    return snapshot.docs
        .map((e) => Shipment.fromMap(e.data() as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, String>?> findDriverForOrder(String cityPlace) async {
    try {
      final querySnapshot = await _fireStore
          .collection('tours')
          .where('areas', arrayContains: cityPlace)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['driverId'] != null) {
            return {
              'driverId': data['driverId'],
              'driverName': data['driverName'],
            };
          }
        }
      }
    } catch (e) {
      print('Error finding driver for tour: $e');
    }
    return null;
  }

  Future<Map<String, String>?> findCollectionDriverForCustomer(
      String customerName) async {
    try {
      final querySnapshot = await _fireStore
          .collection('collection_tours')
          .where('customers', arrayContains: customerName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['driverId'] != null) {
            return {
              'driverId': data['driverId'],
              'driverName': data['driverName'],
            };
          }
        }
      }
    } catch (e) {
      print('Error finding collection driver for customer: $e');
    }
    return null;
  }

  Future<String> addOrder(Map<String, dynamic> data,
      {bool autoAssign = true, bool autoCollection = false}) async {
    // Auto-assign driver if not already assigned and is from "الطلبات الجديدة"
    if ((autoAssign || autoCollection) &&
        data['driverId'] == null &&
        data['status'] == 'الطلبات الجديدة') {
      Map<String, String>? driverInfo;

      if (autoCollection) {
        // Find collection driver by customer name
        final customerName = data['senderName'] ?? data['userName'];
        if (customerName != null) {
          driverInfo = await findCollectionDriverForCustomer(customerName);
        }
      } else if (autoAssign) {
        // Find delivery driver by area
        if (data['city'] != null && data['city'].toString().isNotEmpty) {
          driverInfo = await findDriverForOrder(data['city']);
        }
      }

      if (driverInfo != null) {
        data['driverId'] = driverInfo['driverId'];
        data['driverName'] = driverInfo['driverName'];

        if (autoCollection) {
          data['status'] = 'بانتظار التحميل';
          data['orderPossession'] = 'driverFetching';
        } else {
          data['status'] = 'بانتظار موافقة السائق';
        }

        // Update logs
        List logs = data['logs'] ?? [];
        logs.add({
          'date': DateTime.now().toIso8601String(),
          'text':
              'تم تعيين السائق تلقائياً بناءً على جولة الجلب (${autoCollection ? "جلب" : "توصيل"}): ${driverInfo['driverName']}',
          'status': data['status'],
          'userName': 'النظام'
        });
        data['logs'] = logs;
      }
    }

    var ref = _fireStore.collection('orders').doc(data['orderId']);
    await ref.set(data);

    // If auto-assigned, send notification
    if (data['driverId'] != null &&
        (data['status'] == 'بانتظار موافقة السائق' ||
            data['status'] == 'بانتظار التحميل')) {
      _notificationService.createNotification(
        title: autoCollection
            ? 'طلب جلب جديد تلقائي'
            : 'تم تعيين شحنة جديدة لك تلقائياً',
        message: 'تم تعيين شحنة في منطقة ${data['city']}',
        type: 'order',
        recipientId: data['driverId'],
        orderId: data['orderId'],
      );
    }

    return ref.id;
  }

  Stream<QuerySnapshot> getTodayOrdersStream() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    return _fireStore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .snapshots();
  }

  Future<Shipment?> getOrder(String orderId) async {
    var snapshot = await _fireStore.collection('orders').doc(orderId).get();
    if (snapshot.exists) {
      return Shipment.fromMap(snapshot.data()!);
    }
    return null;
  }

  Future<List<Customer>> getCustomers() async {
    var snapshot = await _fireStore.collection('users').get();
    return snapshot.docs.map((e) => Customer.fromJson(e.data())).toList();
  }

  Future<List<Driver>> getDrivers() async {
    // Get all users with jobRole 'سائق'
    var snapshot = await _fireStore
        .collection('drivers')
        .where('jobRole', isEqualTo: 'سائق')
        .get();

    return snapshot.docs.map((e) => Driver.fromJson(e.data())).toList();
  }

  Future<List<Driver>> getEmployees() async {
    // Get all users with jobRole not equal to 'سائق'
    var snapshot = await _fireStore
        .collection('drivers')
        .where('jobRole', isNotEqualTo: 'سائق')
        .get();

    return snapshot.docs.map((e) => Driver.fromJson(e.data())).toList();
  }

  Future<void> assignDriver(String orderId, Driver driver) async {
    await _fireStore.collection('orders').doc(orderId).update({
      'driverId': driver.userid,
      'driverName': driver.username,
      'status': 'في المركبة',
      'orderPossession': 'driverShipping',
      'lastUpdated': DateTime.now().toIso8601String(),
      'logs': FieldValue.arrayUnion([
        {
          'date': DateTime.now().toIso8601String(),
          'text': 'تم تعيين الشحنة للسائق ${driver.username}',
          'status': 'في المركبة',
          'userName': user?.displayName ?? "مجهول"
        }
      ])
    });
    _notificationService.createNotification(
      title: 'تم تعيين الشحنة للسائق ${driver.username}',
      message: 'يمكنك الان تحصيل الشحنة منها',
      type: 'order',
      recipientId: driver.userid!,
      orderId: orderId,
    );
  }

  Future<void> updateOrderStatus(
      String orderId, String status, Driver? driver, String? note,
      {bool? getMoneyFromUserPalance,
      bool? receivedMoneyFromCustomer,
      bool? returnedAfterDelivery,
      Shelf? shelf,
      OrderPossession? orderPossession,
      DateTime? postponementDate}) async {
    if (status == "تم توصيلها" || status == "تم توصيلها بشكل جزئي") {
      var shipmentData =
          await _fireStore.collection('orders').doc(orderId).get();

      _fireStore.collection('drivers').doc(driver?.userid).update(
          {'cashBalance': FieldValue.increment(shipmentData['codAmount'])});
    }

    Map<String, dynamic> data = {
      if (note != null) 'notes': note,
      'status': status,
      'lastUpdated': DateTime.now().toIso8601String(),
      if (status == "تم توصيلها" ||
          status == "تم توصيلها بشكل جزئي" ||
          status == "تم إرجاعها")
        "cashPossession": 'driver',
      if (status == "تم إرجاعها") ...{
        'returnOrderDate': DateTime.now().toIso8601String(),
        'receivedMoneyFromCustomer': receivedMoneyFromCustomer,
        'getMoneyFromUserPalance': getMoneyFromUserPalance,
        'returnedAfterDelivery': returnedAfterDelivery,
      },
      if (shelf != null) ...{
        'shelfId': shelf.id,
        'shelfName': shelf.name,
        "shelf": shelf.toMap()
      },
      'driverId': driver?.userid,
      'driverName': driver?.username,
      'logs': FieldValue.arrayUnion([
        {
          'date': DateTime.now().toIso8601String(),
          'text': 'تم تغيير حالة الشحنة الى $status ${driver?.username ?? ""}',
          'status': status,
          'userName': user?.displayName ?? "مجهول"
        },
        if (note != null)
          {
            'date': DateTime.now().toIso8601String(),
            'text': 'تم تغير ملاحظات الشحنة الى $note',
            'status': null,
            'userName': user?.displayName ?? "مجهول"
          }
      ])
    };
    if (orderPossession != null) {
      data['orderPossession'] = orderPossession.toString().split('.').last;
    }
    if (postponementDate != null) {
      data['postponementDate'] = postponementDate.toIso8601String();
    }
    await _fireStore.collection('orders').doc(orderId).update(data);

    // Update shelf's shipmentIds if shelfId is provided

    if (driver != null) {
      _notificationService.createNotification(
        title: 'تم تغيير حالة الشحنة الى $status ${driver.username ?? ""}',
        message: 'يمكنك الان تحصيل الشحنة منها',
        type: 'order',
        recipientId: driver.userid ?? '',
        orderId: orderId,
      );
    }
  }

  Future<void> updateOrderPrice(
      String orderId, double oldPrice, double price, String? userId) async {
    await _fireStore.collection('orders').doc(orderId).update({
      'deliveryCost': price,
      'logs': FieldValue.arrayUnion([
        {
          'date': DateTime.now().toIso8601String(),
          'text': 'تم تعديل سعر الشحنة من $oldPrice  إلى $price ',
          'status': null,
          'userName': user?.displayName ?? "مجهول"
        }
      ])
    });
    _notificationService.createNotification(
      title: 'تم تعديل سعر الشحنة من $oldPrice إلى $price ',
      message: 'يمكنك الان تحصيل الشحنة منها',
      type: 'order',
      recipientId: userId!,
      orderId: orderId,
    );
  }

  Future<void> addArea(String data) async {
    var ref = _fireStore.collection('configs').doc('areas');

    ref.update({
      'supportedCities': FieldValue.arrayUnion([data])
    });
  }

  Future<void> removeArea(String data) async {
    var ref = _fireStore.collection('configs').doc('areas');

    ref.update({
      'supportedCities': FieldValue.arrayRemove([data])
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> areasStream() {
    return _fireStore.collection('configs').doc('areas').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> priceCalculatorStream(
      bool isDriver) {
    return _fireStore
        .collection(isDriver ? 'driverPriceCalculator' : 'priceCalculator')
        .snapshots();
  }

  updatePriceCalculator(String id, ShippingRoute route, bool isDriver) {
    return _fireStore
        .collection(isDriver ? 'driverPriceCalculator' : 'priceCalculator')
        .doc(id)
        .update({
      'userId': id,
      'routes': FieldValue.arrayUnion([route.toJson()])
    });
  }

  Future<void> updatePriceCalculatorBatch(
      String id, List<ShippingRoute> routes, bool isDriver) {
    return _fireStore
        .collection(isDriver ? 'driverPriceCalculator' : 'priceCalculator')
        .doc(id)
        .set({
      'userId': id,
      'routes': routes.map((r) => r.toJson()).toList(),
    });
  }

  addPriceCalculator(String id, ShippingRoute route, bool isDriver) {
    return _fireStore
        .collection(isDriver ? 'driverPriceCalculator' : 'priceCalculator')
        .doc(id)
        .set({
      'userId': id,
      'routes': FieldValue.arrayUnion([route.toJson()])
    });
  }

  void deleteShippingRoute(
      String userId, ShippingRoute shippingRoute, bool isDriver) {
    _fireStore
        .collection(isDriver ? 'driverPriceCalculator' : 'priceCalculator')
        .doc(userId)
        .update({
      'routes': FieldValue.arrayRemove([shippingRoute.toJson()])
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      driversWithWithCashBalanceStream() {
    return FirebaseFirestore.instance
        .collection('drivers')
        .where('cashBalance', isGreaterThan: 0)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      usersWithWithCashBalanceStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('cashBalance', isGreaterThan: 0)
        .snapshots();
  }

  Stream<List<Shipment>> getCustomersUserAccount(int selectedIndex) {
    String paymentStatus = "";
    switch (selectedIndex) {
      case 6:
        paymentStatus = "collected";
        break;
      case 7:
        paymentStatus = "sorted";
        break;
      case 8:
        paymentStatus = "exported";
        break;
    }
    return _fireStore
        .collection('orders')
        .where('status',
            whereIn: ["تم توصيلها", "تم توصيلها بشكل جزئي", "تم إرجاعها"])
        .where('cashPossession', isEqualTo: "branch")
        .where('paymentStatus', isEqualTo: paymentStatus)
        .snapshots()
        .map((snapshot) {
          List<Shipment> shipments =
              snapshot.docs.map((e) => Shipment.fromMap(e.data())).toList();

          return shipments;
        });
  }

  static Future<void> updatePaymentStatus(
      UserAccount userAccount, String paymentStatus) async {
    for (var shipment in userAccount.shipments) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(shipment.orderId)
          .update({'paymentStatus': paymentStatus});
    }
  }

  Stream<List<DriverDeliveryData>> getDriverDeliveryData(
      {String? selectedCustomerId,
      String? selectedDriverId,
      DateTime? startDate,
      DateTime? endDate,
      String? shipmentType,
      bool? isReceipt,
      required List<Driver> drivers}) {
    print(selectedDriverId);
    List<DriverDeliveryData> driverDeliveryData = [];
    Query query = _fireStore.collection('orders').where('status',
        whereIn: ["تم توصيلها", "تم توصيلها بشكل جزئي", "تم إرجاعها"]);

    if (selectedCustomerId != null) {
      query = query.where('userId', isEqualTo: selectedCustomerId);
    }
    if (selectedDriverId != null) {
      query = query.where('driverId', isEqualTo: selectedDriverId);
    }

    // Apply date range filter if provided
    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }
    if (isReceipt != null) {
      query = query.where('cashPossession', isEqualTo: 'driver');
    }

    // Apply shipment type filter
    if (shipmentType != null) {
      switch (shipmentType) {
        case 'الشحنات المسلمه':
          query = query.where('cashPossession', isEqualTo: 'branch');
          break;
        case 'الشحنات الغير المسلمه':
          query = query.where('cashPossession', isEqualTo: 'driver');
          break;
        // For 'كل الشحنات', we don't add any cashPossession filter
      }
    }

    return query.snapshots().map((snapshot) {
      print(snapshot.docs);
      List<Shipment> shipments = snapshot.docs
          .map((e) => Shipment.fromMap(e.data() as Map<String, dynamic>))
          .toList();
      List<List<Shipment>> groups = [];
      for (var shipment in shipments) {
        if (!groups
            .any((element) => element.first.driverId == shipment.driverId)) {
          groups.add([shipment]);
        } else {
          groups
              .firstWhere(
                  (element) => element.first.driverId == shipment.driverId)
              .add(shipment);
        }
      }

      for (var group in groups) {
        print(group.first.driverId);
        // String driverName = drivers.firstWhere((element) => element.userid == group.first.driverId).username ?? "";

        driverDeliveryData.add(DriverDeliveryData.fromShipments(
            group.first.driverName ?? '', group));
      }
      return driverDeliveryData;
    });
  }

  Future receiveOrdersFromDriver(DriverDeliveryData driverData) async {
    if (driverData.shipments.first.driverId != null) {
      _fireStore
          .collection('drivers')
          .doc(driverData.shipments.first.driverId)
          .update({
        //2
        'cashBalance': FieldValue.increment(-driverData.totalCollections)
      });
    }
    final batch = _fireStore.batch();
    final now = DateTime.now().toIso8601String();

    for (var shipment in driverData.shipments) {
      // Update order document
      batch.update(_fireStore.collection('orders').doc(shipment.orderId), {
        'cashPossession': 'branch',
        // "driverId":null,
        'paymentStatus': 'collected',
        'lastUpdated': now,
        'logs': FieldValue.arrayUnion([
          {
            'date': now,
            'text': 'تم تحصيل الشحنة من السائق ${driverData.driverName}',
            'status': null,
            'userName': user!.displayName
          }
        ])
      });

      // Update user document if userId exists
      if (shipment.userId != null) {
        batch.update(_fireStore.collection('users').doc(shipment.userId), {
          'cashBalance':
              FieldValue.increment(shipment.codAmount - shipment.deliveryCost)
        });
      }
    }

    await batch.commit();

    _notificationService.createNotification(
      title: 'تم تحصيل الشحنة من السائق ${driverData.driverName}',
      message:
          'يمكنك الان تحصيل الشحنة منها قيكتها ${driverData.totalCollections}',
      type: 'order',
      recipientId: driverData.shipments.first.driverId ?? '',
      orderId: null,
    );
  }

  Future<String> saveDriverReceiptInvoice(DriverDeliveryData driverData) async {
    var ref = _fireStore.collection('receiptedInvoices').doc();
    driverData.id = ref.id;
    await ref.set(driverData.toMap());
    return ref.id;
  }

  Future<String> payOrdersToCustomer(UserAccount userAccount) async {
    List<dynamic> items = [];
    if (userAccount.haveInventoryItems == true) {
      var doc = await inventory.doc(userAccount.id).get();

      if (!doc.exists) return "";

      var data = doc.data() as Map<String, dynamic>;
      items = List.from(data['items'] ?? []);
    }
    _fireStore.collection('users').doc(userAccount.id).update({
      'cashBalance': FieldValue.increment(
          -(userAccount.totalAmount - userAccount.servicesFees))
    });

    for (var shipment in userAccount.shipments) {
      await _fireStore.collection('orders').doc(shipment.orderId).update({
        'cashPossession': 'customer',
        'paymentStatus': 'paid',
        'isSentToFaotara': false,
        'lastUpdated': DateTime.now().toIso8601String(),
        'logs': FieldValue.arrayUnion([
          {
            'date': DateTime.now().toIso8601String(),
            'text': 'تم سداد الشحنة للعميل ${userAccount.client}',
            'status': null,
            'userName': user!.displayName
          }
        ])
      });
      if (shipment.selectedItems != null) {
        for (var item in shipment.selectedItems!.entries) {
          updateInventoryItemQuantity(
              userAccount.id, item.key, item.value, items);
        }
      }
    }
    var ref = _fireStore.collection('exportedInvoices').doc();

    ref.set(userAccount.toMap());

    _notificationService.createNotification(
      title: 'تم سداد الشحنة للعميل ${userAccount.client}',
      message: 'يمكنك الان تسداد الشحنة لها بقيمه ${userAccount.totalAmount}',
      type: 'order',
      recipientId: userAccount.id,
      orderId: null,
    );
    return ref.id;
  }

  static Stream<List<UserAccount>> exportedInvoicesStream() {
    return FirebaseFirestore.instance
        .collection('exportedInvoices')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserAccount.fromMap(doc.data()))
            .toList());
  }

  static Stream<List<DriverDeliveryData>> receiptedInvoicesStream() {
    return FirebaseFirestore.instance
        .collection('receiptedInvoices')
        .orderBy('paymentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverDeliveryData.fromMap(doc.data(), docId: doc.id))
            .toList());
  }

  Future<void> updateOrder(Map<String, dynamic> data) async {
    await orders.doc(data['orderId']).update(data);
  }

  // Expense Methods
  Future<String> addExpense(Map<String, dynamic> data) async {
    var docRef = await expenses.add({
      ...data,
      'creationDate': FieldValue.serverTimestamp(),
      'modificationDate': FieldValue.serverTimestamp(),
      'userName': user?.displayName ?? 'Unknown',
    });
    return docRef.id;
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    await expenses.doc(id).update({
      ...data,
      'modificationDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String id) async {
    await expenses.doc(id).delete();
  }

  Stream<QuerySnapshot> getExpensesStream() {
    return expenses.orderBy('creationDate', descending: true).snapshots();
  }

  Future<void> addExpenseType(String data) async {
    var ref = _fireStore.collection('configs').doc('areas');

    ref.update({
      'expenseTypes': FieldValue.arrayUnion([data])
    });
  }

  Future<void> addAccountName(String name) async {
    try {
      var ref = _fireStore.collection('configs').doc('Accounts');

      // تحقق من وجود الوثيقة أولاً
      var doc = await ref.get();
      if (!doc.exists) {
        // إذا لم تكن الوثيقة موجودة، قم بإنشائها
        await ref.set({
          'BankAccounts': [name]
        });
      } else {
        // إذا كانت الوثيقة موجودة، قم بتحديثها
        await ref.update({
          'BankAccounts': FieldValue.arrayUnion([name])
        });
      }

      print("Account added successfully: $name");
    } catch (e) {
      print("Error adding account: $e");
      throw e;
    }
  }

  Future<void> removeExpenseType(String data) async {
    var ref = _fireStore.collection('configs').doc('areas');

    ref.update({
      'expenseTypes': FieldValue.arrayRemove([data])
    });
  }

  Future<void> deleteExpenseType(String id) async {
    await expenseTypes.doc(id).delete();
  }

  Stream<QuerySnapshot> getExpenseTypesStream() {
    return expenseTypes.orderBy('name').snapshots();
  }

  Future<void> addFile(Map<String, dynamic> data) async {
    await configs.doc("documents").update({
      "files": FieldValue.arrayUnion([data])
    });
  }

  Future<void> deleteFile(Map<String, dynamic> data) async {
    await configs.doc("documents").update({
      "files": FieldValue.arrayRemove([data])
    });
  }

  Stream<List<DocumentFile>> getFilesStream() {
    return configs.doc("documents").snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return [];
      }
      var data = snapshot.data() as Map<String, dynamic>;
      if (!data.containsKey("files")) {
        return [];
      }
      List<dynamic> files = data["files"] as List<dynamic>;
      return files
          .map((e) => DocumentFile.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> deleteCustomer(String email) async {
    try {
      // Normalize email - ensure it has .com extension
      String normalizedEmail = email.endsWith('.com') ? email : email + '.com';

      print('Searching for customer with email: $normalizedEmail');

      // Get the user document reference
      QuerySnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      print(
          'Found ${userDoc.docs.length} documents for email: $normalizedEmail');

      if (userDoc.docs.isNotEmpty) {
        String userId = userDoc.docs.first.id;
        print('Deleting customer with ID: $userId');

        // Delete any associated orders first
        QuerySnapshot ordersToDelete = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .get();

        print('Found ${ordersToDelete.docs.length} orders to delete');

        // Use a batch to delete all related documents
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Add order deletions to batch
        for (var doc in ordersToDelete.docs) {
          batch.delete(doc.reference);
        }

        // Add user document deletion to batch
        batch.delete(userDoc.docs.first.reference);

        // Execute the batch
        await batch.commit();

        print('Customer and related data deleted successfully');
      } else {
        // Try to find by userid if email search fails
        print('No customer found with email: $normalizedEmail');
        throw Exception('User not found with email: $normalizedEmail');
      }
    } catch (e) {
      print('Error deleting customer: $e');
      throw e;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    await users.doc(customer.userid).update(customer.toJson());
  }

  Future<void> deleteCustomerById(String userId) async {
    try {
      print('Deleting customer with ID: $userId');

      // Check if customer exists
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (customerDoc.exists) {
        // Delete any associated orders first
        QuerySnapshot ordersToDelete = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .get();

        print('Found ${ordersToDelete.docs.length} orders to delete');

        // Use a batch to delete all related documents
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Add order deletions to batch
        for (var doc in ordersToDelete.docs) {
          batch.delete(doc.reference);
        }

        // Add customer document deletion to batch
        batch.delete(customerDoc.reference);

        // Execute the batch
        await batch.commit();

        print('Customer and related data deleted successfully');
      } else {
        print('No customer found with ID: $userId');
        throw Exception('Customer not found with ID: $userId');
      }
    } catch (e) {
      print('Error deleting customer by ID: $e');
      throw e;
    }
  }

  Future<void> deleteDriver(String email) async {
    try {
      // Normalize email - ensure it has .com extension
      String normalizedEmail = email.endsWith('.com') ? email : email + '.com';

      print('Searching for driver with email: $normalizedEmail');

      // Get the driver document reference
      QuerySnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      print(
          'Found ${driverDoc.docs.length} documents for email: $normalizedEmail');

      if (driverDoc.docs.isNotEmpty) {
        String driverId = driverDoc.docs.first.id;
        print('Deleting driver with ID: $driverId');

        // Delete any associated orders first
        QuerySnapshot ordersToDelete = await FirebaseFirestore.instance
            .collection('orders')
            .where('driverId', isEqualTo: driverId)
            .get();

        print('Found ${ordersToDelete.docs.length} orders to delete');

        // Use a batch to delete all related documents
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Add order deletions to batch
        for (var doc in ordersToDelete.docs) {
          batch.delete(doc.reference);
        }

        // Add driver document deletion to batch
        batch.delete(driverDoc.docs.first.reference);

        // Execute the batch
        await batch.commit();

        print('Driver and related data deleted successfully');
      } else {
        print('No driver found with email: $normalizedEmail');
        throw Exception('Driver not found with email: $normalizedEmail');
      }
    } catch (e) {
      print('Error deleting driver: $e');
      throw e;
    }
  }

  Future<void> addCity(City city) async {
    var ref = _fireStore.collection('configs').doc('cities');

    await ref.set({city.name: city.places}, SetOptions(merge: true));
  }

  Future<void> updateCity(String oldCityName, City city) async {
    var ref = _fireStore.collection('configs').doc('cities');

    var batch = _fireStore.batch();

    // Remove old city
    batch.update(ref, {oldCityName: FieldValue.delete()});

    // Add new city data
    batch.set(ref, {city.name: city.places}, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> deleteCity(String cityName) async {
    var ref = _fireStore.collection('configs').doc('cities');

    await ref.update({cityName: FieldValue.delete()});
  }

  Stream<Map<String, List<String>>> citiesStream() {
    return _fireStore
        .collection('configs')
        .doc('cities')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data() ?? {};
      final Map<String, List<String>> cities = {};

      data.forEach((key, value) {
        if (value is List) {
          cities[key] = List<String>.from(value);
        }
      });

      return cities;
    });
  }

  Stream<List<String>> getBankAccountsStream() {
    print("Getting bank accounts stream");
    return _fireStore
        .collection('configs')
        .doc('Accounts')
        .snapshots()
        .map((snapshot) {
      print("Raw Firestore data: ${snapshot.data()}");
      if (!snapshot.exists || snapshot.data() == null) {
        print("No data found in Firestore");
        return [];
      }
      final data = snapshot.data()!;
      if (!data.containsKey('BankAccounts')) {
        print("No BankAccounts field found in document");
        return [];
      }
      final accounts = List<String>.from(data['BankAccounts'] ?? []);
      print("Parsed bank accounts: $accounts");
      return accounts;
    });
  }

  Future<void> addBankAccount(String name) async {
    var ref = _fireStore.collection('configs').doc('Accounts');

    await ref.set({
      'BankAccounts': FieldValue.arrayUnion([name])
    }, SetOptions(merge: true));
  }

  Future<void> addTransfer(Map<String, dynamic> data) async {
    await _fireStore.collection('transfers').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Transfer>> getTransfersStream() {
    return _fireStore
        .collection('transfers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Transfer.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  void removeDriver(String orderId) {
    _fireStore.collection('orders').doc(orderId).update({
      'driverId': null,
      'driverName': null,
    });
  }

  getCustomersStream() {
    return _fireStore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Customer.fromJson(doc.data())).toList();
    });
  }

  // Inventory Management Methods
  Future<Inventory?> getCustomerInventory(String userId) async {
    try {
      var snapshot = await inventory.doc(userId).get();
      if (snapshot.exists && snapshot.data() != null) {
        return Inventory.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        // Get customer name from users collection
        var userDoc = await users.doc(userId).get();
        String userName = 'Unknown Customer';

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['username'] ?? 'Unknown Customer';
        }

        // Return an empty inventory
        return Inventory(
          userId: userId,
          userName: userName,
          items: [],
        );
      }
    } catch (e) {
      print('Error getting customer inventory: $e');
      return null;
    }
  }

  Stream<Inventory> getCustomerInventoryStream(String userId) {
    return inventory.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Inventory.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        // Return an empty inventory if none exists
        return Inventory(
          userId: userId,
          userName: 'Unknown Customer',
          items: [],
        );
      }
    });
  }

  Future<void> addInventoryItem(
      String userId, String userName, InventoryItem item) async {
    var docRef = inventory.doc(userId);
    var doc = await docRef.get();

    if (doc.exists) {
      // Update existing inventory
      await docRef.update({
        'items': FieldValue.arrayUnion([item.toMap()]),
      });
    } else {
      // Create new inventory
      await docRef.set({
        'userId': userId,
        'userName': userName,
        'items': [item.toMap()],
      });
    }
  }

  Future<void> updateInventoryItem(
      String userId, InventoryItem updatedItem) async {
    var docRef = inventory.doc(userId);
    var doc = await docRef.get();

    if (!doc.exists) return;

    var data = doc.data() as Map<String, dynamic>;
    List<dynamic> items = List.from(data['items'] ?? []);

    // Find the index of the item to update
    int index = items.indexWhere((item) => item['id'] == updatedItem.id);

    if (index >= 0) {
      // Update the item
      items[index] = updatedItem.toMap();

      // Update the document
      await docRef.update({
        'items': items,
      });
    }
  }

  Future<void> deleteInventoryItem(String userId, String itemId) async {
    var docRef = inventory.doc(userId);
    var doc = await docRef.get();

    if (!doc.exists) return;

    var data = doc.data() as Map<String, dynamic>;
    List<dynamic> items = List.from(data['items'] ?? []);

    // Remove the item
    items.removeWhere((item) => item['id'] == itemId);

    // Update the document
    await docRef.update({
      'items': items,
    });
  }

  Future<void> updateInventoryItemQuantity(
      String userId, String itemId, int quantity, List<dynamic> items) async {
    var docRef = inventory.doc(userId);

    // Find the item to update
    int index = items.indexWhere((item) => item['id'] == itemId);

    if (index >= 0) {
      Map<String, dynamic> item = Map<String, dynamic>.from(items[index]);

      // Update quantity and updatedAt timestamp
      item['quantity'] = item['quantity'] - quantity;
      item['updatedAt'] = DateTime.now().toIso8601String();

      items[index] = item;

      // Update the document
      docRef.update({
        'items': items,
      });
    }
  }

  Future<List<Shipment>> getCustomerShipmentsWithItems(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      var query = _fireStore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('isShipmentWithItems', isEqualTo: true)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate);

      var snapshot = await query.get();

      return snapshot.docs.map((doc) => Shipment.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting customer shipments with items: $e');
      return [];
    }
  }

  void deleteOrders(Set<String> selectedOrderIds) {
    for (String id in selectedOrderIds) {
      FirebaseFirestore.instance.collection('orders').doc(id).delete();
    }
    _notificationService.createNotification(
      title: 'تم حذف الطرد ${selectedOrderIds.length} طلبات',
      message: "تم حذف الطلبات ${selectedOrderIds.map((e) => e).join(", ")}",
      type: 'order_deleted',
      recipientId: "admin",
      orderId: selectedOrderIds.first,
    );
  }

  Future<void> saveAiUsage(Map<String, dynamic> usage) async {
    var ref = _fireStore.collection('configs').doc('aiUsage');

    await ref.set({
      'usages': FieldValue.arrayUnion([usage])
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getAiUsageStream() {
    return _fireStore
        .collection('configs')
        .doc('aiUsage')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return [];
      }
      final data = snapshot.data()!;
      if (!data.containsKey('usages')) {
        return [];
      }
      return List<Map<String, dynamic>>.from(data['usages'] ?? []);
    });
  }

  Future<void> deleteDriverById(String driverId) async {
    try {
      print('Deleting driver with ID: $driverId');

      // Check if driver exists
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      if (driverDoc.exists) {
        // Delete any associated orders first
        QuerySnapshot ordersToDelete = await FirebaseFirestore.instance
            .collection('orders')
            .where('driverId', isEqualTo: driverId)
            .get();

        print('Found ${ordersToDelete.docs.length} orders to delete');

        // Use a batch to delete all related documents
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Add order deletions to batch
        for (var doc in ordersToDelete.docs) {
          batch.delete(doc.reference);
        }

        // Add driver document deletion to batch
        batch.delete(driverDoc.reference);

        // Execute the batch
        await batch.commit();

        print('Driver and related data deleted successfully');
      } else {
        print('No driver found with ID: $driverId');
        throw Exception('Driver not found with ID: $driverId');
      }
    } catch (e) {
      print('Error deleting driver by ID: $e');
      throw e;
    }
  }

  // Shelf Management Methods
  CollectionReference get shelves => _fireStore.collection('shelves');

  Stream<List<Shelf>> getShelvesStream() {
    return shelves.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Shelf.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    });
  }

  Future<void> addShelf(Map<String, dynamic> shelfData) async {
    await shelves.add({
      ...shelfData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateShelf(
      String shelfId, Map<String, dynamic> shelfData) async {
    await shelves.doc(shelfId).update({
      ...shelfData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteShelf(String shelfId) async {
    await shelves.doc(shelfId).delete();
  }

  Future<List<Shipment>> getOrdersByShelfId(String shelfId) async {
    final snapshot = await _fireStore
        .collection('orders')
        .where('shelfId', isEqualTo: shelfId)
        .where('status', isEqualTo: 'على الرفوف') // ✅ الشرط الإضافي
        .get();

    return snapshot.docs
        .map((doc) => Shipment.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<String> createBundledShipment(Set<String> selectedOrderIds) async {
    // Generate bundle ID
    final bundelId =
        DateTime.now().millisecondsSinceEpoch.toString().substring(2);

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (final orderId in selectedOrderIds) {
      final docRef = firestore.collection('orders').doc(orderId);
      batch.update(docRef, {'bundleId': bundelId}); // note spelling fix
    }

    await batch.commit();
    return bundelId;
  }

  Stream<List<SupplyOrder>> getSupplyOrdersStream() {
    return _fireStore.collection('supply_orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupplyOrder.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<SupplyOrder>> getSupplyOrdersForUser(String userId) async {
    final snapshot = await _fireStore
        .collection('supply_orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    return snapshot.docs.map((doc) {
      return SupplyOrder.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<void> updateSupplyOrder(SupplyOrder order) async {
    await _fireStore
        .collection('supply_orders')
        .doc(order.id)
        .update(order.toMap());
  }

  Future<void> reciveReturnOrder(String orderId) async {
    final docRef = _fireStore.collection('orders').doc(orderId);
    docRef.update(
        {'orderPossession': OrderPossession.branch.toString().split('.').last});
  }

  Future<void> assignCollectionDriver(String orderId, Driver driver) async {
    final now = DateTime.now().toIso8601String();
    await _fireStore.collection('orders').doc(orderId).update({
      'driverId': driver.userid,
      'driverName': driver.username,
      'status': 'بانتظار التحميل',
      'orderPossession': 'driverFetching',
      'lastUpdated': now,
      'logs': FieldValue.arrayUnion([
        {
          'date': now,
          'text': 'تم تعيين السائق ${driver.username} لجلب الشحنة من الزبون',
          'status': 'بانتظار التحميل',
          'userName': user?.displayName ?? "مجهول"
        }
      ])
    });

    _notificationService.createNotification(
      title: 'طلب جلب جديد',
      message: 'تم تعيينك لجلب شحنة من الزبون',
      type: 'order',
      recipientId: driver.userid!,
      orderId: orderId,
    );
  }

  Stream<List<ChatMessage>> getChatMessagesStream(String orderId) {
    return _fireStore
        .collection('orders')
        .doc(orderId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  Future<void> sendChatMessage(String orderId, ChatMessage message) async {
    // 1. Add message to chat collection
    await _fireStore
        .collection('orders')
        .doc(orderId)
        .collection('chat')
        .add(message.toMap());

    try {
      // 2. Fetch order to find driverId and userId
      final orderDoc = await _fireStore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final data = orderDoc.data();
        final driverId = data?['driverId'];
        final userId = data?['userId'];

        // 3. Notify Driver (Captain)
        if (driverId != null && driverId.toString().isNotEmpty) {
          await _notificationService.createNotification(
            title: 'رسالة من المتابعة بخصوص طلب #$orderId',
            message: message.text,
            type: 'chat',
            recipientId: driverId.toString(),
            orderId: orderId,
            forAdmin: false,
          );
        }

        // 4. Notify User (Customer)
        if (userId != null && userId.toString().isNotEmpty) {
          await _notificationService.createNotification(
            title: 'رسالة من المتابعة بخصوص طلبك #$orderId',
            message: message.text,
            type: 'chat',
            recipientId: userId.toString(),
            orderId: orderId,
            forAdmin: false,
          );
        }
      }
    } catch (e) {
      print('FCM Debug Error in dual notification: $e');
    }
  }

  updateIsCompanyDeliveryFeePaid(String orderId, bool bool) {
    _fireStore.collection('orders').doc(orderId).update({
      'isCompanyDeliveryFeePaid': bool,
      if (bool) 'isDeliveryFeeOnRecipient': false,
      "status": "الطلبات الجديدة",
      "notes":""
    });
  }
}
