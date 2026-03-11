import '../../models/customer.dart';
import '../../models/Driver.dart';
import '../../models/PriceCalculators.dart';
import '../../models/Shipment.dart';
import '../ManageShipments/widget/SearchableDropdown.dart';
import '../../shared/PrintHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../shared/appProvider.dart';
import '../../shared/constants.dart';

class ShipmentData {
  // Form Controllers
  final TextEditingController deliveryCostController = TextEditingController();
  final TextEditingController addressDescController = TextEditingController();
  final TextEditingController recipientNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codAmountController = TextEditingController();
  final TextEditingController trackingNumberController =
      TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController citySearchController = TextEditingController();

  // Focus Nodes
  final FocusNode recipientNameFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode citySearchFocus = FocusNode();
  final FocusNode addressDescFocus = FocusNode();
  final FocusNode deliveryCostFocus = FocusNode();
  final FocusNode codAmountFocus = FocusNode();
  final FocusNode weightFocus = FocusNode();
  final FocusNode contentFocus = FocusNode();
  final FocusNode notesFocus = FocusNode();

  // City search state
  List<String> filteredCities = [];
  int selectedCityIndex = -1;
  bool showCitySuggestions = false;

  // Form State
  String? selectedCity;
  String? selectedCityPlace;
  String selectedPaymentMethod = 'إحضار';
  String selectedCollectionMethod = 'كاش';
  String selectedServiceType = 'اعتيادي';
  String selectedPickupLocation = 'من عنوان الزبون';
  int parcelCount = 1;
  DateTime? deliveryDate;
  DateTime? expectedDeliveryDate;
  PackageAttributes packageAttributes = PackageAttributes(
    isFragile: false,
    needsPackaging: false,
    hasDangerousMaterials: false,
    isNonOpenable: false,
    canBeFolded: false,
    measurementForbidden: false,
  );
  Map<String, int> selectedInventoryItems = {};
  bool showInventorySection = false;

  void dispose() {
    deliveryCostController.dispose();
    addressDescController.dispose();
    recipientNameController.dispose();
    phoneController.dispose();
    codAmountController.dispose();
    trackingNumberController.dispose();
    contentController.dispose();
    weightController.dispose();
    notesController.dispose();
    citySearchController.dispose();

    // Dispose focus nodes
    recipientNameFocus.dispose();
    phoneFocus.dispose();
    citySearchFocus.dispose();
    addressDescFocus.dispose();
    deliveryCostFocus.dispose();
    codAmountFocus.dispose();
    weightFocus.dispose();
    contentFocus.dispose();
    notesFocus.dispose();
  }

  void reset() {
    deliveryCostController.clear();
    addressDescController.clear();
    recipientNameController.clear();
    phoneController.clear();
    codAmountController.clear();
    trackingNumberController.clear();
    contentController.clear();
    weightController.clear();
    notesController.clear();
    citySearchController.clear();

    selectedCity = null;
    selectedCityPlace = null;
    selectedPaymentMethod = 'إحضار';
    selectedCollectionMethod = 'كاش';
    selectedServiceType = 'اعتيادي';
    selectedPickupLocation = 'من عنوان الزبون';
    parcelCount = 1;
    deliveryDate = null;
    expectedDeliveryDate = null;
    packageAttributes = PackageAttributes(
      isFragile: false,
      needsPackaging: false,
      hasDangerousMaterials: false,
      isNonOpenable: false,
      canBeFolded: false,
      measurementForbidden: false,
    );
    selectedInventoryItems.clear();
    showInventorySection = false;

    // Reset city search state
    filteredCities.clear();
    selectedCityIndex = -1;
    showCitySuggestions = false;
  }
}

class AddOrderForm extends StatefulWidget {
  final Shipment? shipment;
  final bool isEditMode;
  final bool isWhatsapp;
  const AddOrderForm(
      {Key? key,
      this.shipment,
      this.isWhatsapp = false,
      this.isEditMode = false})
      : super(key: key);

  @override
  AddOrderFormState createState() => AddOrderFormState();
}

