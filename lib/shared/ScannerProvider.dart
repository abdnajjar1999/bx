import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Shipment.dart';
import '../models/Driver.dart';

class ScannerProvider extends ChangeNotifier {
  List<Shipment> _scannedShipments = [];
  Set<String> _scannedIds = {};
  Set<String> _selectedIds = {}; // Track selected order IDs for batch actions
  String? _lastScannedBarcode;
  bool _isLoading = false;

  List<Shipment> get scannedShipments => _scannedShipments;
  Set<String> get scannedIds => _scannedIds;
  Set<String> get selectedIds => _selectedIds;
  String? get lastScannedBarcode => _lastScannedBarcode;
  bool get isLoading => _isLoading;

  bool isSelected(String orderId) => _selectedIds.contains(orderId);

  void toggleSelection(String orderId) {
    if (_selectedIds.contains(orderId)) {
      _selectedIds.remove(orderId);
    } else {
      _selectedIds.add(orderId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds = _scannedShipments.map((s) => s.orderId).toSet();
    notifyListeners();
  }

  void deselectAll() {
    _selectedIds.clear();
    notifyListeners();
  }

  void clearLastScanned() {
    _lastScannedBarcode = null;
    notifyListeners();
  }

  Future<void> addShipment(String barcode) async {
    // If we've already scanned this exact barcode string, skip
    if (_scannedIds.contains(barcode)) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Try searching by orderId
      var querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderId', isEqualTo: barcode)
          .limit(1)
          .get();

      // 2. If not found, try searching by trackingNumber
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('trackingNumber', isEqualTo: barcode)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final shipment = Shipment.fromMap(data);

        // Double check we haven't already added this shipment via its other identifier
        if (!_scannedIds.contains(shipment.orderId) &&
            !_scannedIds.contains(shipment.trackingNumber)) {
          _scannedShipments.add(shipment);
          _scannedIds.add(shipment.orderId);
          // Auto-select newly added shipment
          _selectedIds.add(shipment.orderId);
          
          if (shipment.trackingNumber.isNotEmpty) {
            _scannedIds.add(shipment.trackingNumber);
          }
          // Also track the original barcode used to find it
          _scannedIds.add(barcode);
        }
      }
    } catch (e) {
      print('Error adding shipment to scanner: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeShipment(String orderId) {
    _scannedShipments.removeWhere((s) => s.orderId == orderId);
    _scannedIds.remove(orderId);
    _selectedIds.remove(orderId);
    notifyListeners();
  }

  void clearAll() {
    _scannedShipments.clear();
    _scannedIds.clear();
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> bulkUpdateStatus(String status, String performedBy,
      {String? note}) async {
    if (_scannedShipments.isEmpty || _selectedIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();
      
      // Filter list to only act on selected items
      final selectedShipments = _scannedShipments.where((s) => _selectedIds.contains(s.orderId)).toList();

      for (var shipment in selectedShipments) {
        final docRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(shipment.orderId);

        // Prepare log entry
        final logEntry = {
          'text': 'تحديث الحالة إلى $status (عبر الماسح)' + (note != null ? ': $note' : ''),
        'date': now.toIso8601String(),
        'status': status,
        'userName': performedBy,
      };

        Map<String, dynamic> updates = {
          'status': status,
          'logs': FieldValue.arrayUnion([logEntry]),
        };

        // Special handling for "In Branch" status
        if (status == 'في الفرع') {
          updates['orderPossession'] = 'branch';
          updates['driverId'] = FieldValue.delete();
          updates['driverName'] = FieldValue.delete();
        }

        batch.update(docRef, updates);
      }

      await batch.commit();

      // Update local state: remove processed items or update them
      // Common pattern for scanner is to remove them after successful batch operation
      for (var shipment in selectedShipments) {
        _scannedIds.remove(shipment.orderId);
        _scannedIds.remove(shipment.trackingNumber);
        _selectedIds.remove(shipment.orderId);
        _scannedShipments.removeWhere((s) => s.orderId == shipment.orderId);
      }
    } catch (e) {
      print('Error in bulk status update: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> bulkAssignDriver(Driver driver, String performedBy) async {
    if (_scannedShipments.isEmpty || _selectedIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      final selectedShipments = _scannedShipments.where((s) => _selectedIds.contains(s.orderId)).toList();

      for (var shipment in selectedShipments) {
        final docRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(shipment.orderId);

        final logEntry = {
          'text': 'تم تعيين السائق ${driver.username} (عبر الماسح)',
          'date': now.toIso8601String(),
          'userName': performedBy,
        };

        batch.update(docRef, {
          'driverId': driver.userid,
          'driverName': driver.username,
          'status': 'في المركبة',
          'orderPossession': 'driverShipping',
          'logs': FieldValue.arrayUnion([logEntry]),
        });
      }

      await batch.commit();

      // Update local state
      for (var shipment in selectedShipments) {
        _scannedIds.remove(shipment.orderId);
        _scannedIds.remove(shipment.trackingNumber);
        _selectedIds.remove(shipment.orderId);
        _scannedShipments.removeWhere((s) => s.orderId == shipment.orderId);
      }
    } catch (e) {
      print('Error in bulk driver assignment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> bulkReceiveReturns(String performedBy) async {
    if (_scannedShipments.isEmpty || _selectedIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      final selectedShipments = _scannedShipments
          .where((s) => _selectedIds.contains(s.orderId))
          .toList();

      for (var shipment in selectedShipments) {
        final docRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(shipment.orderId);

        final logEntry = {
          'text': 'تم استلام المرتجع في الفرع (عبر الماسح)',
          'date': now.toIso8601String(),
          'userName': performedBy,
        };

        batch.update(docRef, {
          'orderPossession': 'branch',
          'logs': FieldValue.arrayUnion([logEntry]),
        });
      }

      await batch.commit();

      // Update local state
      for (var shipment in selectedShipments) {
        _scannedIds.remove(shipment.orderId);
        _scannedIds.remove(shipment.trackingNumber);
        _selectedIds.remove(shipment.orderId);
        _scannedShipments.removeWhere((s) => s.orderId == shipment.orderId);
      }
    } catch (e) {
      print('Error in bulk receive returns: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
