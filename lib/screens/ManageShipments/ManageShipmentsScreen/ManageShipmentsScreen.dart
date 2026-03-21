import 'dart:convert';

import 'package:good_line_delivery/models/customer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/Shelf.dart';
import '../../../utils/utilities.dart';

import '../../../widgets/BarcodeScannerDialog.dart';

import '../widget/SearchableDropdown.dart';
import '../../../utils/file_handler.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dashboard/header/showSideDrawerDialog.dart';

import '../../../durub/durub.dart';
import '../widget/CounterTextFormField.dart';
import '../widget/CustomButton.dart';
import '../widget/CustomContainer.dart';
import '../widget/CustomDropdown.dart';
import '../widget/CustomScrollbar.dart';
import '../widget/CustomSwitchBar.dart';
import '../widget/CustomTabBar.dart';
import '../widget/CustomTextField.dart';
import '../widget/Customtext.dart';
import '../widget/DropdownButton.dart';
import '../../../shared/PrintHelper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/Shipment.dart';
import '../../../main.dart';
import '../../../models/Driver.dart';
import '../../../shared/ExcelImportHandler.dart';
import '../../../shared/appProvider.dart';
import '../../../shared/constants.dart';
import '../DeliveryReceiveDialog.dart';
import '../DriverAssignmentPopup.dart';
import '../ShipmentDetails.dart';
import '../TourSelectionDialog.dart';
import '../CustomerCollectionDialog.dart';
import 'dialogs.dart';
import 'showChangeStatusBottomSheet.dart';

class ManageShipmentsScreen extends StatefulWidget {
  final int selectedIndex;
  const ManageShipmentsScreen({super.key, required this.selectedIndex});

  @override
  State<ManageShipmentsScreen> createState() => _ManageShipmentsScreenState();
}

