import '../../main.dart';
import '../../models/customer.dart';
import '../../models/Inventory.dart';
import '../../models/Driver.dart';
import '../../models/Shipment.dart';
import '../../shared/constants.dart';
import '../ManageShipments/widget/SearchableDropdown.dart';
import '../../shared/PrintHelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../models/supply_order.dart';
import '../../models/City.dart';
import '../../shared/appProvider.dart';

class AddOrderFormOne extends StatefulWidget {
  final Shipment? shipment;
  final bool isWhatsapp;
  final bool isEditMode;
  const AddOrderFormOne(
      {Key? key,
      this.shipment,
      this.isWhatsapp = false,
      this.isEditMode = false})
      : super(key: key);

  @override
  AddOrderFormState createState() => AddOrderFormState();
}

class AddOrderFormState extends State<AddOrderFormOne> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditMode = false;
  String _submitAction = 'save_and_close';

  // Package Attributes
  late PackageAttributes packageAttributes;

  // Selected inventory items
  Map<String, int> selectedInventoryItems = {};
  bool showInventorySection = false;

  // Supply orders
  List<SupplyOrder> _availableSupplyOrders = [];
  Map<String, int> _selectedSupplyQuantities = {};

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

  // Focus nodes for sequential field navigation
  final FocusNode _regionFocusNode = FocusNode();
  final FocusNode _addressDescFocusNode = FocusNode();

  // Form State
  String? selectedCity;
  String? selectedRegion;
  String? selectedCityPlace;

  String selectedPaymentMethod = 'COD';
  String selectedCollectionMethod = 'كاش';
  String selectedServiceType = 'اعتيادي';
  String selectedPickupLocation = 'من عنوان الزبون';
  String? selectedPackageType = 'العادية';
  int parcelCount = 1;
  DateTime? deliveryDate;
  DateTime? expectedDeliveryDate;

  // New states for payment logic
  bool isDeliveryFeeOnRecipient = true;
  bool isCompanyDeliveryFeePaid = false;
  bool isPayToRecipient = false;
  bool hasUnclosedOrders = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.shipment != null;
    _initializeFormData();
    if (kDebugMode) {
      _fillDummyData();
    }
  }

  void _fillDummyData() {
    if (kDebugMode) {
      deliveryCostController.text = "15";
      addressDescController.text = "شارع مكة، عمارة 10، الطابق الثاني";
      recipientNameController.text = "محمد أحمد";
      phoneController.text = "0791234567";
      codAmountController.text = "150";
      trackingNumberController.text =
          "${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      contentController.text = "ملابس وأحذية";
      weightController.text = "2.5";
      notesController.text = "الرجاء الاتصال قبل التوصيل بنصف ساعة";

      setState(() {
        parcelCount = 2;
        selectedPaymentMethod = 'COD';
        selectedCollectionMethod = 'كاش';
        selectedServiceType = 'اعتيادي';
      });
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
        if (shipment.city.contains(' ')) {
          int spaceIndex = shipment.city.lastIndexOf(' ');
          selectedCity = shipment.city.substring(0, spaceIndex);
          selectedRegion = shipment.city.substring(spaceIndex + 1);
        } else {
          selectedCity = shipment.city;
          selectedRegion = null;
        }
        selectedCityPlace = shipment.city;
        if (paymentMethods.contains(shipment.paymentMethod)) {
          selectedPaymentMethod = shipment.paymentMethod;
        }
        if (collectionMethods.contains(shipment.collectionMethod)) {
          selectedCollectionMethod = shipment.collectionMethod;
        }

        if (serviceTypes.contains(shipment.serviceType)) {
          selectedServiceType = shipment.serviceType;
        }
        parcelCount = shipment.parcelCount ?? 1;
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
      isDeliveryFeeOnRecipient = true;
      isCompanyDeliveryFeePaid = false;
      isPayToRecipient = false;
    }
  }

  @override
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
    paymentMethodSearchController.dispose();
    collectionMethodSearchController.dispose();
    serviceTypeSearchController.dispose();
    customerSearchController.dispose();
    driverSearchController.dispose();
    _regionFocusNode.dispose();
    _addressDescFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(AppProvider appProvider) {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String initialStatus;
      Map<String, dynamic> driverInfo = {};

      switch (selectedPickupLocation) {
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
                  .replaceRange(0, 2, ''),
          username: appProvider.selectedCustomer?.username,
          userId: appProvider.selectedCustomer?.userid,
          profileImageUrl: appProvider.selectedCustomer?.profileImage,
          driverId:
              _isEditMode ? widget.shipment!.driverId : driverInfo['driverId'],
          driverName: _isEditMode
              ? widget.shipment!.driverName
              : driverInfo['driverName'],
          packageAttributes: packageAttributes,
          deliveryCost: double.parse(deliveryCostController.text),
          collectionMethod: selectedCollectionMethod,
          recipientName: recipientNameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          city: selectedCityPlace ?? '',
          addressDescription: addressDescController.text.trim(),
          paymentMethod: selectedPaymentMethod,
          codAmount: double.parse(codAmountController.text),
          serviceType: selectedServiceType,
          trackingNumber: trackingNumberController.text.trim(),
          contents: contentController.text.trim(),
          weight: double.tryParse(weightController.text) ?? 0,
          notes: notesController.text.trim(),
          parcelCount: parcelCount,
          userphone: appProvider.selectedCustomer?.phoneNumber,
          customerlocation: appProvider.selectedCustomer?.city,
          status: _isEditMode ? widget.shipment!.status : initialStatus,
          createdAt: _isEditMode ? widget.shipment!.createdAt : DateTime.now(),
          lastUpdated: DateTime.now(),
          deliveryDate: deliveryDate,
          expectedDeliveryDate:
              expectedDeliveryDate ?? DateTime.now().add(Duration(days: 3)),
          orderPossession: _isEditMode
              ? widget.shipment!.orderPossession
              : OrderPossession.receiver,
          cashPossession: _isEditMode
              ? widget.shipment!.cashPossession
              : CashPossession.receiver,
          isDeliveryFeeOnRecipient: isDeliveryFeeOnRecipient,
          isCompanyDeliveryFeePaid: isCompanyDeliveryFeePaid,
          isPayToRecipient: isPayToRecipient,
          hasReturn: (selectedPaymentMethod == 'تبديل' ||
              selectedPaymentMethod == 'إحضار'),
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
          selectedItems: showInventorySection ? selectedInventoryItems : null,
          isShipmentWithItems: showInventorySection);

      if (_isEditMode) {
        // Build a specific update map for editing to avoid overwriting status or concurrent logs
        Map<String, dynamic> updateMap = {
          'orderId': shipmentData.orderId,
          'username': shipmentData.username,
          'userId': shipmentData.userId,
          'profileImageUrl': shipmentData.profileImageUrl,
          'driverId': shipmentData.driverId,
          'driverName': shipmentData.driverName,
          'packageAttributes': shipmentData.packageAttributes.toMap(),
          'deliveryCost': shipmentData.deliveryCost,
          'collectionMethod': shipmentData.collectionMethod,
          'recipientName': shipmentData.recipientName,
          'phoneNumber': shipmentData.phoneNumber,
          'city': shipmentData.city,
          'addressDescription': shipmentData.addressDescription,
          'paymentMethod': shipmentData.paymentMethod,
          'codAmount': shipmentData.codAmount,
          'serviceType': shipmentData.serviceType,
          'trackingNumber': shipmentData.trackingNumber,
          'contents': shipmentData.contents,
          'weight': shipmentData.weight,
          'notes': shipmentData.notes,
          'parcelCount': shipmentData.parcelCount,
          'userphone': shipmentData.userphone,
          'customerlocation': shipmentData.customerlocation,
          'lastUpdated': shipmentData.lastUpdated,
          'deliveryDate': shipmentData.deliveryDate != null
              ? shipmentData.deliveryDate!.toIso8601String()
              : null,
          'expectedDeliveryDate':
              shipmentData.expectedDeliveryDate?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
          'isDeliveryFeeOnRecipient': shipmentData.isDeliveryFeeOnRecipient,
          'isCompanyDeliveryFeePaid': shipmentData.isCompanyDeliveryFeePaid,
          'isPayToRecipient': shipmentData.isPayToRecipient,
          'hasReturn': shipmentData.hasReturn,
          'selectedItems': shipmentData.selectedItems,
          'isShipmentWithItems': shipmentData.isShipmentWithItems,
        };
        appProvider.updateOrder(updateMap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث الطلب بنجاح')));
        }
      } else {
        appProvider.addOrder(shipmentData.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت إضافة الطلب بنجاح')));
        }
      }

      // Handle different submit actions
      switch (_submitAction) {
        case 'save_and_print':
          PrintHandler().printShipmentReceipt([shipmentData]);
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
          // Clear form fields
          _formKey.currentState!.reset();
          deliveryCostController.clear();
          addressDescController.clear();
          recipientNameController.clear();
          phoneController.clear();
          codAmountController.clear();
          trackingNumberController.clear();
          contentController.clear();
          weightController.clear();
          notesController.clear();

          setState(() {
            selectedCity = null;
            appProvider.selectedCityPlace = null;
            selectedCityPlace = null;
            selectedPaymentMethod = 'إحضار';
            selectedCollectionMethod = 'كاش';
            selectedServiceType = 'اعتيادي';
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
            showInventorySection = false;
            selectedInventoryItems.clear();
            _availableSupplyOrders.clear();
            _selectedSupplyQuantities.clear();

            isDeliveryFeeOnRecipient = true;
            isCompanyDeliveryFeePaid = false;
            isPayToRecipient = false;
          });

          break;
        case 'save_and_not_close':
          // Clear form fields
          _formKey.currentState!.reset();
          deliveryCostController.clear();
          addressDescController.clear();
          recipientNameController.clear();
          phoneController.clear();
          codAmountController.clear();
          trackingNumberController.clear();
          contentController.clear();
          weightController.clear();
          notesController.clear();

          setState(() {
            selectedCity = null;
            appProvider.selectedCityPlace = null;
            selectedCityPlace = null;
            selectedPaymentMethod = 'إحضار';
            selectedCollectionMethod = 'كاش';
            selectedServiceType = 'اعتيادي';
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
            showInventorySection = false;
            selectedInventoryItems.clear();
            _availableSupplyOrders.clear();
            _selectedSupplyQuantities.clear();

            isDeliveryFeeOnRecipient = true;
            isCompanyDeliveryFeePaid = false;
            isPayToRecipient = false;
            appProvider.selectedCustomer = null;
            appProvider.selectedCityPlace = null;
            appProvider.selectedDriver = null;
          });

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

  void _cheakForDriver(AppProvider appProvider) {
    if (selectedCity != null) {
      // Use combined name or city for driver search
      final cityForDriver = selectedCityPlace ?? selectedCity!;
      List<Driver> driversFromCity = appProvider.drivers
          .where((driver) => driver.cities.contains(cityForDriver))
          .toList();
      if (driversFromCity.isNotEmpty) {
        setState(() {
          selectedPickupLocation = 'مع السائق';
          appProvider.selectedDriver = driversFromCity.first;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1100;
    if (widget.isWhatsapp) {
      isDesktop = false;
    }
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        bool isMobile = MediaQuery.of(context).size.width < 600;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: Color(0xfff5f6f8),
            width: isMobile
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width * .70,
            child: Column(
              children: [
                // Professional Invoice Header
                _buildInvoiceHeader(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPickupLocationSection(appProvider),
                                _buildSenderSection(appProvider),
                                _buildRecipientSection(appProvider),
                                _buildPaymentSection(),
                                _buildServiceSection(),
                                _buildGoodsSection(appProvider),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: _buildPackageDetailsSection(appProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(getIconForSection(title), color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetailsSection(AppProvider appProvider) {
    return Card(
      elevation: 1,
      color: Color(0xfff5f6f8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedPackageType,
              decoration: const InputDecoration(
                  labelText: 'نوع الطرد', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(
                    value: 'العادية', child: Text('العادية')),
                ...appProvider.packageTypes.map((pt) {
                  return DropdownMenuItem(value: pt.name, child: Text(pt.name));
                }).toList(),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedPackageType = val;
                    if (val != 'العادية') {
                      try {
                        var pt = appProvider.packageTypes
                            .firstWhere((e) => e.name == val);
                        weightController.text = pt.weight.toString();
                      } catch (_) {}
                    }
                  });
                  calculateDeliveryCost(appProvider);
                }
              },
            ),
            SizedBox(height: 16),
            _buildParcelCounter(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    isRequired: false,
                    controller: trackingNumberController,
                    label: 'رقم الإرسالية التجارية',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    isRequired: false,
                    controller: weightController,
                    label: 'الوزن (كجم)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            _buildTextField(
              controller: contentController,
              label: 'محتويات الطرد',
              maxLines: 2,
              isRequired: false,
            ),
            _buildTextField(
              controller: notesController,
              label: 'ملاحظات',
              maxLines: 2,
              isRequired: false,
            ),
            _buildDateFields(),
            _buildPackageAttributesSwitches(),
            _buildSubmitButton(appProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('عدد العناصر', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Color(0xFFDC2626)),
              onPressed: () {
                if (parcelCount > 1) setState(() => parcelCount--);
              },
            ),
            Text('$parcelCount'),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Color(0xFFDC2626)),
              onPressed: () => setState(() => parcelCount++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPackageAttributesSwitches() {
    return Column(
      children: [
        _buildSwitch(
            'قابل للكسر',
            packageAttributes.isFragile,
            (value) => setState(() => packageAttributes = PackageAttributes(
                  isFragile: value,
                  needsPackaging: packageAttributes.needsPackaging,
                  hasDangerousMaterials:
                      packageAttributes.hasDangerousMaterials,
                  isNonOpenable: packageAttributes.isNonOpenable,
                  canBeFolded: packageAttributes.canBeFolded,
                  measurementForbidden: packageAttributes.measurementForbidden,
                ))),
        _buildSwitch(
            'بحاجة للتغليف',
            packageAttributes.needsPackaging,
            (value) => setState(() => packageAttributes = PackageAttributes(
                  isFragile: packageAttributes.isFragile,
                  needsPackaging: value,
                  hasDangerousMaterials:
                      packageAttributes.hasDangerousMaterials,
                  isNonOpenable: packageAttributes.isNonOpenable,
                  canBeFolded: packageAttributes.canBeFolded,
                  measurementForbidden: packageAttributes.measurementForbidden,
                ))),
        // Add other switches similarly
      ],
    );
  }

  Widget _buildSubmitButton(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFFDC2626),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _isLoading ? null : () => _handleSubmit(appProvider),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child:
                _isLoading ? const CircularProgressIndicator() : Text('إرسال'),
          ),
        ),
        // Radio buttons
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
                  activeColor: Color(0xFFDC2626),
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
                  activeColor: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text('حفظ ومتابعة الإضافة'),
                leading: Radio<String>(
                  value: 'save_and_continue',
                  groupValue: _submitAction,
                  onChanged: (String? value) {
                    setState(() => _submitAction = value!);
                  },
                  activeColor: Color(0xFFDC2626),
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text('حفظ وعدم اغلاق'),
                leading: Radio<String>(
                  value: 'save_and_not_close',
                  groupValue: _submitAction,
                  onChanged: (String? value) {
                    setState(() => _submitAction = value!);
                  },
                  activeColor: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFFDC2626),
            activeTrackColor: Color(0xFFFFFFFF).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupLocationButton(
      String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFDC2626) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildPickupLocationSection(AppProvider appProvider) {
    if (_isEditMode) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('موقع الاستلام'),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildPickupLocationButton(
                  'من الزبون',
                  selectedPickupLocation == 'من عنوان الزبون',
                  () => setState(
                      () => selectedPickupLocation = 'من عنوان الزبون'),
                ),
              ),
              Expanded(
                child: _buildPickupLocationButton(
                  'مع السائق',
                  selectedPickupLocation == 'مع السائق',
                  () => setState(() => selectedPickupLocation = 'مع السائق'),
                ),
              ),
              Expanded(
                child: _buildPickupLocationButton(
                  'في الفرع',
                  selectedPickupLocation == 'في الفرع',
                  () => setState(() => selectedPickupLocation = 'في الفرع'),
                ),
              ),
            ],
          ),
        ),
        if (selectedPickupLocation == 'مع السائق') ...[
          SizedBox(height: 16),
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
  }

  Widget _buildSenderSection(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('معلومات المرسل'),
        SearchableDropdown<Customer>(
          label: 'المتجر/الزبون',
          value: appProvider.selectedCustomer,
          items: appProvider.customers,
          onChanged: (value) async {
            setState(() => appProvider.selectedCustomer = value);
            calculateDeliveryCost(appProvider);
            if (value != null) {
              _checkSupplyOrders(appProvider, value);
              // Check past unclosed orders for this customer
              await _checkUnclosedOrders(value.userid);
            }
          },
          searchController: customerSearchController,
          hint: 'اختر المتجر/الزبون',
        ),
        // if (appProvider.selectedCustomer != null) ...[
        //   SizedBox(height: 8),
        //   Card(
        //     elevation: 1,
        //     color: Colors.white,
        //     child: Padding(
        //       padding: const EdgeInsets.all(12.0),
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           _buildInfoRow('المدينة:',
        //               appProvider.selectedCustomer!.city ?? 'غير محدد'),
        //           _buildInfoRow(
        //               'العنوان:', appProvider.selectedCustomer!.address),
        //           _buildInfoRow(
        //               'رقم الهاتف:', appProvider.selectedCustomer!.phoneNumber),
        //         ],
        //       ),
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildRecipientSection(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('معلومات المستلم'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                  isRequired: false,
                  controller: recipientNameController,
                  label: 'اسم المستلم'),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
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
                  controller: phoneController,
                  label: 'رقم الجوال'),
            ),
          ],
        ),
        // ── OLD CODE (SearchableDropdown) – commented out ──────────────────
        // Row(
        //   children: [
        //     Expanded(
        //       flex: 2,
        //       child: SearchableDropdown<String>(
        //         label: 'المدينة',
        //         value: selectedCity,
        //         items: appProvider.cities,
        //         onChanged: (value) {
        //           setState(() {
        //             selectedCity = value;
        //             selectedRegion = null;
        //             selectedCityPlace = value;
        //           });
        //           calculateDeliveryCost(appProvider);
        //           _cheakForDriver(appProvider);
        //         },
        //         searchController: citySearchController,
        //         hint: 'اختر المدينة',
        //       ),
        //     ),
        //     SizedBox(width: 8),
        //     Expanded(
        //       flex: 3,
        //       child: SearchableDropdown<String>(
        //         label: 'المنطقة',
        //         value: selectedRegion,
        //         items: selectedCity != null
        //             ? appProvider.citiesAndPlaces
        //                 .firstWhere((c) => c.name == selectedCity,
        //                     orElse: () => City(name: selectedCity!, places: []))
        //                 .places
        //             : [],
        //         onChanged: (value) {
        //           setState(() {
        //             selectedRegion = value;
        //             selectedCityPlace =
        //                 (selectedCity ?? "") + " " + (value ?? "");
        //           });
        //           _cheakForDriver(appProvider);
        //         },
        //         searchController: TextEditingController(),
        //         hint: 'اختر المنطقة',
        //       ),
        //     ),
        Row(
          children: [
            // ── المدينة – Autocomplete ────────────────────────────────────
            Expanded(
              flex: 2,
              child: _buildCityAutocomplete(appProvider),
            ),
            SizedBox(width: 8),
            // ── المنطقة – Autocomplete ────────────────────────────────────
            Expanded(
              flex: 3,
              child: _buildRegionAutocomplete(appProvider),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildTextField(
                  controller: addressDescController,
                  label: 'وصف العنوان',
                  focusNode: _addressDescFocusNode),
            ),
          ],
        ),
      ],
    );
  }

  // ── المدينة – Autocomplete helper ──────────────────────────────────────────
  Widget _buildCityAutocomplete(AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FormField<String>(
        initialValue: selectedCity,
        validator: (_) {
          if (selectedCity == null || selectedCity!.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          return null;
        },
        builder: (FormFieldState<String> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                initialValue: selectedCity != null
                    ? TextEditingValue(text: selectedCity!)
                    : null,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return appProvider.cities;
                  }
                  return appProvider.cities.where((city) => city
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String city) {
                  setState(() {
                    selectedCity = city;
                    selectedRegion = null;
                    selectedCityPlace = city;
                  });
                  state.didChange(city);
                  calculateDeliveryCost(appProvider);
                  _cheakForDriver(appProvider);
                  // Move focus to region field
                  _regionFocusNode.requestFocus();
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,
                    onFieldSubmitted: (value) {
                      final filtered = appProvider.cities
                          .where((city) =>
                              city.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                      if (filtered.isNotEmpty) {
                        final selection = filtered.first;
                        setState(() {
                          selectedCity = selection;
                          selectedRegion = null;
                          selectedCityPlace = selection;
                        });
                        state.didChange(selection);
                        textController.text = selection;
                        calculateDeliveryCost(appProvider);
                        _cheakForDriver(appProvider);
                        _regionFocusNode.requestFocus();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'المدينة *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFDC2626)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  );
                },
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── المنطقة – Autocomplete helper ──────────────────────────────────────────
  Widget _buildRegionAutocomplete(AppProvider appProvider) {
    final List<String> regionOptions = selectedCity != null
        ? appProvider.citiesAndPlaces
            .firstWhere((c) => c.name == selectedCity,
                orElse: () => City(name: selectedCity!, places: []))
            .places
        : [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FormField<String>(
        key: ValueKey(selectedCity), // Rebuild when city changes
        initialValue: selectedRegion,
        validator: (_) {
          final typed = selectedRegion?.trim() ?? '';
          if (typed.isNotEmpty &&
              regionOptions.isNotEmpty &&
              !regionOptions.contains(typed)) {
            return 'يرجى اختيار منطقة من القائمة';
          }
          return null;
        },
        builder: (FormFieldState<String> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AbsorbPointer(
                absorbing: selectedCity == null,
                child: Opacity(
                  opacity: selectedCity == null ? 0.4 : 1.0,
                  child: Autocomplete<String>(
                    key: ValueKey('region_$selectedCity'),
                    initialValue: selectedRegion != null
                        ? TextEditingValue(text: selectedRegion!)
                        : null,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return regionOptions;
                      }
                      return regionOptions.where((region) => region
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String region) {
                      setState(() {
                        selectedRegion = region;
                        selectedCityPlace =
                            '${selectedCity ?? ''} $region'.trim();
                      });
                      state.didChange(region);
                      _cheakForDriver(appProvider);
                      // Move focus to address description field
                      _addressDescFocusNode.requestFocus();
                    },
                    fieldViewBuilder:
                        (context, textController, focusNode, onFieldSubmitted) {
                      return Focus(
                        // When _regionFocusNode gains focus, forward it to the
                        // Autocomplete's internal focusNode
                        focusNode: _regionFocusNode,
                        onFocusChange: (hasFocus) {
                          if (hasFocus) focusNode.requestFocus();
                        },
                        child: TextFormField(
                          controller: textController,
                          focusNode: focusNode,
                          onFieldSubmitted: (value) {
                            final filtered = regionOptions
                                .where((region) => region
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                            if (filtered.isNotEmpty) {
                              final selection = filtered.first;
                              setState(() {
                                selectedRegion = selection;
                                selectedCityPlace =
                                    '${selectedCity ?? ''} $selection'.trim();
                              });
                              state.didChange(selection);
                              textController.text = selection;
                              _cheakForDriver(appProvider);
                              _addressDescFocusNode.requestFocus();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'المنطقة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFDC2626)),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            filled: true,
                            fillColor: selectedCity == null
                                ? Colors.grey.shade100
                                : Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('التحصيل'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: deliveryCostController,
                label: 'سعر التوصيل',
                keyboardType: TextInputType.number,
              ),
            ),
            if (selectedPaymentMethod == 'COD') ...[
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: codAmountController,
                  label: 'التحصيل شامل التوصيل',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ],
        ),
        Row(
          children: [
            Expanded(
              child: SearchableDropdown<String>(
                label: 'طريقة الدفع',
                value: selectedPaymentMethod,
                items: paymentMethods,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                    if (selectedPaymentMethod == 'مدفوعة مسبقا') {
                      isDeliveryFeeOnRecipient = true;
                      isCompanyDeliveryFeePaid = false;
                      codAmountController.text = '0';
                    } else if (selectedPaymentMethod == 'تبديل' ||
                        selectedPaymentMethod == 'إحضار') {
                      isPayToRecipient = false;
                    }
                  });
                },
                searchController: paymentMethodSearchController,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SearchableDropdown<String>(
                label: 'طريقة التحصيل',
                value: selectedCollectionMethod,
                items: collectionMethods,
                onChanged: (value) =>
                    setState(() => selectedCollectionMethod = value!),
                searchController: collectionMethodSearchController,
              ),
            ),
          ],
        ),

        // Conditionally show extra payment controls
        if (selectedPaymentMethod == 'مدفوعة مسبقا') _buildPrepaidSection(),
        if (selectedPaymentMethod == 'تبديل' ||
            selectedPaymentMethod == 'إحضار')
          _buildExchangeOrPickupSection(),
      ],
    );
  }

  Widget _buildPrepaidSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 16,
      ),
      _buildSectionTitle('خيارات مسار الدفع'),
      _buildSwitch(
        'المستلم سيدفع سعر التوصيل',
        isDeliveryFeeOnRecipient,
        (value) => setState(() {
          isDeliveryFeeOnRecipient = value;
          if (value) {
            isCompanyDeliveryFeePaid = false;
          }
        }),
      ),
      if (!isDeliveryFeeOnRecipient)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text('طريقة دفع البائع لتسديد رسوم التوصيل',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('دفع من رصيد البائع',
                        style: TextStyle(fontSize: 13)),
                    leading: Radio<bool>(
                      value:
                          false, // isCompanyDeliveryFeePaid = false means from seller balance
                      groupValue: isCompanyDeliveryFeePaid,
                      onChanged: hasUnclosedOrders
                          ? (value) {
                              setState(() => isCompanyDeliveryFeePaid = value!);
                            }
                          : null, // Disable if no unclosed orders
                      activeColor: Color(0xFFDC2626),
                    ),
                    subtitle: !hasUnclosedOrders
                        ? Text(
                            'غير متاح حاليا الا اذا كان يوجد طلبات سابقة غير مقفلة',
                            style: TextStyle(fontSize: 11, color: Colors.grey))
                        : null,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('دفع كاش', style: TextStyle(fontSize: 13)),
                    leading: Radio<bool>(
                      value:
                          true, // isCompanyDeliveryFeePaid = true means cash paid to company directly
                      groupValue: isCompanyDeliveryFeePaid,
                      onChanged: (value) {
                        setState(() => isCompanyDeliveryFeePaid = value!);
                      },
                      activeColor: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    ]);
  }

  Widget _buildExchangeOrPickupSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 16,
      ),
      _buildSectionTitle('خيارات التحصيل'),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: codAmountController,
              label: selectedPaymentMethod == 'تبديل'
                  ? 'قيمة الفرق/الاستبدال'
                  : 'المبلغ المطلوب',
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: false, // isPayToRecipient = false
                      groupValue: isPayToRecipient,
                      onChanged: (value) {
                        setState(() => isPayToRecipient = value!);
                      },
                      activeColor: Color(0xFFDC2626),
                    ),
                    Text('تحصيل من المستلم', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: true, // isPayToRecipient = true
                      groupValue: isPayToRecipient,
                      onChanged: (value) {
                        setState(() => isPayToRecipient = value!);
                      },
                      activeColor: Color(0xFFDC2626),
                    ),
                    Text('الدفع للمستلم', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      )
    ]);
  }

  Widget _buildServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _buildSectionTitle('الخدمة والطلب'),
        SearchableDropdown<String>(
          label: 'نوع الخدمة',
          value: selectedServiceType,
          items: serviceTypes,
          onChanged: (value) => setState(() => selectedServiceType = value!),
          searchController: serviceTypeSearchController,
        ),
        if (_availableSupplyOrders.isNotEmpty) _buildSupplyOrdersSection(),
      ],
    );
  }

  Widget _buildSupplyOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'اختيار بضاعة من التوريد',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._availableSupplyOrders.map((order) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "طلب #${order.id.substring(0, 5)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12),
                ),
              ),
              ...order.items.map((item) {
                final isSelected =
                    _selectedSupplyQuantities.containsKey(item.id);
                final currentQty = _selectedSupplyQuantities[item.id] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: CheckboxListTile(
                    title: Text(item.title ?? "بدون اسم"),
                    subtitle:
                        Text("السعر: ${item.price} | المتاح: ${item.quantity}"),
                    value: isSelected,
                    activeColor: const Color(0xFFDC2626),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedSupplyQuantities[item.id] = 1;
                        } else {
                          _selectedSupplyQuantities.remove(item.id);
                        }
                        _updateCODAndContents();
                      });
                    },
                    secondary: isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20, color: Color(0xFFDC2626)),
                                onPressed: () {
                                  setState(() {
                                    if (currentQty > 1) {
                                      _selectedSupplyQuantities[item.id] =
                                          currentQty - 1;
                                    } else {
                                      _selectedSupplyQuantities.remove(item.id);
                                    }
                                    _updateCODAndContents();
                                  });
                                },
                              ),
                              Text('$currentQty'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 20, color: Color(0xFFDC2626)),
                                onPressed: () {
                                  if (currentQty < item.quantity) {
                                    setState(() {
                                      _selectedSupplyQuantities[item.id] =
                                          currentQty + 1;
                                      _updateCODAndContents();
                                    });
                                  }
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _updateCODAndContents() {
    double totalPrice = 0;
    List<String> itemsDescription = [];

    _selectedSupplyQuantities.forEach((itemId, quantity) {
      // Find the item in _availableSupplyOrders
      for (var order in _availableSupplyOrders) {
        for (var item in order.items) {
          if (item.id == itemId) {
            totalPrice += item.price * quantity;
            itemsDescription.add("${item.title} ($quantity)");
          }
        }
      }
    });

    double deliveryCost = double.tryParse(deliveryCostController.text) ?? 0.0;
    codAmountController.text = (totalPrice + deliveryCost).toString();
    contentController.text = itemsDescription.join(", ");
  }

  Widget _buildGoodsSection(AppProvider appProvider) {
    if (appProvider.selectedCustomer == null) {
      return SizedBox.shrink();
    }

    return StreamBuilder<Inventory>(
        stream: appProvider
            .getCustomerInventoryStream(appProvider.selectedCustomer!.userid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final inventory = snapshot.data;
          final items = inventory?.items ?? [];

          if (items.isEmpty) {
            return SizedBox.shrink();
          }

          return Card(
            elevation: 1,
            color: Color(0xfff5f6f8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('البضائع'),
                      Switch(
                        value: showInventorySection,
                        onChanged: (value) {
                          setState(() {
                            showInventorySection = value;
                            if (!value) {
                              selectedInventoryItems.clear();
                            }
                          });
                        },
                        activeColor: Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  if (showInventorySection) ...[
                    const SizedBox(height: 16),
                    ...List.generate(
                      items.length,
                      (index) {
                        final item = items[index];
                        final isSelected =
                            selectedInventoryItems.containsKey(item.id);
                        final quantity = selectedInventoryItems[item.id] ?? 0;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              'المخزون المتاح: ${item.quantity}${item.price != null ? ' - السعر: ${item.price}' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline,
                                        color: Color(0xFFDC2626)),
                                    onPressed: () {
                                      setState(() {
                                        if (quantity > 1) {
                                          selectedInventoryItems[item.id!] =
                                              quantity - 1;
                                        } else {
                                          selectedInventoryItems
                                              .remove(item.id);
                                        }
                                      });
                                    },
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline,
                                        color: Color(0xFFDC2626)),
                                    onPressed: item.quantity > quantity
                                        ? () {
                                            setState(() {
                                              selectedInventoryItems[item.id!] =
                                                  quantity + 1;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                                Checkbox(
                                  value: isSelected,
                                  activeColor: Color(0xFFDC2626),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedInventoryItems[item.id!] = 1;
                                      } else {
                                        selectedInventoryItems.remove(item.id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ).toList(),
                    if (selectedInventoryItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'العناصر المحددة: ${selectedInventoryItems.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        });
  }

  Widget _buildDateFields() {
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker(
            'تاريخ التوصيل المتوقع',
            deliveryDate,
            (date) => setState(() => deliveryDate = date),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildDatePicker(
            'تاريخ التسليم المتوقع',
            expectedDeliveryDate,
            (date) => setState(() => expectedDeliveryDate = date),
          ),
        ),
      ],
    );
  }

  IconData getIconForSection(String title) {
    switch (title) {
      case 'معلومات المرسل':
        return Icons.location_on;
      case 'معلومات المستلم':
        return Icons.person;
      case 'التحصيل':
        return Icons.monetization_on;
      case 'الخدمة والطلب':
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  Widget _buildTextField({
    required String label,
    bool isRequired = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextEditingController? controller,
    int? maxLines,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFDC2626)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: keyboardType,
        validator: validator ??
            (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            },
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(Duration(days: 365)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Color(0xFFDC2626),
                    onPrimary: Colors.white,
                    surface: Color(0xfff5f6f8),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.calendar_today, color: Color(0xFFDC2626)),
              Text(
                selectedDate != null
                    ? intl.DateFormat('yyyy-MM-dd').format(selectedDate)
                    : label,
                style: TextStyle(
                  color: selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void calculateDeliveryCost(AppProvider appProvider) {
    if (selectedCity != null && appProvider.selectedCustomer != null) {
      try {
        double price = appProvider.calculateDeliveryCostForCity(
            selectedCity!, appProvider.selectedCustomer!.userid,
            packageTypeName: selectedPackageType ?? 'العادية');

        setState(() {
          deliveryCostController.text = price > 0 ? price.toString() : "";
        });
      } catch (e) {
        print("Error in calculateDeliveryCost: $e");
      }
    }
  }

  Widget _buildInvoiceHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Company Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      KcompanyName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                        fontFamily: 'Almarai',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'فاتورة شحن',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ),
              // Invoice Number and Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (kDebugMode)
                    IconButton(
                      icon: Icon(Icons.bug_report, color: Colors.blue),
                      onPressed: _fillDummyData,
                      tooltip: 'تعبئة بيانات تجريبية',
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFDC2626), width: 1),
                    ),
                    child: Text(
                      'رقم ${_isEditMode ? widget.shipment!.orderId : DateTime.now().millisecondsSinceEpoch.toString().replaceRange(0, 2, "")}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    intl.DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Almarai',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _checkSupplyOrders(
      AppProvider appProvider, Customer customer) async {
    try {
      final orders = await appProvider.checkSupplyOrders(customer.userid);
      setState(() {
        _availableSupplyOrders = orders;
        _selectedSupplyQuantities.clear();
      });
    } catch (e) {
      print("Error checking supply orders: $e");
    }
  }

  Future<void> _checkUnclosedOrders(String customerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: customerId)
          .where('cashPossession', isNotEqualTo: 'customer')
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          hasUnclosedOrders = snapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print("Error checking unclosed orders: $e");
    }
  }
}