class AddOrderFormState extends State<AddOrderForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditMode = false;
  String _submitAction = 'save_and_close';

  // Multiple shipments support
  List<ShipmentData> shipments = [];
  int currentShipmentIndex = 0;

  // Package Attributes
  late PackageAttributes packageAttributes;

  // Selected inventory items
  Map<String, int> selectedInventoryItems = {};
  bool showInventorySection = false;

  // Form Controllers
  final TextEditingController deliveryCostController = TextEditingController();
  final TextEditingController addressDescController = TextEditingController();
  final TextEditingController recipientNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codAmountController = TextEditingController();
  final TextEditingController trackingNumberController =
      TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Add search controllers
  final TextEditingController citySearchController = TextEditingController();
  final TextEditingController paymentMethodSearchController =
      TextEditingController();
  final TextEditingController collectionMethodSearchController =
      TextEditingController();
  final TextEditingController serviceTypeSearchController =
      TextEditingController();
  final TextEditingController customerSearchController =
      TextEditingController();
  final TextEditingController driverSearchController = TextEditingController();

  // Form State
  String? selectedCity;
  String? selectedCityPlace;

  String selectedPaymentMethod = 'إحضار';
  String selectedShelevs = '1';
  String selectedCollectionMethod = 'كاش';
  String selectedServiceType = 'اعتيادي';
  String selectedPickupLocation = 'من عنوان الزبون';
  int parcelCount = 1;
  DateTime? deliveryDate;
  DateTime? expectedDeliveryDate;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.isEditMode;
    _initializeFormData();
    // Initialize with one shipment
    if (shipments.isEmpty) {
      _addNewShipment();
    }
  }

  void _initializeFormData() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (widget.shipment != null) {
      final shipment = widget.shipment!;
      final customers = appProvider.customers
          .where((customer) => customer.userid == shipment.userId)
          .toList();
      if (customers.isNotEmpty) {
        appProvider.selectedCustomer = customers.first;
      }
      selectedPickupLocation =
          shipment.driverId != null ? 'مع السائق' : 'في الفرع';

      if (shipment.driverId != null) {
        final drivers = appProvider.drivers
            .where((driver) => driver.userid == shipment.driverId)
            .toList();
        if (drivers.isNotEmpty) {
          appProvider.selectedDriver = drivers.first;
        }
      }

      // Initialize package attributes
      packageAttributes = shipment.packageAttributes;
//add shelevs
      selectedShelevs = shipment.shelf?.toString() ?? '1';
      // Populate form controllers
      deliveryCostController.text = shipment.deliveryCost.toString();
      addressDescController.text = shipment.addressDescription;
      recipientNameController.text = shipment.recipientName;
      phoneController.text = shipment.phoneNumber;
      codAmountController.text = shipment.codAmount.toString();
      trackingNumberController.text = shipment.trackingNumber;
      contentController.text = shipment.contents;
      weightController.text = shipment.weight.toString();
      notesController.text = shipment.notes;
      if (shipment.selectedItems != null) {
        selectedInventoryItems = shipment.selectedItems!;
        showInventorySection = true;
      }

      // Set dropdown values
      setState(() {
        selectedCity = shipment.city.split(' ')[0];
        if (appProvider.citiesAndPlacesNames.contains(shipment.city)) {
          selectedCityPlace = shipment.city;
        }
        if (paymentMethods.contains(shipment.paymentMethod)) {
          selectedPaymentMethod = shipment.paymentMethod;
        }
        if (collectionMethods.contains(shipment.collectionMethod)) {
          selectedCollectionMethod = shipment.collectionMethod;
        }

        if (serviceTypes.contains(shipment.serviceType)) {
          selectedServiceType = shipment.serviceType;
        }
        parcelCount = shipment.parcelCount;
        deliveryDate = shipment.deliveryDate;
        expectedDeliveryDate = shipment.expectedDeliveryDate;
      });
    } else {
      // Initialize with default values for new orders
      packageAttributes = PackageAttributes(
        isFragile: false,
        needsPackaging: false,
        hasDangerousMaterials: false,
        isNonOpenable: false,
        canBeFolded: false,
        measurementForbidden: false,
      );
    }
  }

  @override
  void dispose() {
    // Dispose all shipment controllers
    for (var shipment in shipments) {
      shipment.dispose();
    }
    citySearchController.dispose();
    paymentMethodSearchController.dispose();
    collectionMethodSearchController.dispose();
    serviceTypeSearchController.dispose();
    customerSearchController.dispose();
    driverSearchController.dispose();
    super.dispose();
  }

  void _addNewShipment() {
    setState(() {
      shipments.add(ShipmentData());
      currentShipmentIndex = shipments.length - 1;
    });
  }

  void _removeShipment(int index) {
    if (shipments.length > 1) {
      setState(() {
        shipments[index].dispose();
        shipments.removeAt(index);
        if (currentShipmentIndex >= shipments.length) {
          currentShipmentIndex = shipments.length - 1;
        }
      });
    }
  }

  void _selectShipment(int index) {
    setState(() {
      currentShipmentIndex = index;
    });
  }

  ShipmentData get _currentShipment => shipments[currentShipmentIndex];

  void _handleSubmit(AppProvider appProvider) {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<Shipment> shipmentDataList = [];

      for (int i = 0; i < shipments.length; i++) {
        final shipment = shipments[i];
        String initialStatus;
        Map<String, dynamic> driverInfo = {};

        switch (shipment.selectedPickupLocation) {
          case 'من عنوان الزبون':
            initialStatus = 'الطلبات الجديدة';
            break;
          case 'مع السائق':
            if (appProvider.selectedDriver == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء اختيار السائق')));
              return;
            }
            initialStatus = 'في المركبة';
            driverInfo = {
              'driverId': appProvider.selectedDriver!.userid,
              'driverName': appProvider.selectedDriver!.username,
            };
            break;
          case 'في الفرع':
            initialStatus = 'في الفرع';
            break;
          default:
            initialStatus = 'الطلبات الجديدة';
        }

        final shipmentData = Shipment(
            orderId: _isEditMode
                ? widget.shipment!.orderId
                : DateTime.now()
                        .millisecondsSinceEpoch
                        .toString()
                        .replaceRange(0, 2, '') +
                    '$i',
            username: appProvider.selectedCustomer?.username,
            userId: appProvider.selectedCustomer?.userid,
            profileImageUrl: appProvider.selectedCustomer?.profileImage,
            driverId: _isEditMode
                ? widget.shipment!.driverId
                : driverInfo['driverId'],
            driverName: _isEditMode
                ? widget.shipment!.driverName
                : driverInfo['driverName'],
            packageAttributes: shipment.packageAttributes,
            deliveryCost: double.parse(shipment.deliveryCostController.text),
            collectionMethod: shipment.selectedCollectionMethod,
            recipientName: shipment.recipientNameController.text.trim(),
            phoneNumber: shipment.phoneController.text.trim(),
            city: shipment.selectedCityPlace ?? '',
            addressDescription: shipment.addressDescController.text.trim(),
            paymentMethod: shipment.selectedPaymentMethod,
            codAmount: double.parse(shipment.codAmountController.text),
            serviceType: shipment.selectedServiceType,
            trackingNumber: shipment.trackingNumberController.text.trim(),
            contents: shipment.contentController.text.trim(),
            weight: double.tryParse(shipment.weightController.text) ?? 0,
            notes: shipment.notesController.text.trim(),
            parcelCount: shipment.parcelCount,
            userphone: appProvider.selectedCustomer?.phoneNumber,
            customerlocation: appProvider.selectedCustomer?.city,
            status: _isEditMode ? widget.shipment!.status : initialStatus,
            createdAt:
                _isEditMode ? widget.shipment!.createdAt : DateTime.now(),
            lastUpdated: DateTime.now(),
            deliveryDate: shipment.deliveryDate,
            expectedDeliveryDate: shipment.expectedDeliveryDate ??
                DateTime.now().add(Duration(days: 3)),
            cashPossession: _isEditMode
                ? widget.shipment!.cashPossession
                : CashPossession.receiver,
            orderPossession: _isEditMode
                ? widget.shipment!.orderPossession
                : OrderPossession.receiver,
            logs: _isEditMode
                ? [
                    ...widget.shipment!.logs,
                    ShipmentLog(
                        date: DateTime.now(),
                        text: 'تم تحديث الشحنة',
                        status: initialStatus,
                        userName:
                            FirebaseAuth.instance.currentUser?.displayName ??
                                "مجهول")
                  ]
                : [
                    ShipmentLog(
                        date: DateTime.now(),
                        text: 'تمت إضافة الشحنة',
                        status: 'الطلبات الجديدة',
                        userName:
                            FirebaseAuth.instance.currentUser?.displayName ??
                                "مجهول")
                  ],
            selectedItems: shipment.showInventorySection
                ? shipment.selectedInventoryItems
                : null,
            isShipmentWithItems: shipment.showInventorySection);

        shipmentDataList.add(shipmentData);
      }

      // Save all shipments
      for (var shipmentData in shipmentDataList) {
        if (_isEditMode) {
          appProvider.updateOrder(shipmentData.toMap());
        } else {
          appProvider.addOrder(shipmentData.toMap());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'تم ${_isEditMode ? 'تحديث' : 'إضافة'} ${shipmentDataList.length} شحنة بنجاح')));
      }

      // Handle different submit actions
      switch (_submitAction) {
        case 'save_and_print':
          PrintHandler().printShipmentReceipt(shipmentDataList);
          appProvider.selectedCustomer = null;
          appProvider.selectedCityPlace = null;
          appProvider.selectedDriver = null;
          Navigator.pop(context);
          break;
        case 'save_and_close':
          appProvider.selectedCustomer = null;
          appProvider.selectedCityPlace = null;
          appProvider.selectedDriver = null;
          Navigator.pop(context);
          break;
        case 'save_and_continue':
          // Clear all shipments and add a new one
          for (var shipment in shipments) {
            shipment.dispose();
          }
          shipments.clear();
          _addNewShipment();
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        bool isMobile = MediaQuery.of(context).size.width < 600;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: background,
            width: isMobile
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width * .70,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildShipmentTabs(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 8 : 16),
                      child: Column(
                        children: [
                          _buildSenderSection(appProvider),
                          SizedBox(height: isMobile ? 12 : 20),
                          _buildShipmentRows(appProvider),
                          SizedBox(height: isMobile ? 12 : 20),
                          _buildAddShipmentButton(),
                          SizedBox(height: isMobile ? 12 : 20),
                          _buildSubmitButton(appProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShipmentTabs() {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 50 : 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: shipments.length,
              itemBuilder: (context, index) {
                final isSelected = index == currentShipmentIndex;
                return GestureDetector(
                  onTap: () => _selectShipment(index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 16,
                        vertical: isMobile ? 3 : 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'شحنة ${index + 1}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 9 : 14,
                          ),
                        ),
                        if (shipments.length > 1) ...[
                          SizedBox(width: 3),
                          GestureDetector(
                            onTap: () => _removeShipment(index),
                            child: Icon(
                              Icons.close,
                              size: isMobile ? 10 : 16,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentRows(AppProvider appProvider) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    bool isVerySmallDesktop = MediaQuery.of(context).size.width < 800;

    return Column(
      children: [
        // Header row - only show on desktop and not very small screens
        if (!isMobile && !isVerySmallDesktop) ...[
          _buildShipmentHeaderRow(),
          SizedBox(height: 16),
        ],
        // Shipment rows
        ...List.generate(shipments.length, (index) {
          return _buildSingleShipmentRow(index, appProvider);
        }),
      ],
    );
  }

  Widget _buildShipmentHeaderRow() {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 4 : 12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('اسم المستلم',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 2,
                  child: Text('رقم الجوال',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 2,
                  child: Text('المدينة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 2,
                  child: Text('وصف العنوان',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 1,
                  child: Text('سعر التوصيل',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 1,
                  child: Text('التحصيل',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 1,
                  child: Text('الوزن',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 1,
                  child: Text('المحتويات',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 1,
                  child: Text('الملاحظات',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 1,
                  child: Text('الإجراءات',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                  child: Text('موقع الاستلام',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primary,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 2,
                  child: Text('من الزبون',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 2,
                  child: Text('مع السائق',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 2,
                  child: Text('في الفرع',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(
                  flex: 2,
                  child: Text('السائق (إذا كان مع السائق)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 7 : 12))),
              Expanded(flex: 3, child: SizedBox()), // Empty space for alignment
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleShipmentRow(int index, AppProvider appProvider) {
    final shipment = shipments[index];
    bool isMobile = MediaQuery.of(context).size.width < 600;
    bool isVerySmallDesktop = MediaQuery.of(context).size.width < 800;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 4 : 8),
      padding: EdgeInsets.all(isMobile ? 6 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pickup location selection
          _buildPickupLocationRow(shipment, appProvider),
          SizedBox(height: isMobile ? 6 : 12),

          if (isMobile || isVerySmallDesktop)
            // Mobile layout - vertical fields
            _buildMobileShipmentFields(shipment, index)
          else
            // Desktop layout - horizontal fields
            _buildDesktopShipmentFields(shipment, index),
        ],
      ),
    );
  }

  Widget _buildMobileShipmentFields(ShipmentData shipment, int index) {
    return Column(
      children: [
        // Row 1: Name and Phone
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: shipment.recipientNameController,
                focusNode: shipment.recipientNameFocus,
                decoration: InputDecoration(
                  hintText: 'اسم المستلم',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 12),
                onFieldSubmitted: (value) {
                  shipment.phoneFocus.requestFocus();
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !value.startsWith('07') ||
                      value.length != 10 ||
                      !value.contains(new RegExp(r'^[0-9]+$'))) {
                    return 'رقم الجوال يجب أن يبدأ بالرقم 07 ويتكون من 10 أرقام فقط';
                  }
                  return null;
                },
                controller: shipment.phoneController,
                focusNode: shipment.phoneFocus,
                decoration: InputDecoration(
                  hintText: 'رقم الجوال',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 12),
                onFieldSubmitted: (value) {
                  shipment.citySearchFocus.requestFocus();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Row 2: City and Address
        Row(
          children: [
            Expanded(
              child: _buildCitySearchField(
                  shipment, Provider.of<AppProvider>(context, listen: false)),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: shipment.addressDescController,
                focusNode: shipment.addressDescFocus,
                decoration: InputDecoration(
                  hintText: 'وصف العنوان',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 12),
                onFieldSubmitted: (value) {
                  shipment.deliveryCostFocus.requestFocus();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Row 3: Delivery Cost and COD Amount
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: shipment.deliveryCostController,
                focusNode: shipment.deliveryCostFocus,
                decoration: InputDecoration(
                  hintText: 'سعر التوصيل',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 12),
                onFieldSubmitted: (value) {
                  shipment.codAmountFocus.requestFocus();
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: shipment.codAmountController,
                focusNode: shipment.codAmountFocus,
                decoration: InputDecoration(
                  hintText: 'التحصيل',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 12),
                onFieldSubmitted: (value) {
                  shipment.weightFocus.requestFocus();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Row 4: Weight and Content
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: shipment.weightController,
                focusNode: shipment.weightFocus,
                decoration: InputDecoration(
                  hintText: 'الوزن',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 12),
                onFieldSubmitted: (value) {
                  shipment.contentFocus.requestFocus();
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: shipment.contentController,
                focusNode: shipment.contentFocus,
                decoration: InputDecoration(
                  hintText: 'المحتويات',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
                style: TextStyle(fontSize: 12),
                onFieldSubmitted: (value) {
                  shipment.notesFocus.requestFocus();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Row 5: Notes and Actions
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: shipment.notesController,
                focusNode: shipment.notesFocus,
                decoration: InputDecoration(
                  hintText: 'الملاحظات',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: false,
                  hintStyle: TextStyle(fontSize: 12),
                ),
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.done,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(width: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (shipments.length > 1)
                  IconButton(
                    onPressed: () => _removeShipment(index),
                    icon: Icon(Icons.delete, color: Colors.red, size: 16),
                    tooltip: 'حذف الشحنة',
                    padding: EdgeInsets.all(2),
                    constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                IconButton(
                  onPressed: () => _selectShipment(index),
                  icon: Icon(Icons.edit, color: primary, size: 16),
                  tooltip: 'تعديل الشحنة',
                  padding: EdgeInsets.all(2),
                  constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopShipmentFields(ShipmentData shipment, int index) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 1200;
    bool isVerySmallScreen = MediaQuery.of(context).size.width < 1000;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: shipment.recipientNameController,
            focusNode: shipment.recipientNameFocus,
            decoration: InputDecoration(
              hintText: 'اسم المستلم',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              shipment.phoneFocus.requestFocus();
            },
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: shipment.phoneController,
            focusNode: shipment.phoneFocus,
            decoration: InputDecoration(
              hintText: 'رقم الجوال',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            textAlign: TextAlign.right,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              shipment.citySearchFocus.requestFocus();
            },
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 2,
          child: _buildCitySearchField(
              shipment, Provider.of<AppProvider>(context, listen: false)),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: shipment.addressDescController,
            focusNode: shipment.addressDescFocus,
            decoration: InputDecoration(
              hintText: 'وصف العنوان',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              shipment.deliveryCostFocus.requestFocus();
            },
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: shipment.deliveryCostController,
            focusNode: shipment.deliveryCostFocus,
            decoration: InputDecoration(
              hintText: 'سعر التوصيل',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              shipment.codAmountFocus.requestFocus();
            },
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: shipment.codAmountController,
            focusNode: shipment.codAmountFocus,
            decoration: InputDecoration(
              hintText: 'التحصيل',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              shipment.weightFocus.requestFocus();
            },
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: shipment.weightController,
            focusNode: shipment.weightFocus,
            decoration: InputDecoration(
              hintText: 'الوزن',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              shipment.contentFocus.requestFocus();
            },
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: shipment.contentController,
            focusNode: shipment.contentFocus,
            decoration: InputDecoration(
              hintText: 'المحتويات',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (value) {
              shipment.notesFocus.requestFocus();
            },
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: shipment.notesController,
            focusNode: shipment.notesFocus,
            decoration: InputDecoration(
              hintText: 'الملاحظات',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16),
                  vertical: 12),
              isDense: false,
            ),
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.done,
          ),
        ),
        SizedBox(width: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shipments.length > 1)
                IconButton(
                  onPressed: () => _removeShipment(index),
                  icon: Icon(Icons.delete,
                      color: Colors.red,
                      size: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                  tooltip: 'حذف الشحنة',
                  padding: EdgeInsets.all(
                      isVerySmallScreen ? 1 : (isSmallScreen ? 2 : 4)),
                  constraints: BoxConstraints(
                      minWidth:
                          isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                      minHeight:
                          isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32)),
                ),
              IconButton(
                onPressed: () => _selectShipment(index),
                icon: Icon(Icons.edit,
                    color: primary,
                    size: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                tooltip: 'تعديل الشحنة',
                padding: EdgeInsets.all(
                    isVerySmallScreen ? 1 : (isSmallScreen ? 2 : 4)),
                constraints: BoxConstraints(
                    minWidth:
                        isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                    minHeight:
                        isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickupLocationRow(
      ShipmentData shipment, AppProvider appProvider) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('موقع الاستلام:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildPickupLocationButton(
                  'من الزبون',
                  shipment.selectedPickupLocation == 'من عنوان الزبون',
                  () => setState(() =>
                      shipment.selectedPickupLocation = 'من عنوان الزبون'),
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildPickupLocationButton(
                  'مع السائق',
                  shipment.selectedPickupLocation == 'مع السائق',
                  () => setState(
                      () => shipment.selectedPickupLocation = 'مع السائق'),
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildPickupLocationButton(
                  'في الفرع',
                  shipment.selectedPickupLocation == 'في الفرع',
                  () => setState(
                      () => shipment.selectedPickupLocation = 'في الفرع'),
                ),
              ),
            ],
          ),
          if (shipment.selectedPickupLocation == 'مع السائق') ...[
            SizedBox(height: 6),
            SearchableDropdown<Driver>(
              label: 'السائق',
              value: appProvider.selectedDriver,
              items: appProvider.drivers,
              onChanged: (value) =>
                  setState(() => appProvider.selectedDriver = value),
              searchController: driverSearchController,
              hint: 'اختر السائق',
            ),
          ],
        ],
      );
    } else {
      return Row(
        children: [
          Text('موقع الاستلام:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildPickupLocationButton(
                    'من الزبون',
                    shipment.selectedPickupLocation == 'من عنوان الزبون',
                    () => setState(() =>
                        shipment.selectedPickupLocation = 'من عنوان الزبون'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPickupLocationButton(
                    'مع السائق',
                    shipment.selectedPickupLocation == 'مع السائق',
                    () => setState(
                        () => shipment.selectedPickupLocation = 'مع السائق'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPickupLocationButton(
                    'في الفرع',
                    shipment.selectedPickupLocation == 'في الفرع',
                    () => setState(
                        () => shipment.selectedPickupLocation = 'في الفرع'),
                  ),
                ),
              ],
            ),
          ),
          if (shipment.selectedPickupLocation == 'مع السائق') ...[
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SearchableDropdown<Driver>(
                label: 'السائق',
                value: appProvider.selectedDriver,
                items: appProvider.drivers,
                onChanged: (value) =>
                    setState(() => appProvider.selectedDriver = value),
                searchController: driverSearchController,
                hint: 'اختر السائق',
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildPickupLocationButton(
      String text, bool isSelected, VoidCallback onTap) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: isMobile ? 3 : 8, horizontal: isMobile ? 4 : 12),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: isMobile ? 8 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAddShipmentButton() {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addNewShipment,
        icon: Icon(Icons.add, size: isMobile ? 14 : 20),
        label: Text(
          'إضافة شحنة جديدة',
          style: TextStyle(fontSize: isMobile ? 10 : 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 6 : 16,
            horizontal: isMobile ? 4 : 16,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildCitySearchField(ShipmentData shipment, AppProvider appProvider) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (shipment.showCitySuggestions &&
                  shipment.filteredCities.isNotEmpty) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  setState(() {
                    shipment.selectedCityIndex =
                        (shipment.selectedCityIndex + 1) %
                            shipment.filteredCities.length;
                  });
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  setState(() {
                    shipment.selectedCityIndex = shipment.selectedCityIndex <= 0
                        ? shipment.filteredCities.length - 1
                        : shipment.selectedCityIndex - 1;
                  });
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                  if (shipment.selectedCityIndex >= 0 &&
                      shipment.selectedCityIndex <
                          shipment.filteredCities.length) {
                    _selectCity(
                        shipment,
                        shipment.filteredCities[shipment.selectedCityIndex],
                        appProvider);
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                  setState(() {
                    shipment.showCitySuggestions = false;
                    shipment.selectedCityIndex = -1;
                  });
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: TextFormField(
            controller: shipment.citySearchController,
            focusNode: shipment.citySearchFocus,
            validator: (value) {
              print(appProvider.citiesAndPlacesNames);
              if (value!.isEmpty) {
                return 'الرجاء ادخال المدينة';
              }
              if (!appProvider.citiesAndPlacesNames.contains(value)) {
                return 'الرجاء ادخال المدينة بشكل صحيح';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن المدينة',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: isMobile ? 8 : 12),
              suffixIcon: Icon(Icons.search, size: isMobile ? 14 : 16),
              isDense: false,
              hintStyle: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: isMobile ? 12 : 14),
            onChanged: (value) {
              setState(() {
                shipment.selectedCityPlace = value;
                if (value.isNotEmpty) {
                  shipment.selectedCity = value.split(" ")[0];
                  // Filter cities based on search
                  shipment.filteredCities = appProvider.citiesAndPlacesNames
                      .where((city) =>
                          city.toLowerCase().contains(value.toLowerCase()))
                      .take(5)
                      .toList();
                  shipment.showCitySuggestions =
                      shipment.filteredCities.isNotEmpty;
                  shipment.selectedCityIndex = -1;
                } else {
                  shipment.showCitySuggestions = false;
                  shipment.selectedCityIndex = -1;
                }
              });
              calculateDeliveryCost(appProvider);
            },
            onFieldSubmitted: (value) {
              if (shipment.selectedCityIndex >= 0 &&
                  shipment.selectedCityIndex < shipment.filteredCities.length) {
                _selectCity(
                    shipment,
                    shipment.filteredCities[shipment.selectedCityIndex],
                    appProvider);
              } else {
                // If no city is selected, move to next field
                shipment.addressDescFocus.requestFocus();
              }
            },
            onTap: () {
              setState(() {
                if (shipment.citySearchController.text.isNotEmpty) {
                  shipment.showCitySuggestions =
                      shipment.filteredCities.isNotEmpty;
                }
              });
            },
          ),
        ),
        if (shipment.showCitySuggestions) ...[
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: shipment.filteredCities.asMap().entries.map((entry) {
                int index = entry.key;
                String city = entry.value;
                bool isSelected = index == shipment.selectedCityIndex;

                return Container(
                  color: isSelected
                      ? primary.withOpacity(0.1)
                      : Colors.transparent,
                  child: ListTile(
                    title: Text(
                      city,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isSelected ? primary : Colors.black,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: isMobile ? 9 : 14,
                      ),
                    ),
                    onTap: () => _selectCity(shipment, city, appProvider),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  void _selectCity(
      ShipmentData shipment, String city, AppProvider appProvider) {
    setState(() {
      shipment.citySearchController.text = city;
      shipment.selectedCityPlace = city;
      shipment.selectedCity = city.split(" ")[0];
      shipment.showCitySuggestions = false;
      shipment.selectedCityIndex = -1;
    });
    calculateDeliveryCost(appProvider);
  }

  Widget _buildSenderSection(AppProvider appProvider) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 6 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: primary, size: isMobile ? 14 : 20),
                SizedBox(width: 4),
                Text(
                  'معلومات المرسل',
                  style: TextStyle(
                      fontSize: isMobile ? 10 : 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 16),
            SearchableDropdown<Customer>(
              label: 'المتجر/الزبون',
              value: appProvider.selectedCustomer,
              items: appProvider.customers,
              onChanged: (value) {
                setState(() => appProvider.selectedCustomer = value);
                calculateDeliveryCost(appProvider);
              },
              searchController: customerSearchController,
              hint: 'اختر المتجر/الزبون',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppProvider appProvider) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 16),
          ),
          onPressed: _isLoading ? null : () => _handleSubmit(appProvider),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    'إرسال',
                    style: TextStyle(fontSize: isMobile ? 12 : 16),
                  ),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        // Radio buttons
        if (isMobile)
          // Mobile layout - vertical radio buttons
          Column(
            children: [
              ListTile(
                title: Text('حفظ وطباعة', style: TextStyle(fontSize: 12)),
                leading: Radio<String>(
                  value: 'save_and_print',
                  groupValue: _submitAction,
                  onChanged: (String? value) {
                    setState(() => _submitAction = value!);
                  },
                  activeColor: primary,
                ),
              ),
              ListTile(
                title: Text('حفظ وإغلاق', style: TextStyle(fontSize: 12)),
                leading: Radio<String>(
                  value: 'save_and_close',
                  groupValue: _submitAction,
                  onChanged: (String? value) {
                    setState(() => _submitAction = value!);
                  },
                  activeColor: primary,
                ),
              ),
              ListTile(
                title:
                    Text('حفظ ومتابعة الإضافة', style: TextStyle(fontSize: 12)),
                leading: Radio<String>(
                  value: 'save_and_continue',
                  groupValue: _submitAction,
                  onChanged: (String? value) {
                    setState(() => _submitAction = value!);
                  },
                  activeColor: primary,
                ),
              ),
            ],
          )
        else
          // Desktop layout - horizontal radio buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('حفظ وطباعة'),
                      leading: Radio<String>(
                        value: 'save_and_print',
                        groupValue: _submitAction,
                        onChanged: (String? value) {
                          setState(() => _submitAction = value!);
                        },
                        activeColor: primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('حفظ وإغلاق'),
                      leading: Radio<String>(
                        value: 'save_and_close',
                        groupValue: _submitAction,
                        onChanged: (String? value) {
                          setState(() => _submitAction = value!);
                        },
                        activeColor: primary,
                      ),
                    ),
                  ),
                ],
              ),
              ListTile(
                title: Text('حفظ ومتابعة الإضافة'),
                leading: Radio<String>(
                  value: 'save_and_continue',
                  groupValue: _submitAction,
                  onChanged: (String? value) {
                    setState(() => _submitAction = value!);
                  },
                  activeColor: primary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void calculateDeliveryCost(AppProvider appProvider) {
    if (_currentShipment.selectedCity != null &&
        appProvider.selectedCustomer != null) {
      // Find customer-specific shipping route

      UserShippingRoute? customerRoute =
          appProvider.userShippingRoutes.firstWhere(
        (route) => route.userId == appProvider.selectedCustomer!.userid,
        orElse: () => appProvider.userShippingRoutes
            .firstWhere((route) => route.userId == 'main'),
      );

      // Find matching route for selected city
      ShippingRoute? matchingRoute = customerRoute.shippingRoute.firstWhere(
        (route) =>
            route.to == _currentShipment.selectedCity &&
            route.from == appProvider.selectedCustomer!.city,
        orElse: () {
          // If no customer-specific route found, try main route
          UserShippingRoute mainRoute = appProvider.userShippingRoutes
              .firstWhere((route) => route.userId == 'main');
          return mainRoute.shippingRoute.firstWhere(
              (route) =>
                  route.to == _currentShipment.selectedCity &&
                  route.from == appProvider.selectedCustomer!.city, orElse: () {
            UserShippingRoute mainRoute = appProvider.userShippingRoutes
                .firstWhere((route) => route.userId == 'main');
            return mainRoute.shippingRoute.firstWhere(
                (route) =>
                    route.to == appProvider.selectedCustomer!.city &&
                    route.from == _currentShipment.selectedCity, orElse: () {
              return ShippingRoute(
                from: '',
                to: '',
                deliveryPrice: 0,
                returnPrice: 0,
                returnBeforeDeliveryPrice: 0,
              );
            });
          });
        },
      );

      if (matchingRoute.deliveryPrice > 0) {
        setState(() {
          _currentShipment.deliveryCostController.text =
              matchingRoute.deliveryPrice.toString();
        });
      }
    }
  }
}
