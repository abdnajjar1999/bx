import '../../models/customer.dart';
import '../../models/Driver.dart';

import '../../models/Shipment.dart';
import '../ManageShipments/widget/SearchableDropdown.dart';
import '../../shared/PrintHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../shared/appProvider.dart';
import '../../sadrad/colors.dart';
import '../../shared/constants.dart';
import '../../models/City.dart';

const Color primary = SadradColors.primary;
const Color background = SadradColors.background;

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
  String? selectedRegion;
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
    selectedRegion = null;
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
  String? selectedRegion;
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
      // تنظيف النص من أي مسافات زائدة لضمان التقسيم الصحيح
      String fullCityName = shipment.city.replaceAll(RegExp(r'\s+'), ' ').trim();
      bool splitFound = false;
      
      // Try to match against known cities first
      for (var city in appProvider.cities) {
        if (fullCityName.startsWith("$city ")) {
          selectedCity = city;
          selectedRegion = fullCityName.substring(city.length + 1).trim();
          citySearchController.text = selectedCity!;
          splitFound = true;
          break;
        }
      }
      
      if (!splitFound) {
        if (fullCityName.contains(' ')) {
          int spaceIndex = fullCityName.indexOf(' '); // Split at first space instead of last
          selectedCity = fullCityName.substring(0, spaceIndex);
          selectedRegion = fullCityName.substring(spaceIndex + 1);
          citySearchController.text = selectedCity!;
        } else {
          selectedCity = fullCityName;
          selectedRegion = null;
          citySearchController.text = selectedCity ?? '';
        }
      }
      
      if (shipment.selectedItems != null) {
        selectedInventoryItems = shipment.selectedItems!;
        showInventorySection = true;
      }

      // Set dropdown values
      setState(() {
        // Fix: Removed selectedCity = shipment.city; which was overwriting the split result
        if (appProvider.citiesAndPlacesNames.contains(shipment.city)) {
          selectedCityPlace = shipment.city;
        } else {
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
                  _buildHeader(context),
                  _buildShipmentTabs(),
                  _buildBulkSummary(appProvider),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 12 : 24),
                      child: Column(
                        children: [
                          _buildSenderSection(appProvider),
                          const SizedBox(height: 24),
                          _buildShipmentRows(appProvider),
                          const SizedBox(height: 32),
                          _buildAddShipmentButton(),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActions(appProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.grid_view_rounded, color: primary, size: 28),
          const SizedBox(width: 12),
          const Text(
            'إضافة طلبات بالجملة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: SadradColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkSummary(AppProvider appProvider) {
    double totalCod = 0;
    for (var s in shipments) {
      totalCod += double.tryParse(s.codAmountController.text) ?? 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100),
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          _buildSummaryItem('عدد الشحنات', '${shipments.length}',
              Icons.local_shipping_outlined),
          _buildSummaryDivider(),
          _buildSummaryItem('إجمالي التحصيل',
              '${totalCod.toStringAsFixed(2)} JOD', Icons.payments_outlined),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: SadradColors.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: SadradColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildShipmentTabs() {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 50 : 66,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: shipments.length,
        itemBuilder: (context, index) {
          final isSelected = index == currentShipmentIndex;
          return GestureDetector(
            onTap: () => _selectShipment(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? primary : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'شحنة ${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : SadradColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (shipments.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeShipment(index),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isSelected ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShipmentRows(AppProvider appProvider) {
    return Column(
      children: List.generate(shipments.length, (index) {
        return _buildSingleShipmentRow(index, appProvider);
      }),
    );
  }

  Widget _buildSingleShipmentRow(int index, AppProvider appProvider) {
    final shipment = shipments[index];
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of the shipment card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: primary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'تفاصيل الشحنة',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                ),
                const Spacer(),
                if (shipments.length > 1)
                  IconButton(
                    onPressed: () => _removeShipment(index),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    tooltip: 'حذف هذه الشحنة',
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPickupLocationRow(shipment, appProvider),
                const SizedBox(height: 24),
                isMobile
                    ? _buildMobileShipmentFields(shipment, index)
                    : _buildDesktopShipmentFields(shipment, index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: primary.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
          onFieldSubmitted: (_) => nextFocus?.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildAddShipmentButton() {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addNewShipment,
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: const Text(
          'إضافة شحنة أخرى لهذه القائمة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }


  Widget _buildCitySearchField(ShipmentData shipment, AppProvider appProvider) {
    return SearchableDropdown<String>(
      label: 'المدينة',
      value: shipment.selectedCity,
      items: appProvider.cities,
      onChanged: (value) {
        setState(() {
          shipment.selectedCity = value;
          shipment.selectedRegion = null;
          shipment.selectedCityPlace = value;
          shipment.citySearchController.text = value ?? '';
        });
        calculateDeliveryCost(appProvider, specificShipment: shipment);
      },
      searchController: shipment.citySearchController,
      hint: 'اختر المدينة',
    );
  }


  Widget _buildRegionDropdown(dynamic target, AppProvider appProvider) {
    String? city = target is ShipmentData ? target.selectedCity : selectedCity;
    String? region =
        target is ShipmentData ? target.selectedRegion : selectedRegion;

    List<String> items = [];
    if (city != null) {
      try {
        items = appProvider.citiesAndPlaces
            .firstWhere((c) => c.name == city)
            .places;
      } catch (e) {
        // Fallback or empty
      }
    }

    return SearchableDropdown<String>(
      label: 'المنطقة',
      value: region,
      items: items,
      onChanged: (value) {
        setState(() {
          if (target is ShipmentData) {
            target.selectedRegion = value;
            target.selectedCityPlace =
                (target.selectedCity ?? "") + " " + (value ?? "");
          } else {
            selectedRegion = value;
            selectedCityPlace = (selectedCity ?? "") + " " + (value ?? "");
          }
        });
      },
      searchController: TextEditingController(),
      hint: 'المنطقة',
    );
  }



  Widget _buildPickupLocationRow(ShipmentData shipment, AppProvider appProvider) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'موقع استلام الشحنة',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        isMobile
            ? Column(
                children: [
                  _buildPickupLocationButton(
                    icon: Icons.person_outline,
                    title: 'من الزبون',
                    subtitle: 'استلام من موقع المرسل',
                    isSelected:
                        shipment.selectedPickupLocation == 'من عنوان الزبون',
                    onTap: () => setState(() =>
                        shipment.selectedPickupLocation = 'من عنوان الزبون'),
                  ),
                  const SizedBox(height: 10),
                  _buildPickupLocationButton(
                    icon: Icons.local_shipping_outlined,
                    title: 'مع السائق',
                    subtitle: 'السائق يستلم الشحنة',
                    isSelected: shipment.selectedPickupLocation == 'مع السائق',
                    onTap: () => setState(
                        () => shipment.selectedPickupLocation = 'مع السائق'),
                  ),
                  const SizedBox(height: 10),
                  _buildPickupLocationButton(
                    icon: Icons.store_outlined,
                    title: 'في الفرع',
                    subtitle: 'تسليم في فرع الشركة',
                    isSelected: shipment.selectedPickupLocation == 'في الفرع',
                    onTap: () => setState(
                        () => shipment.selectedPickupLocation = 'في الفرع'),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildPickupLocationButton(
                      icon: Icons.person_outline,
                      title: 'من الزبون',
                      subtitle: 'من موقع المرسل',
                      isSelected:
                          shipment.selectedPickupLocation == 'من عنوان الزبون',
                      onTap: () => setState(() =>
                          shipment.selectedPickupLocation = 'من عنوان الزبون'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickupLocationButton(
                      icon: Icons.local_shipping_outlined,
                      title: 'مع السائق',
                      subtitle: 'استلام خارجي',
                      isSelected: shipment.selectedPickupLocation == 'مع السائق',
                      onTap: () => setState(
                          () => shipment.selectedPickupLocation = 'مع السائق'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickupLocationButton(
                      icon: Icons.store_outlined,
                      title: 'في الفرع',
                      subtitle: 'تسليم للفرع',
                      isSelected: shipment.selectedPickupLocation == 'في الفرع',
                      onTap: () => setState(
                          () => shipment.selectedPickupLocation = 'في الفرع'),
                    ),
                  ),
                ],
              ),
        if (shipment.selectedPickupLocation == 'مع السائق') ...[
          const SizedBox(height: 20),
          SearchableDropdown<Driver>(
            label: 'اختر السائق المستلم',
            value: appProvider.selectedDriver,
            items: appProvider.drivers,
            onChanged: (value) =>
                setState(() => appProvider.selectedDriver = value),
            searchController: driverSearchController,
            hint: 'ابحث عن اسم السائق...',
          ),
        ],
      ],
    );
  }

  Widget _buildPickupLocationButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primary : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? primary.withOpacity(0.05) : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? primary : Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? primary.withOpacity(0.7)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileShipmentFields(ShipmentData shipment, int index) {
    return Column(
      children: [
        _buildModernTextField(
          controller: shipment.recipientNameController,
          focusNode: shipment.recipientNameFocus,
          hint: 'اسم المستلم الثلاثي',
          label: 'اسم المستلم',
          icon: Icons.person_outline,
          nextFocus: shipment.phoneFocus,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: shipment.phoneController,
          focusNode: shipment.phoneFocus,
          hint: '07XXXXXXXX',
          label: 'رقم الجوال',
          icon: Icons.phone_android_outlined,
          keyboardType: TextInputType.phone,
          nextFocus: shipment.citySearchFocus,
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                !value.startsWith('07') ||
                value.length != 10 ||
                !value.contains(RegExp(r'^[0-9]+$'))) {
              return 'رقم الجوال يجب أن يبدأ بالرقم 07 ويتكون من 10 أرقام فقط';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildCitySearchField(
            shipment, Provider.of<AppProvider>(context, listen: false)),
        const SizedBox(height: 16),
        _buildRegionDropdown(
            shipment, Provider.of<AppProvider>(context, listen: false)),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: shipment.addressDescController,
          focusNode: shipment.addressDescFocus,
          hint: 'مثال: قرب مسجد التقوى، عمارة رقم 5',
          label: 'وصف العنوان التفصيلي',
          icon: Icons.location_on_outlined,
          nextFocus: shipment.codAmountFocus,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: shipment.codAmountController,
                focusNode: shipment.codAmountFocus,
                hint: '0.00',
                label: 'المبلغ المطلوب (COD)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                nextFocus: shipment.deliveryCostFocus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernTextField(
                controller: shipment.deliveryCostController,
                focusNode: shipment.deliveryCostFocus,
                hint: '0.00',
                label: 'سعر التوصيل',
                icon: Icons.local_shipping_outlined,
                keyboardType: TextInputType.number,
                nextFocus: shipment.weightFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: shipment.weightController,
                focusNode: shipment.weightFocus,
                hint: '1.0',
                label: 'الوزن (كغم)',
                icon: Icons.fitness_center_outlined,
                keyboardType: TextInputType.number,
                nextFocus: shipment.contentFocus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernTextField(
                controller: shipment.contentController,
                focusNode: shipment.contentFocus,
                hint: 'مثال: ملابس، إلكترونيات',
                label: 'محتويات الشحنة',
                icon: Icons.inventory_2_outlined,
                nextFocus: shipment.notesFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: shipment.notesController,
          focusNode: shipment.notesFocus,
          hint: 'أي ملاحظات إضافية للسائق...',
          label: 'ملاحظات إضافية',
          icon: Icons.note_add_outlined,
        ),
      ],
    );
  }

  Widget _buildDesktopShipmentFields(ShipmentData shipment, int index) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: shipment.recipientNameController,
                focusNode: shipment.recipientNameFocus,
                hint: 'اسم المستلم الثلاثي',
                label: 'اسم المستلم',
                icon: Icons.person_outline,
                nextFocus: shipment.phoneFocus,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: shipment.phoneController,
                focusNode: shipment.phoneFocus,
                hint: '07XXXXXXXX',
                label: 'رقم الجوال',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                nextFocus: shipment.citySearchFocus,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !value.startsWith('07') ||
                      value.length != 10 ||
                      !value.contains(RegExp(r'^[0-9]+$'))) {
                    return 'رقم الجوال يجب أن يبدأ بالرقم 07 ويتكون من 10 أرقام فقط';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCitySearchField(
                  shipment, Provider.of<AppProvider>(context, listen: false)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRegionDropdown(
                  shipment, Provider.of<AppProvider>(context, listen: false)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildModernTextField(
                controller: shipment.addressDescController,
                focusNode: shipment.addressDescFocus,
                hint: 'وصف العنوان التفصيلي (الشارع، البناية، رقم الشقة)',
                label: 'العنوان بالتفصيل',
                icon: Icons.location_on_outlined,
                nextFocus: shipment.codAmountFocus,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: shipment.codAmountController,
                focusNode: shipment.codAmountFocus,
                hint: '0.00',
                label: 'المبلغ COD',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                nextFocus: shipment.deliveryCostFocus,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: shipment.deliveryCostController,
                focusNode: shipment.deliveryCostFocus,
                hint: '0.00',
                label: 'التوصيل',
                icon: Icons.local_shipping_outlined,
                keyboardType: TextInputType.number,
                nextFocus: shipment.weightFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: shipment.weightController,
                focusNode: shipment.weightFocus,
                hint: '1.0',
                label: 'الوزن',
                icon: Icons.fitness_center_outlined,
                keyboardType: TextInputType.number,
                nextFocus: shipment.contentFocus,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildModernTextField(
                controller: shipment.contentController,
                focusNode: shipment.contentFocus,
                hint: 'ماذا يوجد داخل الشحنة؟',
                label: 'المحتويات',
                icon: Icons.inventory_2_outlined,
                nextFocus: shipment.notesFocus,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildModernTextField(
                controller: shipment.notesController,
                focusNode: shipment.notesFocus,
                hint: 'ملاحظات خاصة بالتسليم...',
                label: 'ملاحظات إضافية',
                icon: Icons.note_add_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSenderSection(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store_outlined, color: primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'معلومات المرسل (المتجر)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SearchableDropdown<Customer>(
            label: 'اختر المتجر أو الزبون',
            value: appProvider.selectedCustomer,
            items: appProvider.customers,
            onChanged: (value) {
              setState(() => appProvider.selectedCustomer = value);
              calculateDeliveryCost(appProvider);
            },
            searchController: customerSearchController,
            hint: 'ابحث عن اسم المتجر أو رقم الهاتـف...',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppProvider appProvider) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          isMobile
              ? Column(
                  children: [
                    _buildModernRadio(
                      title: 'حفظ وطباعة البوليصة',
                      value: 'save_and_print',
                    ),
                    _buildModernRadio(
                      title: 'حفظ وإغلاق النموذج',
                      value: 'save_and_close',
                    ),
                    _buildModernRadio(
                      title: 'حفظ ومتابعة الإضافة',
                      value: 'save_and_continue',
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildModernRadio(
                        title: 'حفظ وطباعة',
                        value: 'save_and_print',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernRadio(
                        title: 'حفظ وإغلاق',
                        value: 'save_and_close',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernRadio(
                        title: 'حفظ ومتابعة',
                        value: 'save_and_continue',
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleSubmit(appProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'تأكيد وإرسال الطلبات الآن',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRadio({required String title, required String value}) {
    bool isSelected = _submitAction == value;
    return InkWell(
      onTap: () => setState(() => _submitAction = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? primary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primary : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void calculateDeliveryCost(AppProvider appProvider, {ShipmentData? specificShipment}) {
    if (appProvider.selectedCustomer == null) return;
    // تحديد الطلبات التي سنحسب تكلفتها (طلب واحد أو الجميع)
    List<ShipmentData> targets = specificShipment != null ? [specificShipment] : shipments;
    for (var shipment in targets) {
      String? cityName = shipment.selectedCity;
      if (cityName == null || cityName.isEmpty) continue;
      try {
        // جلب السعر عبر المحرك المركزي
        double price = appProvider.calculateDeliveryCostForCity(
          cityName, 
          appProvider.selectedCustomer!.userid
        );
        setState(() {
          // تحديث السعر في الطلب المحدد
          shipment.deliveryCostController.text = price > 0 ? price.toString() : "";
        });
      } catch (e) {
        print("Error in calculateDeliveryCost: $e");
      }
    }
  }

}