class _ManageShipmentsScreenState extends State<ManageShipmentsScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _headerHorizontalScrollController = ScrollController();
  final ScrollController _verticalMainScrollController = ScrollController();

  int _limit = 40;
  int _perPage = 50;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isSwitched = true; // Will be set based on screen size in initState
  bool showDelivered = false;
  bool _isRangeSelectionMode = false;
  String? _lastSelectedOrderId;

  bool showJump = false;
  bool _showLoadMoreButton = false;
  Shipment? selectedOrder;
  Set<String> selectedOrderIds = {};
  Set<Shipment> selectedOrders = {};

  List<Shipment> orders = [];
  List<Shipment> filteredOrders = [];
  Timer? _debounce;

  List<String> barcodeScannerOrderIds = [];

  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  Future<List<Shipment>?> _showShipmentSelectionDialog(
      List<Shipment> shipments, Set<String> existingTrackingNumbers) async {
    return await showDialog<List<Shipment>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Create a local set of selected shipment ORDER IDs (or unique identifiers)
        // Initially select all EXCEPT duplicates
        Set<String> selectedIds = shipments
            .where((s) => !existingTrackingNumbers.contains(s.trackingNumber))
            .map((s) => s.orderId)
            .toSet();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool allSelected = selectedIds.length == shipments.length;

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تأكيد استيراد الشحنات'),
                  Text(
                    '${selectedIds.length} / ${shipments.length}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 500,
                child: Column(
                  children: [
                    // Header with Select All
                    CheckboxListTile(
                      title: const Text('تحديد الكل',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      value: allSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedIds = shipments
                                .where((s) => !existingTrackingNumbers
                                    .contains(s.trackingNumber))
                                .map((s) => s.orderId)
                                .toSet();
                          } else {
                            selectedIds.clear();
                          }
                        });
                      },
                    ),
                    const Divider(),
                    // List of shipments
                    Expanded(
                      child: ListView.separated(
                        itemCount: shipments.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final shipment = shipments[index];
                          final isSelected =
                              selectedIds.contains(shipment.orderId);
                          final isDuplicate = existingTrackingNumbers
                              .contains(shipment.trackingNumber);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedIds.add(shipment.orderId);
                                } else {
                                  selectedIds.remove(shipment.orderId);
                                }
                              });
                            },
                            title: Row(
                              children: [
                                Text(
                                    '${shipment.recipientName} - ${shipment.city}'),
                                if (isDuplicate) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red),
                                    ),
                                    child: const Text(
                                      'مكرر',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الهاتف: ${shipment.phoneNumber}'),
                                if (shipment.addressDescription.isNotEmpty)
                                  Text(
                                      'العنوان: ${shipment.addressDescription}'),
                                Text(
                                    'المبلغ: ${shipment.codAmount} | التوصيل: ${shipment.deliveryCost}'),
                                Text('Tracking: ${shipment.trackingNumber}',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[600])),
                              ],
                            ),
                            secondary: CircleAvatar(
                              child: Text((index + 1).toString()),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null), // Cancel
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: selectedIds.isNotEmpty
                      ? () {
                          // Filter shipments based on selection
                          List<Shipment> finalSelection = shipments
                              .where((s) => selectedIds.contains(s.orderId))
                              .toList();
                          Navigator.pop(context, finalSelection);
                        }
                      : null, // Disable if none selected
                  child: Text('استيراد (${selectedIds.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Customer?> _showCustomerSelectionDialog() async {
    return await showDialog<Customer>(
      context: context,
      builder: (context) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredCustomers = _appProvider.customers
                .where((c) =>
                    c.username
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()) ||
                    c.phoneNumber.contains(searchQuery))
                .toList();

            return AlertDialog(
              title: const Text('اختر الزبون'),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'بحث بالاسم أو رقم الهاتف...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return ListTile(
                            title: Text(customer.username),
                            subtitle: Text(customer.phoneNumber),
                            onTap: () {
                              Navigator.pop(context, customer);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });
    //QuerySnapshot<Map<String, dynamic>> snapshot = await
    var query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('timestamp', descending: true);

    if (showDelivered == false) {
      query = query.where('cashPossession', isNotEqualTo: "customer");
    }
    if (selectedCustomer == null &&
        selectedDriver == null &&
        _phoneController.text.isEmpty) {
      query = query.limit(_limit);
    }
    if (selectedCustomer != null) {
      query = query.where('username', isEqualTo: selectedCustomer);
    }
    if (selectedDriver != null) {
      query = query.where('driverName', isEqualTo: selectedDriver);
    }
    if (_phoneController.text.isNotEmpty) {
      query = query.where('phoneNumber', isEqualTo: _phoneController.text);
    }
    if (barcodeScannerOrderIds.isNotEmpty) {
      query = query.where('orderId', whereIn: barcodeScannerOrderIds);
    }

    // final currentUser = _appProvider.currentUserEmployee;

    // if (currentUser?.jobRole == 'موظف متابعة') {
    //   final assignedDrivers = currentUser?.assignedDrivers ?? [];
    //   if (assignedDrivers.isNotEmpty) {
    //     // Firestore 'whereIn' supports up to 30 values now
    //     // We use the first 30 assigned drivers for the server-side filter
    //     query =
    //         query.where('driverId', whereIn: assignedDrivers.take(30).toList());
    //   } else {
    //     // No drivers assigned: ensure zero orders are returned
    //     query =
    //         query.where('driverId', isEqualTo: 'no_driver_assigned_dummy_id');
    //   }
    // }

    await _ordersSubscription?.cancel();
    _ordersSubscription = query.snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          orders = snapshot.docs
              .map((doc) =>
                  Shipment.fromMap(Map<String, dynamic>.from(doc.data())))
              .toList();
          // app provider
          _appProvider.orders = orders;
          print("orders length: ${orders.length}");

          _applyFiltersLocally();
        });
      }
    });
  }

  final TextEditingController _driverSearchController = TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();
  late AppProvider _appProvider;
  // Filter controllers
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bookingDateController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _expectedDeliveryDateController =
      TextEditingController();
  final TextEditingController _lastStatusDateController =
      TextEditingController();
  final TextEditingController _postponementDateController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _recipientCityController =
      TextEditingController();
  final TextEditingController _recipientAreaController =
      TextEditingController();
  final TextEditingController _secondaryPhoneController =
      TextEditingController();
  String? selectedRecipientCityOnly;

  void _applyFiltersLocally() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUserEmployee;

    setState(() {
      filteredOrders = orders.where((order) {
        // ID & Search Filters
        bool matchesOrderId = _orderIdController.text.isEmpty ||
            order.orderId
                .toLowerCase()
                .contains(_orderIdController.text.toLowerCase());

        bool matchesTrackingNumber = _trackingNumberController.text.isEmpty ||
            order.trackingNumber
                .toLowerCase()
                .contains(_trackingNumberController.text.toLowerCase());

        bool matchesWeight = _weightController.text.isEmpty ||
            (double.tryParse(_weightController.text) != null &&
                order.weight == double.parse(_weightController.text));

        bool matchesPrice = _priceController.text.isEmpty ||
            (double.tryParse(_priceController.text) != null &&
                order.deliveryCost == double.parse(_priceController.text));

        bool matchesCustomer = selectedCustomer == null ||
            order.username?.toLowerCase() == selectedCustomer?.toLowerCase();

        bool matchesPhone = _phoneController.text.isEmpty ||
            order.phoneNumber.contains(_phoneController.text);

        bool matchesStatus = selectedStatus == null ||
            order.status.toLowerCase() == selectedStatus?.toLowerCase();

        bool matchesPaymentMethod = selectedPaymentMethod == null ||
            order.paymentMethod.toLowerCase() ==
                selectedPaymentMethod?.toLowerCase();

        bool matchesCollectionMethod = selectedCollectionMethod == null ||
            order.collectionMethod.toLowerCase() ==
                selectedCollectionMethod?.toLowerCase();

        bool matchesSenderName = _senderNameController.text.isEmpty ||
            (order.senderName?.toLowerCase() ?? '')
                .contains(_senderNameController.text.toLowerCase()) ||
            (order.username?.toLowerCase() ?? '')
                .contains(_senderNameController.text.toLowerCase());

        // Recipient Search Filters
        bool matchesRecipientName = _recipientNameController.text.isEmpty ||
            order.recipientName
                .toLowerCase()
                .contains(_recipientNameController.text.toLowerCase());

        bool matchesRecipientCity = _recipientCityController.text.isEmpty ||
            order.city
                .toLowerCase()
                .contains(_recipientCityController.text.toLowerCase());

        bool matchesRecipientArea = _recipientAreaController.text.isEmpty ||
            _getDistrict(order.addressDescription)
                .toLowerCase()
                .contains(_recipientAreaController.text.toLowerCase());

        // Legacy Dropdown Filter (if still used in overlay)
        bool matchesRecipientCityOnly = selectedRecipientCityOnly == null ||
            order.city
                .toLowerCase()
                .contains(selectedRecipientCityOnly!.toLowerCase());

        bool matchesSenderCity = selectedSenderCity == null ||
            order.city.toLowerCase() == selectedSenderCity?.toLowerCase();

        // Date Filters
        bool matchesBookingDate = _bookingDateController.text.isEmpty ||
            _isDateMatch(order.createdAt, _bookingDateController.text);

        bool matchesDeliveryDate = _deliveryDateController.text.isEmpty ||
            (order.deliveryDate != null &&
                _isDateMatch(
                    order.deliveryDate!, _deliveryDateController.text));

        bool matchesExpectedDeliveryDate =
            _expectedDeliveryDateController.text.isEmpty ||
                (order.expectedDeliveryDate != null &&
                    _isDateMatch(order.expectedDeliveryDate!,
                        _expectedDeliveryDateController.text));

        bool matchesLastStatusDate = _lastStatusDateController.text.isEmpty ||
            _isDateMatch(order.lastUpdated, _lastStatusDateController.text);

        bool matchesPostponementDate = _postponementDateController
                .text.isEmpty ||
            (order.postponementDate != null &&
                _isDateMatch(
                    order.postponementDate!, _postponementDateController.text));

        bool matchesNotes = _notesController.text.isEmpty ||
            order.notes
                .toLowerCase()
                .contains(_notesController.text.toLowerCase());

        bool matchesDriver = selectedDriver == null ||
            order.driverName?.toLowerCase() == selectedDriver?.toLowerCase();

        bool notDelivered = showDelivered ? true : order.status != "ملغاة";

        // Combine all standard filters
        bool baseMatches = matchesTrackingNumber &&
            notDelivered &&
            matchesOrderId &&
            matchesWeight &&
            matchesPrice &&
            matchesCustomer &&
            matchesPhone &&
            matchesStatus &&
            matchesPaymentMethod &&
            matchesCollectionMethod &&
            matchesSenderName &&
            matchesRecipientName &&
            matchesRecipientCity &&
            matchesRecipientArea &&
            matchesRecipientCityOnly &&
            matchesSenderCity &&
            matchesBookingDate &&
            matchesDeliveryDate &&
            matchesExpectedDeliveryDate &&
            matchesLastStatusDate &&
            matchesPostponementDate &&
            matchesDriver &&
            matchesNotes;

        // Role-based restrictions
        // if (currentUser?.jobRole == 'موظف متابعة') {
        //   if (currentUser?.assignedDrivers.isEmpty ?? true) {
        //     return false;
        //   }
        //   bool matchesAssignedDriver =
        //       currentUser!.assignedDrivers.contains(order.driverId);
        //   return baseMatches && matchesAssignedDriver;
        // }

        return baseMatches;
      }).toList();
    });
  }

  String _getDistrict(String addressDescription) {
    if (addressDescription.isEmpty) return '';
    var parts = addressDescription.split(' - ');
    return parts.isNotEmpty ? parts[0] : '';
  }

  // Helper method to compare dates
  bool _isDateMatch(DateTime orderDate, String filterDate) {
    try {
      DateTime filter = DateTime.parse(filterDate);
      return orderDate.year == filter.year &&
          orderDate.month == filter.month &&
          orderDate.day == filter.day;
    } catch (e) {
      return false;
    }
  }

  // Call this method whenever a filter changes
  void _onFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _applyFiltersLocally();
    });
  }

  @override
  void initState() {
    super.initState();

    // Listen for user role updates to refresh filter
    _appProvider = Provider.of<AppProvider>(context, listen: false);
    _appProvider.addListener(_onAppProviderUpdate);

    // Set initial toolbar visibility based on screen size
    Future.delayed(Duration.zero, () {
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        _isSwitched =
            screenWidth >= 1200; // Large screen: true, Small screen: false
      });
    });

    _loadColumnSettings();
    _fetchOrders();
    Future.delayed(Duration.zero, () {
      // Add null safety checks for scroll controllers
      // if (_horizontalScrollController.hasClients &&
      //     _horizontalScrollController.position.hasContentDimensions) {
      //   _horizontalScrollController
      //       .jumpTo(_horizontalScrollController.position.maxScrollExtent);
      // }
    });
    _horizontalScrollController.addListener(() {
      // Add null safety checks before accessing scroll controller properties
      if (_horizontalScrollController.hasClients &&
          _headerHorizontalScrollController.hasClients &&
          _horizontalScrollController.position.hasContentDimensions &&
          _headerHorizontalScrollController.position.hasContentDimensions) {
        print(_horizontalScrollController.offset);
        print(_headerHorizontalScrollController.offset);
        print(_horizontalScrollController.position.maxScrollExtent);
        _headerHorizontalScrollController.jumpTo(
            _horizontalScrollController.position.maxScrollExtent -
                _horizontalScrollController.offset);
      }
    });
    _verticalMainScrollController.addListener(() {
      setState(() {
        showJump = _verticalMainScrollController.offset != 0;
      });
    });

    // Add listener for mobile scroll detection
    _verticalScrollController.addListener(() {
      _onMobileScroll();
    });
    //_verticalScrollController.addListener(_onScroll);

    //  _verticalScrollController.addListener(_onScroll);

    // Add listeners to all filter controllers
    _orderIdController.addListener(_onFilterChanged);
    _trackingNumberController.addListener(_onFilterChanged);
    _weightController.addListener(_onFilterChanged);
    _priceController.addListener(_onFilterChanged);
    _phoneController.addListener(_onFilterChanged);
    _senderNameController.addListener(_onFilterChanged);
    _recipientNameController.addListener(_onFilterChanged);
    _notesController.addListener(_onFilterChanged);
    _bookingDateController.addListener(_onFilterChanged);
    _deliveryDateController.addListener(_onFilterChanged);
    _expectedDeliveryDateController.addListener(_onFilterChanged);
    _lastStatusDateController.addListener(_onFilterChanged);
    _postponementDateController.addListener(_onFilterChanged);
    _recipientCityController.addListener(_onFilterChanged);
    _recipientAreaController.addListener(_onFilterChanged);
    _secondaryPhoneController.addListener(_onFilterChanged);
  }

  void _onAppProviderUpdate() {
    // If we have orders but the filter might have been skipped because user wasn't loaded
    // we should re-fetch to apply the correct Firestore-level filters.
    if (mounted && orders.isNotEmpty) {
      final currentUser = _appProvider.currentUserEmployee;
      if (currentUser?.jobRole == 'موظف متابعة') {
        _fetchOrders();
      }
    }
  }

  @override
  void dispose() {
    _appProvider.removeListener(_onAppProviderUpdate);
    _ordersSubscription?.cancel();
    _debounce?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _headerHorizontalScrollController.dispose();
    _verticalMainScrollController.dispose();
    _driverSearchController.dispose();
    _customerSearchController.dispose();
    _orderIdController.dispose();
    _trackingNumberController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _bookingDateController.dispose();
    _deliveryDateController.dispose();
    _expectedDeliveryDateController.dispose();
    _lastStatusDateController.dispose();
    _postponementDateController.dispose();
    _notesController.dispose();
    _senderNameController.dispose();
    _recipientNameController.dispose();
    _secondaryPhoneController.dispose();
    _recipientCityController.dispose();
    _recipientAreaController.dispose();
    super.dispose();
  }

  List<Driver> _getVisibleDrivers(AppProvider appProvider) {
    // final currentUser = appProvider.currentUserEmployee;
    // if (currentUser?.jobRole == 'موظف متابعة') {
    //   return appProvider.drivers
    //       .where(
    //           (driver) => currentUser!.assignedDrivers.contains(driver.userid))
    //       .toList();
    // }
    return appProvider.drivers;
  }

  @override
  void didUpdateWidget(ManageShipmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if selectedIndex has changed
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      if (widget.selectedIndex == 1) {
        setState(() {
          selectedOrderIds = {};

          selectedStatus = null;
          _applyFiltersLocally();
        });
      } else if (widget.selectedIndex == 2) {
        setState(() {
          selectedOrderIds = {};
          filteredOrders = [];
        });
      }
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary, // Your primary color
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format the date as you prefer
      final formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      controller.text = formattedDate;
    }
  }

  // Dropdown values
  String? selectedStatus;
  String? selectedShipment;
  String? selectedPaymentMethod;
  String? selectedCollectionMethod;
  String? selectedCustomer;
  String? selectedDriver;
  String? selectedSenderCity;
  String? selectedRecipientCity;

  Future<void> _fetchMoreOrders(int limit) async {
    setState(() {
      _limit += limit;
    });
    await _fetchOrders();
  }

  void _onMobileScroll() {
    if (_verticalScrollController.hasClients) {
      final maxScroll = _verticalScrollController.position.maxScrollExtent;
      final currentScroll = _verticalScrollController.offset;
      final delta = 200.0; // Show button when 200px from bottom

      bool shouldShowButton = (maxScroll - currentScroll) <= delta &&
          filteredOrders.length < orders.length;

      if (_showLoadMoreButton != shouldShowButton) {
        setState(() {
          _showLoadMoreButton = shouldShowButton;
        });
      }
    }
  }

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

// Add this method to create the overlay
  void _showOverlaySender(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(
              0.0, 40.0), // Adjust this to control distance below button
          child: Material(
            elevation: 8,
            child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: CustomForm(
                  title: 'تخصيص معلومات المرسل',
                  fields: [
                    CustomSearchField(
                      label: 'الاسم',
                      controller: _senderNameController,
                      onChanged: (value) {
                        // Handle name change
                      },
                    ),
                    DropdownFormField(
                      label: 'المنطقة',
                      value: selectedSenderCity,
                      items: jordanianCities,
                      onChanged: (value) {
                        setState(() {
                          selectedSenderCity = value;
                          _applyFiltersLocally();
                        });
                      },
                    ),
                  ],
                  onCancel: () {
                    setState(() {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    });
                  },
                  onSubmit: () {
                    setState(() {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    });
                  },
                )),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  final LayerLink _layerLinkRecipient = LayerLink();

// Add this method to create the overlay
  void _showOverlayRecipient(BuildContext context, List<String> cities) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLinkRecipient,
          showWhenUnlinked: false,
          offset: const Offset(
              0.0, 40.0), // Adjust this to control distance below button
          child: Material(
            elevation: 8,
            child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: CustomForm(
                  title: 'تخصيص معلومات المستقبل',
                  fields: [
                    CustomSearchField(
                      label: 'الاسم',
                      controller: _recipientNameController,
                      onChanged: (value) {
                        // Handle name change
                      },
                    ),
                    DropdownFormField(
                      label: 'المدينة',
                      value: selectedRecipientCityOnly,
                      items: cities
                          .map((city) => city.split(" ")[0])
                          .toSet()
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRecipientCityOnly = value;
                          _applyFiltersLocally();
                        });
                      },
                    ),
                    DropdownFormField(
                      label: 'المنطقة',
                      value: selectedRecipientCity,
                      items: cities
                          .where((city) =>
                              city.startsWith(selectedRecipientCityOnly ?? ""))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRecipientCity = value;
                          _applyFiltersLocally();
                        });
                      },
                    ),
                  ],
                  onCancel: () {
                    setState(() {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    });
                  },
                  onSubmit: () {
                    setState(() {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    });
                  },
                )),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  List<Map<String, dynamic>> columnConfigs = [
    {'id': 'orderId', 'label': 'رقم الطرد', 'visible': true, 'width': 200.0},
    {'id': 'weight', 'label': 'الوزن', 'visible': true, 'width': 150.0},
    {'id': 'price', 'label': 'الاجور', 'visible': true, 'width': 200.0},
    {'id': 'cod', 'label': 'COD', 'visible': true, 'width': 150.0},
    {'id': 'customer', 'label': 'الزبون', 'visible': true, 'width': 250.0},
    {'id': 'driver', 'label': 'السواق', 'visible': true, 'width': 250.0},
    {'id': 'phone', 'label': 'هاتف المستقبل', 'visible': true, 'width': 200.0},
    {
      'id': 'secondaryPhone',
      'label': 'الهاتف الاحتياطي',
      'visible': true,
      'width': 200.0
    },
    {'id': 'sender', 'label': 'المرسل', 'visible': true, 'width': 200.0},
    {
      'id': 'recipientName',
      'label': 'اسم المستقبل',
      'visible': true,
      'width': 200.0
    },
    {
      'id': 'recipientCity',
      'label': 'المدينة',
      'visible': true,
      'width': 150.0
    },
    {
      'id': 'recipientArea',
      'label': 'المنطقة',
      'visible': true,
      'width': 150.0
    },
    {'id': 'status', 'label': 'الحالة', 'visible': true, 'width': 200.0},
    {'id': 'tracking', 'label': 'الإرسالية', 'visible': true, 'width': 200.0},
    {
      'id': 'paymentMethod',
      'label': 'طريقة الدفع',
      'visible': true,
      'width': 200.0
    },
    {
      'id': 'collectionMethod',
      'label': 'طريقة التحصيل',
      'visible': true,
      'width': 200.0
    },
    {
      'id': 'bookingDate',
      'label': 'تاريخ الحجز',
      'visible': true,
      'width': 200.0
    },
    {
      'id': 'deliveryDate',
      'label': 'تاريخ التوصيل',
      'visible': true,
      'width': 200.0
    },
    {
      'id': 'expectedDeliveryDate',
      'label': 'التوصيل المتوقع',
      'visible': true,
      'width': 200.0
    },
    {
      'id': 'lastStatusDate',
      'label': 'تاريخ اخر حالة',
      'visible': true,
      'width': 200.0
    },
    {
      'id': 'postponementDate',
      'label': 'تاريخ التأجيل',
      'visible': true,
      'width': 200.0
    },
    {'id': 'notes', 'label': 'ملاحظات', 'visible': true, 'width': 200.0},
    {'id': 'actions', 'label': 'الإجراءات', 'visible': true, 'width': 70.0},
  ];

  get totalWidth {
    return columnConfigs.where((c) => c['visible']).fold(
        0.0, (sum, config) => sum + (config['width'] as double? ?? 200.0));
  }

  Future<void> _loadColumnSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedConfigs = prefs.getString('shipment_column_configs');
    if (savedConfigs != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedConfigs);
        setState(() {
          List<Map<String, dynamic>> loadedConfigs =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();

          List<Map<String, dynamic>> updatedConfigs = [];
          for (var loaded in loadedConfigs) {
            final defaultIdx =
                columnConfigs.indexWhere((c) => c['id'] == loaded['id']);
            if (defaultIdx != -1) {
              updatedConfigs.add({
                ...columnConfigs[defaultIdx],
                'visible': loaded['visible'] ?? true,
                'width': loaded['width'] ?? columnConfigs[defaultIdx]['width'],
              });
            }
          }

          for (var defaultCol in columnConfigs) {
            if (!updatedConfigs.any((c) => c['id'] == defaultCol['id'])) {
              updatedConfigs.add(defaultCol);
            }
          }

          columnConfigs = updatedConfigs;
        });
      } catch (e) {
        debugPrint('Error loading column settings: $e');
      }
    }
  }

  Future<void> _saveColumnSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(columnConfigs);
    await prefs.setString('shipment_column_configs', encoded);
  }

  void _showColumnSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إعدادات الأعمدة', textAlign: TextAlign.right),
          content: Container(
            width: 400,
            height: 500,
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setDialogState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = columnConfigs.removeAt(oldIndex);
                  columnConfigs.insert(newIndex, item);
                });
                _saveColumnSettings();
                setState(() {}); // Update main table
              },
              children: columnConfigs.map((config) {
                return ListTile(
                  key: ValueKey(config['id']),
                  leading: Icon(Icons.drag_handle),
                  title: Text(config['label'], textAlign: TextAlign.right),
                  trailing: Checkbox(
                    value: config['visible'],
                    onChanged: (val) {
                      setDialogState(() {
                        config['visible'] = val;
                      });
                      _saveColumnSettings();
                      setState(() {}); // Update main table
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActiveFilters() {
    List<Map<String, dynamic>> activeFilters = [];

    void addFilter(String label, String value, VoidCallback onClear) {
      if (value.trim().isNotEmpty) {
        activeFilters.add({'label': label, 'value': value, 'onClear': onClear});
      }
    }

    addFilter(
        'رقم الطلب', _orderIdController.text, () => _orderIdController.clear());
    addFilter('رقم التتبع', _trackingNumberController.text,
        () => _trackingNumberController.clear());
    addFilter('الوزن', _weightController.text, () => _weightController.clear());
    addFilter('السعر', _priceController.text, () => _priceController.clear());
    addFilter('الهاتف', _phoneController.text, () => _phoneController.clear());
    addFilter('المرسل', _senderNameController.text,
        () => _senderNameController.clear());
    addFilter('المستقبل', _recipientNameController.text,
        () => _recipientNameController.clear());
    addFilter('المدينة', _recipientCityController.text,
        () => _recipientCityController.clear());
    addFilter('المنطقة', _recipientAreaController.text,
        () => _recipientAreaController.clear());
    addFilter('ملاحظات', _notesController.text, () => _notesController.clear());
    addFilter('تاريخ الحجز', _bookingDateController.text,
        () => _bookingDateController.clear());
    addFilter('تاريخ التوصيل', _deliveryDateController.text,
        () => _deliveryDateController.clear());
    addFilter('تاريخ التوصيل المتوقع', _expectedDeliveryDateController.text,
        () => _expectedDeliveryDateController.clear());
    addFilter('تاريخ آخر حالة', _lastStatusDateController.text,
        () => _lastStatusDateController.clear());
    addFilter('تاريخ التأجيل', _postponementDateController.text,
        () => _postponementDateController.clear());

    if (selectedStatus != null) {
      addFilter('الحالة', selectedStatus!, () {
        setState(() => selectedStatus = null);
        _applyFiltersLocally();
      });
    }
    if (selectedPaymentMethod != null) {
      addFilter('طريقة الدفع', selectedPaymentMethod!, () {
        setState(() => selectedPaymentMethod = null);
        _applyFiltersLocally();
      });
    }
    if (selectedCollectionMethod != null) {
      addFilter('طريقة الجمع', selectedCollectionMethod!, () {
        setState(() => selectedCollectionMethod = null);
        _applyFiltersLocally();
      });
    }
    if (selectedCustomer != null) {
      addFilter('الزبون', selectedCustomer!, () {
        setState(() => selectedCustomer = null);
        _applyFiltersLocally();
      });
    }
    if (selectedDriver != null) {
      addFilter('السائق', selectedDriver!, () {
        setState(() => selectedDriver = null);
        _applyFiltersLocally();
      });
    }
    if (selectedSenderCity != null) {
      addFilter('مدينة المرسل', selectedSenderCity!, () {
        setState(() => selectedSenderCity = null);
        _applyFiltersLocally();
      });
    }

    if (selectedRecipientCityOnly != null) {
      addFilter('مدينة المستقبل (تخصيص)', selectedRecipientCityOnly!, () {
        setState(() => selectedRecipientCityOnly = null);
        _applyFiltersLocally();
      });
    }

    addFilter('الهاتف الثاني', _secondaryPhoneController.text,
        () => _secondaryPhoneController.clear());

    return activeFilters;
  }

  Widget _buildActiveFilters() {
    final activeFilters = _getActiveFilters();
    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'الفلاتر المفعلة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _orderIdController.clear();
                    _trackingNumberController.clear();
                    _weightController.clear();
                    _priceController.clear();
                    _phoneController.clear();
                    _senderNameController.clear();
                    _recipientNameController.clear();
                    _recipientCityController.clear();
                    _recipientAreaController.clear();
                    _notesController.clear();
                    _bookingDateController.clear();
                    _deliveryDateController.clear();
                    _expectedDeliveryDateController.clear();
                    _lastStatusDateController.clear();
                    _postponementDateController.clear();
                    _secondaryPhoneController.clear();
                    selectedStatus = null;
                    selectedPaymentMethod = null;
                    selectedCollectionMethod = null;
                    selectedCustomer = null;
                    selectedDriver = null;
                    selectedSenderCity = null;
                    selectedRecipientCityOnly = null;
                  });
                  _applyFiltersLocally();
                },
                child: Text('مسح الكل', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeFilters.map((filter) {
              return Chip(
                label: Text('${filter['label']}: ${filter['value']}'),
                onDeleted: () {
                  filter['onClear']();
                },
                deleteIcon: Icon(Icons.close, size: 18),
                backgroundColor: Colors.blue[50],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  final GlobalKey<PaginatedDataTableState> _tableKey =
      GlobalKey<PaginatedDataTableState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            _overlayEntry?.remove();
            _overlayEntry = null;
          });
        },
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: _isLoading ? CircularProgressIndicator() : null,
            ),
            //todo
            if (widget.selectedIndex == 2)
              CustomTabBar(
                onTabChanged: (index) {
                  _filterShipmentsByTab(index);
                },
              ),
            Expanded(
              child: Scaffold(
                floatingActionButtonAnimator:
                    FloatingActionButtonAnimator.scaling,
                key: _scaffoldKey,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
                floatingActionButton: showJump
                    ? FloatingActionButton(
                        onPressed: () {
                          _fetchMoreOrders(40);
                        },
                        child: Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      )
                    : null,
                body: Column(
                  children: [
                    Expanded(
                        child: _ResponsiveBody(
                            controller: _verticalMainScrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20, right: 30, left: 20),
                                  child: Wrap(
                                    children: [
                                      Consumer<AppProvider>(builder:
                                          (context, appProvider, child) {
                                        if (appProvider
                                                .currentUserEmployee?.jobRole ==
                                            'موظف متابعة') {
                                          return Text("تنسيقات المتابعه");
                                        }
                                        return widget.selectedIndex == 1
                                            ? Text("إدارة الطرود")
                                            : Text("المتابعات");
                                      }),

                                      SizedBox(width: 40),

                                      // // Spacer(),
                                      // if (orders.isNotEmpty)
                                      //   Row(
                                      //     children: [
                                      //       Text(
                                      //         "أول تاريخ: ${orders.last.createdAt.day}/${orders.last.createdAt.month} ${orders.last.createdAt.hour}:00 | ",
                                      //         style: TextStyle(fontSize: 14),
                                      //       ),
                                      //       Text(
                                      //         "آخر تاريخ: ${orders.first.createdAt.day}/${orders.first.createdAt.month} ${orders.first.createdAt.hour}:00",
                                      //         style: TextStyle(fontSize: 14),
                                      //       ),
                                      //       SizedBox(width: 20),
                                      //     ],
                                      //   ),

                                      CustomSwitchBar(
                                        label: 'شريط الأدوات',
                                        value: _isSwitched,
                                        onChanged: (value) {
                                          setState(() {
                                            _isSwitched = value;
                                          });
                                        },
                                      ),
                                      CustomSwitchBar(
                                        label: 'تحديد متعدد',
                                        value: _isRangeSelectionMode,
                                        onChanged: (value) {
                                          setState(() {
                                            _isRangeSelectionMode = value;
                                            _lastSelectedOrderId = null;
                                          });
                                        },
                                      ),
                                      CustomSwitchBar(
                                        label: 'عرض المغلقه',
                                        value: showDelivered,
                                        onChanged: (value) {
                                          setState(() {
                                            showDelivered = value;
                                            _fetchOrders();
                                          });
                                        },
                                      ),
                                      // if (filteredOrders.length < orders.length)
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.arrow_downward),
                                        label: Text('تحميل المزيد'),
                                        onPressed: () {
                                          _fetchMoreOrders(40);
                                        },
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.qr_code_scanner),
                                        label: Text('ماسح الباركود'),
                                        onPressed: () {
                                          Navigator.pushNamed(
                                              context, '/barcodescanner');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFDC2626),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.settings),
                                        label: Text('إعدادات الأعمدة'),
                                        onPressed: _showColumnSettings,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueGrey,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),

                                      CustomContainer(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            PopupMenuButton(
                                              onSelected: (value) async {
                                                final excelImporter =
                                                    ExcelImportHandler();

                                                if (value == 'export_excel') {
                                                  if (selectedOrderIds
                                                      .isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'يرجى تحديد الطرود'),
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  try {
                                                    // get list of selectedOrders from selectedOrderIds List
                                                    final selectedOrders = orders
                                                        .where((order) =>
                                                            selectedOrderIds
                                                                .contains(order
                                                                    .orderId))
                                                        .toList();
                                                    final excelHandler =
                                                        ExcelImportHandler();
                                                    final excelBytes =
                                                        await excelHandler
                                                            .exportShipmentsToExcel(
                                                                selectedOrders);

                                                    await FileHandler
                                                        .downloadFile(
                                                            excelBytes,
                                                            'shipments.xlsx');

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'تم تصدير البيانات بنجاح')),
                                                    );
                                                  } catch (e) {
                                                    print(
                                                        'Error exporting to Excel: $e');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'حدث خطأ أثناء التصدير: $e')),
                                                    );
                                                  }
                                                } else if (value ==
                                                    'import_excel') {
                                                  try {
                                                    final selected =
                                                        await _showCustomerSelectionDialog();
                                                    if (selected != null) {
                                                      // 1. Parse Shipments
                                                      List<Shipment>
                                                          parsedShipments =
                                                          await excelImporter
                                                              .importShipmentsFromExcel(
                                                        selectedUserId:
                                                            selected.userid,
                                                        selectedUsername:
                                                            selected.username,
                                                        appProvider:
                                                            appProvider,
                                                      );

                                                      if (parsedShipments
                                                          .isEmpty) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'لم يتم العثور على شحنات صالحة في الملف')),
                                                          );
                                                        }
                                                        return;
                                                      }

                                                      // 2. Check for duplicates
                                                      Set<String>
                                                          existingTrackingNumbers =
                                                          await excelImporter
                                                              .getExistingTrackingNumbers(
                                                                  parsedShipments
                                                                      .map((s) =>
                                                                          s.trackingNumber)
                                                                      .toList());

                                                      // 3. Show Selection Dialog
                                                      if (context.mounted) {
                                                        List<Shipment>?
                                                            selectedShipments =
                                                            await _showShipmentSelectionDialog(
                                                                parsedShipments,
                                                                existingTrackingNumbers);

                                                        // 3. Upload if confirmed
                                                        if (selectedShipments !=
                                                                null &&
                                                            selectedShipments
                                                                .isNotEmpty) {
                                                          await excelImporter
                                                              .uploadShipments(
                                                                  selectedShipments);

                                                          if (context.mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                  content: Text(
                                                                      'تم استيراد ${selectedShipments.length} شحنة بنجاح')),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    }
                                                  } catch (e) {
                                                    print(e);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'حدث خطأ أثناء الاستيراد: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'export_excel',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.file_present,
                                                          color:
                                                              Colors.black54),
                                                      SizedBox(width: 8.0),
                                                      Text("تصدير Excel"),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'import_excel',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.file_present,
                                                          color:
                                                              Colors.black54),
                                                      SizedBox(width: 8.0),
                                                      Text("استيراد Excel"),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.arrow_drop_down,
                                                      color: Colors.black54),
                                                  SizedBox(width: 4.0),
                                                  Text(
                                                    'استيراد / تصدير',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8.0),
                                                  Icon(Icons.description,
                                                      color: Colors.black54),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CustomContainer(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            PopupMenuButton(
                                              initialValue: _limit,
                                              onSelected: (value) async {
                                                setState(() {
                                                  _limit = value;
                                                });
                                                await _fetchOrders();
                                              },
                                              itemBuilder: (context) => [
                                                ...List.generate(5, (index) {
                                                  final value =
                                                      (index + 1) * 50;
                                                  return PopupMenuItem(
                                                    value: value,
                                                    child:
                                                        Text(value.toString()),
                                                  );
                                                }),
                                              ],
                                              child: Row(
                                                children: [
                                                  Icon(Icons.arrow_drop_down,
                                                      color: Colors.black54),
                                                  SizedBox(width: 4.0),
                                                  Text(
                                                    "عدد المعروض: $_limit",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8.0),
                                                  Icon(Icons.description,
                                                      color: Colors.black54),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // load more orders

                                      // CustomContainer(
                                      //   child: Row(
                                      //     mainAxisSize: MainAxisSize.min,
                                      //     children: [
                                      //       PopupMenuButton(
                                      //         onSelected: (value) {},
                                      //         itemBuilder: (context) =>
                                      //             dates.asMap().entries.map((entry) {
                                      //           int index = entry.key;
                                      //           String date = entry.value;
                                      //
                                      //           return PopupMenuItem<int>(
                                      //             value: index,
                                      //             child: Row(
                                      //               children: [
                                      //                 Text(date),
                                      //               ],
                                      //             ),
                                      //           );
                                      //         }).toList(),
                                      //         child: const Row(
                                      //           children: [
                                      //             Icon(Icons.arrow_drop_down,
                                      //                 color: Colors.black54),
                                      //             SizedBox(width: 4.0),
                                      //             Text(
                                      //               'تاريخ الججز',
                                      //               style: TextStyle(
                                      //                 fontSize: 16,
                                      //                 fontWeight: FontWeight.w500,
                                      //               ),
                                      //             ),
                                      //             SizedBox(width: 8.0),
                                      //             Icon(Icons.calendar_month,
                                      //                 color: Colors.black54),
                                      //           ],
                                      //         ),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      // CustomContainer(
                                      //   child: GestureDetector(
                                      //     onTap: _pickDate,
                                      //     child: const Row(
                                      //       children: [
                                      //         Icon(Icons.arrow_drop_down,
                                      //             color: Colors.black54),
                                      //         SizedBox(width: 4.0),
                                      //         Text(
                                      //           'الكل',
                                      //           style: TextStyle(
                                      //             fontSize: 16,
                                      //             fontWeight: FontWeight.w500,
                                      //           ),
                                      //         ),
                                      //         SizedBox(width: 8.0),
                                      //         Icon(Icons.calendar_month,
                                      //             color: Colors.black54),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),
                                      // customFilterOptions(),
                                      // CustomContainer(
                                      //   child: Container(
                                      //     width: 120,
                                      //     child: const TextField(
                                      //       decoration: InputDecoration(
                                      //           labelText: 'البحث',
                                      //           labelStyle: TextStyle(fontSize: 12),
                                      //           border: InputBorder.none,
                                      //           suffixIcon: Icon(Icons.search)),
                                      //     ),
                                      //   ),
                                      // )
                                    ],
                                  ),
                                ),
                                if (_isSwitched)
                                  Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                        color: Color(0xfffefaf3),
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 5.0,
                                      runSpacing: 5.0,
                                      children: [
                                        ...[
                                          'استلام طرود من السائق',
                                          'استلام الطرود المرجعه من السائق',
                                        ].asMap().entries.map((entry) {
                                          int index = entry.key;
                                          String date = entry.value;
                                          return CustomButton(
                                            text: date,
                                            onPressed: () {
                                              showDeliveryDialog(
                                                  context, index);
                                            },
                                            color: Color(0xFFDC2626),
                                            textColor: Colors.white,
                                            fontSize: 12.0,
                                            borderRadius: 10.0,
                                            // icon: Icons.check,
                                            iconColor: Colors.white,
                                            height: 30.0,
                                            isLoading: false,
                                          );
                                        }),
                                        CustomButton(
                                          text: 'الجولات',
                                          onPressed: () {
                                            showTourDialog(context);
                                          },
                                          color: Colors.blue,
                                          textColor: Colors.white,
                                          fontSize: 12.0,
                                          borderRadius: 10.0,
                                          iconColor: Colors.white,
                                          height: 30.0,
                                          isLoading: false,
                                        ),
                                        CustomButton(
                                          text: 'جلب من زبائن',
                                          onPressed: () {
                                            showCustomerCollectionDialog(
                                                context);
                                          },
                                          color: Colors.green,
                                          textColor: Colors.white,
                                          fontSize: 12.0,
                                          borderRadius: 10.0,
                                          iconColor: Colors.white,
                                          height: 30.0,
                                          isLoading: false,
                                        ),
                                        CustomButton(
                                          text: 'طباعه طلبات سائق',
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder:
                                                    (context) =>
                                                        StatefulBuilder(builder:
                                                            (context,
                                                                setState) {
                                                          String
                                                              selectedPageFormat =
                                                              "a5";
                                                          bool isLoading =
                                                              false;
                                                          return Dialog(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15)),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(20),
                                                              width: 400,
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        "طباعة طلبات سائق",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                20,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      IconButton(
                                                                        icon: Icon(
                                                                            Icons.close),
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.pop(context),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          20),
                                                                  CustomDropdown(
                                                                    labelText:
                                                                        'اختر السائق',
                                                                    prefixIcon:
                                                                        Icons
                                                                            .person_outline,
                                                                    value:
                                                                        selectedDriver,
                                                                    items: _getVisibleDrivers(
                                                                            appProvider)
                                                                        .map((e) =>
                                                                            e.username ??
                                                                            '')
                                                                        .where((name) =>
                                                                            name.isNotEmpty)
                                                                        .toList(),
                                                                    onClearPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        selectedDriver =
                                                                            null;
                                                                        _applyFiltersLocally();
                                                                      });
                                                                    },
                                                                    onChanged:
                                                                        (String?
                                                                            newValue) {
                                                                      setState(
                                                                          () {
                                                                        selectedDriver =
                                                                            newValue!;

                                                                        _applyFiltersLocally();
                                                                      });
                                                                    },
                                                                  ),
                                                                  CustomDropdown(
                                                                      hintText:
                                                                          "اختر الصيغة",
                                                                      items: [
                                                                        "a5",
                                                                        "a4"
                                                                      ],
                                                                      onChanged:
                                                                          (String?
                                                                              newValue) {
                                                                        setState(
                                                                            () {
                                                                          selectedPageFormat =
                                                                              newValue!;
                                                                        });
                                                                      }),
                                                                  const SizedBox(
                                                                      height:
                                                                          30),
                                                                  SizedBox(
                                                                    width: double
                                                                        .infinity,
                                                                    child:
                                                                        CustomButton(
                                                                      isLoading:
                                                                          isLoading,
                                                                      text:
                                                                          'طباعة',
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          isLoading =
                                                                              true;
                                                                        });
                                                                        print(
                                                                            selectedDriver);
                                                                        String? driverId = appProvider
                                                                            .drivers
                                                                            .firstWhere((e) =>
                                                                                e.username ==
                                                                                selectedDriver)
                                                                            .userid;
                                                                        print(
                                                                            driverId);
                                                                        FirebaseFirestore
                                                                            .instance
                                                                            .collection(
                                                                                'orders')
                                                                            .where('driverId',
                                                                                isEqualTo:
                                                                                    driverId)
                                                                            .where('status', whereIn: [
                                                                              "في المركبة",
                                                                              "مؤجلة لوقت آخر"
                                                                            ])
                                                                            .get()
                                                                            .then((value) {
                                                                              print(value.docs.map((e) => e.data()));
                                                                              List<Shipment> shipments = value.docs.map((e) => Shipment.fromMap(e.data())).toList();
                                                                              PrintHandler().printShipmentsDocument(
                                                                                shipments,
                                                                                pageFormatString: selectedPageFormat,
                                                                                driverName: selectedDriver,
                                                                              );
                                                                              setState(() {
                                                                                isLoading = false;
                                                                              });
                                                                              Navigator.pop(context);
                                                                            });
                                                                      },
                                                                      color: Colors
                                                                          .green,
                                                                      textColor:
                                                                          Colors
                                                                              .white,
                                                                      fontSize:
                                                                          16.0,
                                                                      borderRadius:
                                                                          10.0,
                                                                      height:
                                                                          45,
                                                                      icon: Icons
                                                                          .print,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        }));
                                          },
                                          color: Colors.green,
                                          textColor: Colors.white,
                                          fontSize: 12.0,
                                          borderRadius: 10.0,
                                        ),

                                        PopupMenuButton<String>(
                                          child: Container(
                                            height: 30.0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFDC2626),
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'طباعة الطرود المحدده',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.white),
                                              ],
                                            ),
                                          ),
                                          onSelected: (String value) {
                                            final selectedOrders = orders
                                                .where((order) =>
                                                    selectedOrderIds.contains(
                                                        order.orderId))
                                                .toList();

                                            switch (value) {
                                              case 'a5':
                                                PrintHandler()
                                                    .printShipmentsDocument(
                                                        selectedOrders,
                                                        pageFormatString: "a5");
                                                break;
                                              case 'a4':
                                                PrintHandler()
                                                    .printShipmentsDocument(
                                                        selectedOrders,
                                                        pageFormatString: "a4");
                                                break;
                                              case 'compact':
                                                PrintHandler()
                                                    .printShipmentReceipt(
                                                        selectedOrders);
                                                break;
                                              case 'detailed':
                                                PrintHandler().print10x9Receipt(
                                                    selectedOrders);
                                                break;
                                              case 'ملصق 4*6':
                                                PrintHandler().print6x4Receipt(
                                                    selectedOrders);
                                                break;
                                              case 'ملصق 10*15':
                                                PrintHandler()
                                                    .print15x10Receipt(
                                                        selectedOrders);
                                                break;
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'a5',
                                              child: Text('A5 قائمة '),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'a4',
                                              child: Text('A4 قائمة '),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'compact',
                                              child: Text('بوليصة'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'detailed',
                                              child: Text('ملصق 9*10'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'ملصق 4*6',
                                              child: Text('ملصق 4*6'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'ملصق 10*15',
                                              child: Text('ملصق 10*15'),
                                            ),
                                          ],
                                        ),
                                        // CustomButton(
                                        //   text: 'قراءة بالباركود',
                                        //   onPressed: () {},
                                        //   color: Colors.green,
                                        //   textColor: Colors.white,
                                        //   fontSize: 12.0,
                                        //   borderRadius: 10.0,
                                        //   // icon: Icons.check,
                                        //   iconColor: Colors.white,
                                        //   height: 30.0,
                                        //   isLoading: false,
                                        // ),
                                        CustomButton(
                                          text: 'تعيين السائق',
                                          onPressed: () async {
                                            Driver? selectedDriver =
                                                await showDriverAssignmentDialog(
                                                    context,
                                                    _getVisibleDrivers(
                                                        appProvider));
                                            if (selectedDriver != null) {
                                              selectedOrderIds.forEach((e) {
                                                appProvider.assignDriver(
                                                    e, selectedDriver);
                                              });
                                              print(
                                                  'Selected driver: ${selectedDriver.username}');
                                            }
                                          },
                                          color: Colors.green,
                                          textColor: Colors.white,
                                          fontSize: 12.0,
                                          borderRadius: 10.0,
                                          // icon: Icons.check,
                                          iconColor: Colors.white,
                                          height: 30.0,
                                          isLoading: false,
                                          enabled:
                                              selectedOrderIds.isNotEmpty &&
                                                  selectedStatus ==
                                                      "الطلبات الجديدة",
                                        ),
                                        CustomButton(
                                          text: 'تغير الحاله',
                                          onPressed: () async {
                                            return showChangeStatusBottomSheet(
                                              context: context,
                                                appProvider: appProvider,
                                                selectedOrderIds: selectedOrderIds.toList()
                                                )
                                                ;
                                          },
                                          color: Colors.green,
                                          textColor: Colors.white,
                                          fontSize: 12.0,
                                          borderRadius: 10.0,
                                          // icon: Icons.check,
                                          iconColor: Colors.white,
                                          height: 30.0,
                                          isLoading: false,
                                          enabled: selectedOrderIds.isNotEmpty,
                                        ),

                                        CustomButton(
                                          text: 'قراءة  باركود',
                                          onPressed: () {
                                            setState(() {
                                              barcodeScannerOrderIds.clear();
                                            });
                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    BarcodeScannerDialog(
                                                      title:
                                                          'قراءة باركود', // optional
                                                      onScan: (String code) {
                                                        print(code);
                                                        appProvider
                                                            .getOrder(code)
                                                            .then((order) {
                                                          if (order != null) {
                                                            if (!barcodeScannerOrderIds
                                                                .contains(order
                                                                    .orderId)) {
                                                              barcodeScannerOrderIds
                                                                  .add(order
                                                                      .orderId);
                                                              setState(() {});
                                                              _fetchOrders();
                                                            }
                                                          }
                                                        });
                                                      },

                                                      showManualInput:
                                                          false, // optional
                                                    ));
                                          },
                                          color: Color(0xFFDC2626),
                                          textColor: Colors.white,
                                          fontSize: 12.0,
                                          borderRadius: 10.0,
                                        ),

                                        if (barcodeScannerOrderIds.isNotEmpty)
                                          // turn off barcode scanner mode
                                          CustomButton(
                                            text: 'إيقاف قراءة الباركود',
                                            onPressed: () {
                                              setState(() {
                                                barcodeScannerOrderIds.clear();
                                                _fetchOrders();
                                              });
                                            },
                                            color: Colors.red,
                                            textColor: Colors.white,
                                            fontSize: 12.0,
                                            borderRadius: 10.0,
                                          ),
                                        if (selectedOrderIds.length > 1)
                                          CustomButton(
                                            text: "عمل حزمه مجمعه",
                                            onPressed: () async {
                                              String bundelId =
                                                  await appProvider
                                                      .createBundledShipment(
                                                          selectedOrderIds);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          "تم انشاء حزمه مجمعه $bundelId")));
                                            },
                                            color: Colors.green,
                                            textColor: Colors.white,
                                            fontSize: 12.0,
                                            borderRadius: 10.0,
                                          ),
                                        // number of selected orders
                                        if (selectedOrderIds.isNotEmpty)
                                          Text(
                                              '${selectedOrderIds.length} طلبات محددة'),

                                        // ...list_btn.asMap().entries.map((entry) {
                                        //   int index = entry.key;
                                        //   String value = entry.value;
                                        //
                                        //   return CustomButton(
                                        //     text: value,
                                        //     onPressed: () async {},
                                        //     color: Colors.green,
                                        //     textColor: Colors.white,
                                        //     fontSize: 12.0,
                                        //     borderRadius: 10.0,
                                        //     // icon: Icons.check,
                                        //     iconColor: Colors.white,
                                        //     height: 30.0,
                                        //     isLoading: false,
                                        //     enabled: false,
                                        //   );
                                        // }).toList(),

                                        if (Utilities.hasPermission(
                                            "حذف الطرود"))
                                          CustomButton(
                                            text: 'حذف الطرود المحددة',
                                            onPressed: () async {
                                              final shouldDelete =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: Text('تأكيد الحذف'),
                                                  content: Text(
                                                      'هل أنت متأكد أنك تريد حذف الطرود المحددة ( ${selectedOrderIds.length} طلبات)؟ لا يمكن التراجع عن هذا الإجراء.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(false),
                                                      child: Text('إلغاء'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(true),
                                                      child: Text('حذف',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (shouldDelete == true) {
                                                appProvider.deleteOrders(
                                                    selectedOrderIds);

                                                setState(() {
                                                  selectedOrderIds.clear();
                                                });
                                              }
                                            },
                                            color: Colors.redAccent,
                                            textColor: Colors.white,
                                            fontSize: 12.0,
                                            borderRadius: 10.0,
                                            // icon: Icons.check,
                                            iconColor: Colors.white,
                                            height: 30.0,
                                            enabled:
                                                selectedOrderIds.isNotEmpty,
                                            isLoading: false,
                                          ),
                                      ],
                                    ),
                                  ),
                                _buildActiveFilters(),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        top: 20, right: 0, bottom: 5),
                                    alignment: Alignment.topRight,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Check if screen is small (mobile/tablet)
                                        bool isSmallScreen =
                                            constraints.maxWidth < 1000;

                                        if (isSmallScreen) {
                                          _isSwitched = false;

                                          // Mobile/Small screen layout with cards
                                          return _buildCardsLayout(appProvider);
                                        } else {
                                          _isSwitched = true;
                                          // Desktop layout with table
                                          return _buildTableLayout(appProvider);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )))
                  ],
                ),
              ),
            ),
            // Show pagination only on large screens
            LayoutBuilder(
              builder: (context, constraints) {
                bool isSmallScreen = constraints.maxWidth < 1000;

                if (isSmallScreen) {
                  // Don't show pagination controls on small screens
                  return const SizedBox.shrink();
                } else {
                  // Show full pagination controls on large screens
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 30),
                      child: Wrap(
                        children: [
                          CustomButton(
                            text: 'الصفحة الأولى',
                            onPressed: () {
                              _tableKey.currentState?.pageTo(0);
                            },
                            color: primary,
                            textColor: Colors.white,
                            fontSize: 14.0,
                            borderRadius: 8.0,
                            icon: Icons.first_page,
                            iconColor: Colors.white,
                            height: 40.0,
                            isLoading: false,
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text: 'الصفحة السابقة',
                            onPressed: () {
                              if (_currentPage > 0) {
                                _tableKey.currentState
                                    ?.pageTo(_currentPage - _perPage);
                              }
                            },
                            color: primary,
                            textColor: Colors.white,
                            fontSize: 14.0,
                            borderRadius: 8.0,
                            icon: Icons.navigate_before,
                            iconColor: Colors.white,
                            height: 40.0,
                            isLoading: false,
                          ),
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'الطلبات ${(_currentPage + 1)} من ${filteredOrders.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          CustomButton(
                            text: 'الصفحة التالية',
                            onPressed: () {
                              print(_currentPage);
                              print(_tableKey.currentState);
                              if (_currentPage + _perPage <
                                  filteredOrders.length) {
                                _tableKey.currentState
                                    ?.pageTo(_currentPage + _perPage);
                              }
                            },
                            color: primary,
                            textColor: Colors.white,
                            fontSize: 14.0,
                            borderRadius: 8.0,
                            icon: Icons.navigate_next,
                            iconColor: Colors.white,
                            height: 40.0,
                            isLoading: false,
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text: 'الصفحة الأخيرة',
                            onPressed: () {
                              _tableKey.currentState
                                  ?.pageTo(filteredOrders.length - 1);
                            },
                            color: primary,
                            textColor: Colors.white,
                            fontSize: 14.0,
                            borderRadius: 8.0,
                            icon: Icons.last_page,
                            iconColor: Colors.white,
                            height: 40.0,
                            isLoading: false,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            // add pagination buttons here
          ],
        ),
      );
    });
  }


  void _filterShipmentsByTab(int tabIndex) {
    setState(() {
      selectedStatus = null;
      switch (tabIndex) {
        case 0: //todo طلب تغير الدفع
          filteredOrders = [];

          break;

        case 1: // الطلبات الجديدة
          selectedStatus = "الطلبات الجديدة";
          _applyFiltersLocally();

          break;

        case 2: // بانتظار تعيين السائق
          selectedStatus = "بانتظار تعيين السائق";
          _applyFiltersLocally();

          break;

        case 3: // ملغاة
          selectedStatus = "ملغاة";
          _applyFiltersLocally();
          break;

        case 4: // تم توصيلها
          showDelivered = true;
          selectedStatus = "تم توصيلها";

          _fetchOrders();
          // _applyFiltersLocally();
          break;

        case 5: // تم إرجاعها
          selectedStatus = "تم إرجاعها";
          _applyFiltersLocally();
          break;

        case 6: // تم إرجاعها مع السائق
          filteredOrders = orders
              .where((order) =>
                  order.status == "تم إرجاعها" &&
                  order.cashPossession == CashPossession.driver)
              .toList();
          setState(() {
            selectedStatus = "تم إرجاعها";
          });

          break;

        case 7: // تم إرجاعها مع الفرع
          filteredOrders = orders
              .where((order) =>
                  order.status == "تم إرجاعها" &&
                  order.cashPossession == CashPossession.branch)
              .toList();
          setState(() {
            selectedStatus = "تم إرجاعها";
          });
          break;

        case 8: // تم إرجاعها مع الزبون
          filteredOrders = orders
              .where((order) =>
                  order.status == "تم إرجاعها" &&
                  order.cashPossession == CashPossession.customer)
              .toList();
          setState(() {
            selectedStatus = "تم إرجاعها";
          });
          break;

        case 9: // الطرود حسب مدينة المستقبل
          // Group by city
          final ordersPerCity = <String, List<Shipment>>{};

          for (var order in orders) {
            if (!ordersPerCity.containsKey(order.city)) {
              ordersPerCity[order.city] = [];
            }
            ordersPerCity[order.city]!.add(order);
          }
          filteredOrders = [];
          for (var shipmentList in ordersPerCity.keys) {
            filteredOrders.addAll(ordersPerCity[shipmentList]!);
          }

          break;

        case 10: // الطلبات المتاخرة
          final now = DateTime.now();
          filteredOrders = orders
              .where((order) =>
                  order.expectedDeliveryDate != null &&
                  order.expectedDeliveryDate!.isBefore(now) &&
                  order.status != "تم توصيلها" &&
                  order.status != "ملغاة")
              .toList();
          break;

        case 11: // الطرود المحذوفة
          // This might require additional tracking of deleted shipments
          filteredOrders =
              []; // You'll need to implement tracking of deleted shipments
          break;

        case 12: // مرجع مؤجل

          setState(() {
            selectedStatus = "تم ارجاعها";
            _notesController.text = "مرجع مؤجل";
            _limit = 100;
            showDelivered = true;
          });
          _fetchOrders();
          break;

        case 13: // في المركبة
          filteredOrders =
              orders.where((order) => order.status == "في المركبة").toList();
          break;

        case 14: //todo  تم تعديلها
          filteredOrders = [];
          break;

        default:
          filteredOrders = orders;
      }

      // Clear any previous selections when switching tabs
      selectedOrderIds.clear();
    });
  }

  DateTime? selectedDate;

  final datePickerService = DatePickerService(
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  // Build cards layout for small screens
  Widget _buildCardsLayout(AppProvider appProvider) {
    return ListView.builder(
      controller: _verticalScrollController,
      padding: const EdgeInsets.all(16),
      // Items: 0=Filters, 1..N=Orders, N+1=Pagination, N+2=BottomPadding
      itemCount: filteredOrders.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _buildMobileFilters(appProvider),
              const SizedBox(height: 16),
            ],
          );
        }

        // Orders occupy indices 1 to filteredOrders.length
        if (index > 0 && index <= filteredOrders.length) {
          final orderIndex = index - 1;
          return _buildOrderCard(filteredOrders[orderIndex], appProvider);
        }

        if (index == filteredOrders.length + 1) {
          return _buildMobilePagination();
        }

        // Last item (index == filteredOrders.length + 2)
        return const SizedBox(height: 100);
      },
    );
  }

  // Build table layout for large screens
  Widget _buildTableLayout(AppProvider appProvider) {
    return CustomScrollbar(
      verticalScrollController: _verticalScrollController,
      horizontalScrollController: _horizontalScrollController,
      contentWidth: totalWidth + 200,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: totalWidth + 200,
          child: PaginatedDataTable(
            key: _tableKey,
            onPageChanged: (pageIndex) {
              setState(() {
                _currentPage = pageIndex;
              });
            },
            arrowHeadColor: Colors.white,
            showFirstLastButtons: true,
            sortAscending: false,
            showEmptyRows: false,
            onSelectAll: (checked) {
              setState(() {
                if (checked == true) {
                  selectedOrderIds =
                      filteredOrders.map((e) => e.orderId).toSet();
                } else {
                  selectedOrderIds = {};
                }
              });
            },
            header: null,
            rowsPerPage: _perPage,
            onRowsPerPageChanged: (value) async {
              setState(() {
                _perPage = value!;
              });
            },
            showCheckboxColumn: true,
            horizontalMargin: 15,
            columnSpacing: 5,
            headingRowHeight: 100,
            dataRowMaxHeight: 70,
            columns: [
              ...columnConfigs.where((c) => c['visible']).map((config) {
                final id = config['id'];
                final width = config['width'];
                final label = config['label'];

                Widget headerWidget;
                switch (id) {
                  case 'orderId':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "ادخل رقم الطرد",
                      prefixIcon: Icons.numbers,
                      controller: _orderIdController,
                    );
                    break;
                  case 'weight':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "ادخل الوزن",
                      prefixIcon: Icons.scale,
                      controller: _weightController,
                    );
                    break;
                  case 'price':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "ادخل الاجور",
                      prefixIcon: Icons.monetization_on_outlined,
                      controller: _priceController,
                    );
                    break;
                  case 'cod':
                    headerWidget = Center(child: Text(label));
                    break;
                  case 'customer':
                    headerWidget = SearchableDropdown<String>(
                      searchController: _customerSearchController,
                      label: label,
                      prefixIcon: Icons.person_outline,
                      value: selectedCustomer,
                      items:
                          appProvider.customers.map((e) => e.username).toList(),
                      onClearPressed: () {
                        setState(() {
                          selectedCustomer = null;
                          _fetchOrders();
                        });
                      },
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCustomer = newValue!;
                          _fetchOrders();
                        });
                      },
                    );
                    break;
                  case 'driver':
                    headerWidget = SearchableDropdown<String>(
                      searchController: _driverSearchController,
                      label: label,
                      prefixIcon: Icons.person_outline,
                      value: selectedDriver,
                      items: _getVisibleDrivers(appProvider)
                          .map((e) => e.username ?? '')
                          .where((name) => name.isNotEmpty)
                          .toList(),
                      onClearPressed: () {
                        setState(() {
                          selectedDriver = null;
                          _applyFiltersLocally();
                        });
                      },
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDriver = newValue!;
                          _applyFiltersLocally();
                        });
                      },
                    );
                    break;
                  case 'phone':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "ادخل رقم الهاتف",
                      prefixIcon: Icons.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onTap: () async {
                        setState(() {
                          _limit = 400;
                        });
                        await _fetchOrders();
                      },
                      onEditingComplete: (String? value) {
                        _phoneController.text = value!;
                        _fetchOrders();
                      },
                    );
                    break;
                  case 'secondaryPhone':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "هاتف احتياطي",
                      prefixIcon: Icons.phone_android,
                      controller: _secondaryPhoneController,
                      keyboardType: TextInputType.phone,
                    );
                    break;
                  case 'sender':
                    headerWidget = CompositedTransformTarget(
                      link: _layerLink,
                      child: CustomTextField(
                        readOnly: true,
                        onTap: () {
                          setState(() {
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                            if (_overlayEntry == null) {
                              _showOverlaySender(context);
                            }
                          });
                        },
                        labelText: label,
                        hintText: "ادخل اسم المرسل",
                        prefixIcon: Icons.person_outline,
                        controller: _senderNameController,
                      ),
                    );
                    break;
                  case 'recipientName':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "اسم المستقبل",
                      prefixIcon: Icons.person_outline,
                      controller: _recipientNameController,
                    );
                    break;
                  case 'recipientCity':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "المدينة",
                      prefixIcon: Icons.location_city,
                      controller: _recipientCityController,
                    );
                    break;
                  case 'recipientArea':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "المنطقة",
                      prefixIcon: Icons.map_outlined,
                      controller: _recipientAreaController,
                    );
                    break;
                  case 'recipient':
                    headerWidget = CompositedTransformTarget(
                      link: _layerLinkRecipient,
                      child: CustomTextField(
                        readOnly: true,
                        onTap: () {
                          setState(() {
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                            if (_overlayEntry == null) {
                              _showOverlayRecipient(
                                  context, appProvider.citiesAndPlacesNames);
                            }
                          });
                        },
                        labelText: label,
                        hintText: "ادخل اسم المستقبل",
                        prefixIcon: Icons.person_outline,
                        controller: _recipientNameController,
                      ),
                    );
                    break;
                  case 'status':
                    headerWidget = CustomDropdown(
                      labelText: label,
                      prefixIcon: Icons.info_outline,
                      value: selectedStatus,
                      items: statusOptions.keys.toList(),
                      childRow: true,
                      onClearPressed: () {
                        setState(() {
                          selectedStatus = null;
                          _applyFiltersLocally();
                        });
                      },
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedStatus = newValue!;
                          _applyFiltersLocally();
                        });
                      },
                    );
                    break;
                  case 'tracking':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "رقم الإرسالية",
                      prefixIcon: Icons.local_shipping_outlined,
                      controller: _trackingNumberController,
                    );
                    break;
                  case 'paymentMethod':
                    headerWidget = CustomDropdown(
                      labelText: label,
                      prefixIcon: Icons.payment,
                      value: selectedPaymentMethod,
                      items: paymentMethods,
                      onClearPressed: () {
                        setState(() {
                          selectedPaymentMethod = null;
                          _applyFiltersLocally();
                        });
                      },
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPaymentMethod = newValue!;
                          _applyFiltersLocally();
                        });
                      },
                    );
                    break;
                  case 'collectionMethod':
                    headerWidget = CustomDropdown(
                      labelText: label,
                      prefixIcon: Icons.account_balance_wallet,
                      value: selectedCollectionMethod,
                      items: collectionMethods,
                      onClearPressed: () {
                        setState(() {
                          selectedCollectionMethod = null;
                          _applyFiltersLocally();
                        });
                      },
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCollectionMethod = newValue!;
                          _applyFiltersLocally();
                        });
                      },
                    );
                    break;
                  case 'bookingDate':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "تاريخ الحجز",
                      prefixIcon: Icons.calendar_today,
                      controller: _bookingDateController,
                      onTap: () => _selectDate(context, _bookingDateController),
                      readOnly: true,
                    );
                    break;
                  case 'deliveryDate':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "تاريخ التوصيل",
                      prefixIcon: Icons.calendar_today,
                      controller: _deliveryDateController,
                      onTap: () =>
                          _selectDate(context, _deliveryDateController),
                      readOnly: true,
                    );
                    break;
                  case 'expectedDeliveryDate':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "تاريخ متوقع",
                      prefixIcon: Icons.calendar_today,
                      controller: _expectedDeliveryDateController,
                      onTap: () =>
                          _selectDate(context, _expectedDeliveryDateController),
                      readOnly: true,
                    );
                    break;
                  case 'lastStatusDate':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "اخر حالة",
                      prefixIcon: Icons.calendar_today,
                      controller: _lastStatusDateController,
                      onTap: () =>
                          _selectDate(context, _lastStatusDateController),
                      readOnly: true,
                    );
                    break;
                  case 'postponementDate':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "تاريخ التأجيل",
                      prefixIcon: Icons.calendar_today,
                      controller: _postponementDateController,
                      onTap: () =>
                          _selectDate(context, _postponementDateController),
                      readOnly: true,
                    );
                    break;
                  case 'notes':
                    headerWidget = CustomTextField(
                      labelText: label,
                      hintText: "ادخل ملاحظات",
                      prefixIcon: Icons.note,
                      controller: _notesController,
                    );
                    break;
                  default:
                    headerWidget = Text(label);
                }

                return DataColumn(
                  label: SizedBox(
                    width: width,
                    child: headerWidget,
                  ),
                );
              }),
            ],
            source: _ShipmentDataTableSource(
              filteredOrders,
              context,
              selectedOrderIds,
              columnConfigs,
              (orderId, checked) {
                setState(() {
                  if (checked) {
                    if (_isRangeSelectionMode && _lastSelectedOrderId != null) {
                      int currentIndex = filteredOrders
                          .indexWhere((element) => element.orderId == orderId);
                      int lastIndex = filteredOrders.indexWhere(
                          (element) => element.orderId == _lastSelectedOrderId);

                      if (currentIndex != -1 && lastIndex != -1) {
                        int start =
                            currentIndex < lastIndex ? currentIndex : lastIndex;
                        int end =
                            currentIndex > lastIndex ? currentIndex : lastIndex;

                        for (int i = start; i <= end; i++) {
                          selectedOrderIds.add(filteredOrders[i].orderId);
                        }
                      } else {
                        selectedOrderIds.add(orderId);
                      }
                    } else {
                      selectedOrderIds.add(orderId);
                    }
                    _lastSelectedOrderId = orderId;
                  } else {
                    selectedOrderIds.remove(orderId);
                  }
                });
              },
              (order) {
                showSideDrawerDialog(
                  context: context,
                  side: DrawerSide.left,
                  width: MediaQuery.of(context).size.width > 850
                      ? 850
                      : MediaQuery.of(context).size.width,
                  child: ShipmentDetails(shipment: order),
                );
              },
              (order) {
                showSideDrawerDialog(
                  context: context,
                  side: DrawerSide.left,
                  width: MediaQuery.of(context).size.width > 850
                      ? 850
                      : MediaQuery.of(context).size.width,
                  child: ShipmentDetails(shipment: order),
                );
              },
              showChangeStatusBottomSheet,
              appProvider,
            ),
          ),
        ),
      ),
    );
  }

  // Build mobile filters
  Widget _buildMobileFilters(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  labelText: "رقم الطرد",
                  hintText: "ادخل رقم الطرد",
                  prefixIcon: Icons.numbers,
                  controller: _orderIdController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextField(
                  labelText: 'هاتف المستقبل',
                  hintText: "ادخل رقم الهاتف",
                  prefixIcon: Icons.phone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SearchableDropdown<String>(
                  searchController: _customerSearchController,
                  label: 'الزبون',
                  prefixIcon: Icons.person_outline,
                  value: selectedCustomer,
                  items: appProvider.customers.map((e) => e.username).toList(),
                  onClearPressed: () {
                    setState(() {
                      selectedCustomer = null;
                      _fetchOrders();
                    });
                  },
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCustomer = newValue!;
                      _fetchOrders();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomDropdown(
                  labelText: 'الحالة',
                  prefixIcon: Icons.info_outline,
                  value: selectedStatus,
                  items: statusOptions.keys.toList(),
                  onClearPressed: () {
                    setState(() {
                      selectedStatus = null;
                      _applyFiltersLocally();
                    });
                  },
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                      _applyFiltersLocally();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('فلاتر إضافية',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            childrenPadding: EdgeInsets.zero,
            tilePadding: EdgeInsets.zero,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      labelText: "المستقبل",
                      hintText: "اسم المستقبل",
                      prefixIcon: Icons.person_outline,
                      controller: _recipientNameController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      labelText: "المدينة",
                      hintText: "المدينة",
                      prefixIcon: Icons.location_city,
                      controller: _recipientCityController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      labelText: "المنطقة",
                      hintText: "المنطقة",
                      prefixIcon: Icons.map_outlined,
                      controller: _recipientAreaController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      labelText: "اسم المرسل",
                      hintText: "اسم المرسل",
                      prefixIcon: Icons.person,
                      controller: _senderNameController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  // Build order card
  Widget _buildOrderCard(Shipment order, AppProvider appProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with checkbox and order ID
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getStatusColor(order.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selectedOrderIds.contains(order.orderId),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedOrderIds.add(order.orderId);
                      } else {
                        selectedOrderIds.remove(order.orderId);
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'طرد رقم: ${order.orderId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCardInfoRow(
                        'الزبون',
                        order.username?.isNotEmpty == true
                            ? order.username!
                            : 'غير محدد',
                        Icons.person,
                      ),
                    ),
                    Expanded(
                      child: _buildCardInfoRow(
                        'السائق',
                        order.driverName?.isNotEmpty == true
                            ? order.driverName!
                            : 'غير معين',
                        Icons.local_shipping,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardInfoRow(
                        'المستقبل',
                        order.recipientName,
                        Icons.person_outline,
                      ),
                    ),
                    Expanded(
                      child: _buildCardInfoRow(
                        'المدينة',
                        order.city,
                        Icons.location_city,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardInfoRow(
                        'الوزن',
                        '${order.weight} كغ',
                        Icons.scale,
                      ),
                    ),
                    Expanded(
                      child: _buildCardInfoRow(
                        'السعر',
                        '${order.deliveryCost} دينار',
                        Icons.monetization_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardInfoRow(
                        'COD',
                        '${order.codAmount} JOD',
                        Icons.payment,
                      ),
                    ),
                    Expanded(
                      child: _buildCardInfoRow(
                        'الهاتف',
                        order.phoneNumber,
                        Icons.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showChangeStatusBottomSheet(
context: context,
                            shipment: order,
                            appProvider: appProvider,
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('تغيير الحالة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showSideDrawerDialog(
                            context: context,
                            side: DrawerSide.left,
                            width: MediaQuery.of(context).size.width > 850
                                ? 850
                                : MediaQuery.of(context).size.width,
                            child: ShipmentDetails(shipment: order),
                          );
                        },
                        icon: const Icon(Icons.info, size: 16),
                        label: const Text('التفاصيل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build card info row
  Widget _buildCardInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build mobile pagination
  Widget _buildMobilePagination() {
    // Only show if user scrolled near bottom and there are more orders to load
    if (!_showLoadMoreButton) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: CustomButton(
          text: 'عرض المزيد',
          onPressed: () {
            _fetchMoreOrders(40);
          },
          color: primary,
          textColor: Colors.white,
          fontSize: 16.0,
          borderRadius: 10.0,
          icon: Icons.expand_more,
          iconColor: Colors.white,
          height: 45.0,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}

class _ShipmentDataTableSource extends DataTableSource {
  final List<Shipment> orders;
  final BuildContext context;
  final Set<String> selectedOrderIds;
  final Function(String, bool) onCheckboxChanged;
  final Function(Shipment) onRowSelected;
  final Function(Shipment) onRowLongPressed;
  final Function({required BuildContext context,Shipment? shipment, required AppProvider appProvider})
      showFutureDetailsBottomSheet;
  final AppProvider appProvider;
  final List<Map<String, dynamic>> columnConfigs;

  _ShipmentDataTableSource(
    this.orders,
    this.context,
    this.selectedOrderIds,
    this.columnConfigs,
    this.onCheckboxChanged,
    this.onRowSelected,
    this.onRowLongPressed,
    this.showFutureDetailsBottomSheet,
    this.appProvider,
  );

  @override
  DataRow? getRow(int index) {
    if (index >= orders.length) return null;
    final order = orders[index];

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (!order.isAddressed) {
          return Colors.red.withOpacity(0.05);
        }
        return null;
      }),
      onLongPress: () => onRowLongPressed(order),
      selected: selectedOrderIds.contains(order.orderId),
      onSelectChanged: (checked) {
        onCheckboxChanged(order.orderId, checked ?? false);
      },
      cells: [
        ...columnConfigs.where((c) => c['visible']).map((config) {
          final id = config['id'];
          final width = config['width'];

          Widget cellWidget;
          switch (id) {
            case 'orderId':
              cellWidget = Customtext(title: order.orderId);
              break;
            case 'weight':
              cellWidget = Customtext(title: order.weight.toString());
              break;
            case 'price':
              cellWidget = Center(
                child: CounterTextFormField(
                  initialValue: order.deliveryCost,
                  min: 0,
                  max: 100,
                  step: .25,
                  isInteger: false,
                  onChanged: (value) {
                    appProvider.updateOrderPrice(
                      order.orderId,
                      double.parse(order.deliveryCost.toString()),
                      double.parse(value),
                      order.userId,
                    );
                  },
                ),
              );
              break;
            case 'cod':
              cellWidget = Customtext(title: "${order.codAmount} JOD");
              break;
            case 'customer':
              cellWidget = Customtext(title: order.username ?? '');
              break;
            case 'driver':
              cellWidget = Customtext(title: order.driverName ?? 'غير معين');
              break;
            case 'phone':
              cellWidget = Customtext(title: order.phoneNumber);
              break;
            case 'secondaryPhone':
              cellWidget = Customtext(title: order.secondaryPhoneNumber ?? '');
              break;
            case 'sender':
              cellWidget = Customtext(
                  title:
                      "${order.senderName ?? order.username}\n${order.userphone}");
              break;
            case 'recipientName':
              cellWidget = Customtext(title: order.recipientName);
              break;
            case 'recipientCity':
              cellWidget = Customtext(title: order.city);
              break;
            case 'recipientArea':
              cellWidget =
                  Customtext(title: _getDistrict(order.addressDescription));
              break;
            case 'status':
              cellWidget = Center(
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Customtext(
                        color: Colors.white,
                        title: order.status,
                      ),
                    ),
                    getSubText(order.status, order)
                  ],
                ),
              );
              break;
            case 'tracking':
              cellWidget = Customtext(title: order.trackingNumber);
              break;
            case 'paymentMethod':
              cellWidget = Customtext(title: order.paymentMethod);
              break;
            case 'collectionMethod':
              cellWidget = Customtext(title: order.collectionMethod);
              break;
            case 'bookingDate':
              cellWidget = Customtext(title: order.createdAt.toString());
              break;
            case 'deliveryDate':
              cellWidget =
                  Customtext(title: order.deliveryDate?.toString() ?? '');
              break;
            case 'expectedDeliveryDate':
              cellWidget = Customtext(
                  title: order.expectedDeliveryDate?.toString() ?? '');
              break;
            case 'lastStatusDate':
              cellWidget = Customtext(title: order.lastUpdated.toString());
              break;
            case 'postponementDate':
              cellWidget =
                  Customtext(title: order.postponementDate?.toString() ?? '');
              break;
            case 'notes':
              cellWidget = Customtext(title: order.notes);
              break;
            case 'actions':
             
                cellWidget = PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  tooltip: 'الإجراءات',
                  onSelected: (value) {
                    if (value == 'changeStatus') {
                      showFutureDetailsBottomSheet(
                        context: context,
                        shipment: order,
                        appProvider: appProvider,
                      );
                    } else if (value == 'assignDriver') {
                      showDriverAssignmentDialog(context, appProvider.drivers)
                          .then((driver) {
                        if (driver != null) {
                          appProvider.assignDriver(order.orderId, driver);
                        }
                      });

                    } else if (value == 'واصل bx') {
                     appProvider.updateIsCompanyDeliveryFeePaid(order.orderId, true);
                   
                      
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'changeStatus',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('تغير الحاله'),
                        ],
                      ),
                    ),
                    if (order.status == 'الطلبات الجديدة')
                    const PopupMenuItem<String>(
                      value: 'assignDriver',
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('تعيين سائق'),
                        ],
                      ),
                    ),
                    if (order.paymentMethod == 'مدفوعة مسبقا' && !order.isCompanyDeliveryFeePaid)
                    const PopupMenuItem<String>(
                      value: 'واصل bx',
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('واصل bx'),
                        ],
                      ),
                    ),
                  ],
                );
             
              break;
            default:
              cellWidget = Text('');
          }

          return DataCell(
            SizedBox(width: width, child: cellWidget),
            onTap: id == 'status'
                ? () => showFutureDetailsBottomSheet(
                  context: context,
                    shipment: order, appProvider: appProvider)
                : null,
          );
        }),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => orders.length;

  @override
  int get selectedRowCount => selectedOrderIds.length;

  String _getDistrict(String addressDescription) {
    if (addressDescription.isEmpty) return '';
    var parts = addressDescription.split(' - ');
    return parts.isNotEmpty ? parts[0] : '';
  }
}

Widget getSubText(String status, Shipment shipment) {
  switch (status) {
    case 'تم توصيلها':
      return Text('قيمه الطرد مع:' + shipment.cashPossession.nameAr);
    case 'على الرفوف':
      return Text('الطرد على الرف:' + shipment.shelfName.toString());
    case 'تم إرجاعها':
      return Text('تم إرجاع الطرد مع: ${shipment.orderPossession.nameAr}');
    default:
      return SizedBox.shrink();
  }
}

class _ResponsiveBody extends StatelessWidget {
  final Widget child;
  final ScrollController controller;

  const _ResponsiveBody({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use standard desktop breakpoint
        if (constraints.maxWidth >= 1000) {
          // On desktop, let the child (Table) expand to fill available space
          // and handle its own scrolling. No outer constraints or scroll view.
          return child;
        } else {
          // On mobile, wrap in SingleChildScrollView and ConstrainedBox as before
          return SingleChildScrollView(
            controller: controller,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 1200, maxHeight: 2000),
              child: child,
            ),
          );
        }
      },
    );
  }
}
