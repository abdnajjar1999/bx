

// TourSelectionDialog.dart
//   show driverPrice use getShipmentsWithDriverPrice and add driverPrice per order as an option it changes the order's driverPrice to this value when assigning calculate the whole values besides it 


// import 'package:flutter/services.dart';
// import 'package:universal_html/html.dart';

// import '../../models/City.dart';
// import '../../models/Customer.dart';
// import '../../models/Driver.dart';
// import '../../models/Inventory.dart';
// import '../../models/PriceCalculators.dart';
// import '../../models/Shipment.dart';
// import '../../screens/ManageShipments/widget/SearchableDropdown.dart';
// import '../../shared/PrintHelper.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart' as intl;
// import 'package:provider/provider.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';

// import '../../main.dart';
// import '../../shared/appProvider.dart';
// import '../../shared/constants.dart';

// class AddOrderForm extends StatefulWidget {
//   final Shipment? shipment;
//   final bool isEditMode;
//   final bool isWhatsapp;
//   const AddOrderForm({Key? key, this.shipment, this.isWhatsapp = false, this.isEditMode = false})
//       : super(key: key);

//   @override
//   AddOrderFormState createState() => AddOrderFormState();
// }

// class AddOrderFormState extends State<AddOrderForm> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _isEditMode = false;
//   String _submitAction = 'save_and_close';

//   // Package Attributes
//   late PackageAttributes packageAttributes;

//   // Selected inventory items
//   Map<String, int> selectedInventoryItems = {};
//   bool showInventorySection = false;

//   // Form Controllers
//   final TextEditingController deliveryCostController = TextEditingController();
//   final TextEditingController addressDescController = TextEditingController();
//   final TextEditingController recipientNameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController codAmountController = TextEditingController();
//   final TextEditingController trackingNumberController =
//       TextEditingController();
//   final TextEditingController contentController = TextEditingController();
//   final TextEditingController weightController = TextEditingController();
//   final TextEditingController notesController = TextEditingController();

//   // Add search controllers
//   final TextEditingController citySearchController = TextEditingController();
//   final TextEditingController paymentMethodSearchController =
//       TextEditingController();
//   final TextEditingController collectionMethodSearchController =
//       TextEditingController();
//   final TextEditingController serviceTypeSearchController =
//       TextEditingController();
//   final TextEditingController customerSearchController =
//       TextEditingController();
//   final TextEditingController driverSearchController = TextEditingController();


//   // Focus Nodes


//   final FocusNode selectedCityFocusNode = FocusNode();
//   final FocusNode  citySearchFocusNode = FocusNode();
//   final FocusNode phoneFocusNode = FocusNode();

//   // Form State
//   String? selectedCity;
//   String? selectedCityPlace;

//   String selectedPaymentMethod = 'إحضار';
//   String selectedCollectionMethod = 'كاش';
//   String selectedServiceType = 'اعتيادي';
//   String selectedPickupLocation = 'من عنوان الزبون';
//   int parcelCount = 1;
//   DateTime? deliveryDate;
//   DateTime? expectedDeliveryDate;

//   @override
//   void initState() {
//     super.initState();
//     _isEditMode = widget.isEditMode;
//     _initializeFormData();
//   }


//   void _initializeFormData() {
//     final appProvider = Provider.of<AppProvider>(context, listen: false);
//     if (widget.shipment != null) {
//       final shipment = widget.shipment!;
//       final customers = appProvider.customers
//           .where((customer) => customer.userid == shipment.userId)
//           .toList();
//       if (customers.isNotEmpty) {
//         appProvider.selectedCustomer = customers.first;
//       }
//       selectedPickupLocation =
//           shipment.driverId != null ? 'مع السائق' : 'في الفرع';

//       if (shipment.driverId != null) {
//         final drivers = appProvider.drivers
//             .where((driver) => driver.userid == shipment.driverId)
//             .toList();
//         if (drivers.isNotEmpty) {
//           appProvider.selectedDriver = drivers.first;
//         }
//       }

//       // Initialize package attributes
//       packageAttributes = shipment.packageAttributes;

//       // Populate form controllers
//       deliveryCostController.text = shipment.deliveryCost.toString();
//       addressDescController.text = shipment.addressDescription;
//       recipientNameController.text = shipment.recipientName;
//       phoneController.text = shipment.phoneNumber;
//       codAmountController.text = shipment.codAmount.toString();
//       trackingNumberController.text = shipment.trackingNumber;
//       contentController.text = shipment.contents;
//       weightController.text = shipment.weight.toString();
//       notesController.text = shipment.notes;
//       if (shipment.selectedItems != null) {
//         selectedInventoryItems = shipment.selectedItems!;
//         showInventorySection = true;
//       }

//       // Set dropdown values
//       setState(() {
//         selectedCity = shipment.city.split(' ')[0];
//         if (appProvider.citiesAndPlacesNames.contains(shipment.city)) {
//           selectedCityPlace = shipment.city;
//         }
//         if (paymentMethods.contains(shipment.paymentMethod)) {
//           selectedPaymentMethod = shipment.paymentMethod;
//         }
//         if (collectionMethods.contains(shipment.collectionMethod)) {
//           selectedCollectionMethod = shipment.collectionMethod;
//         }

//         if (serviceTypes.contains(shipment.serviceType)) {
//           selectedServiceType = shipment.serviceType;
//         }
//         parcelCount = shipment.parcelCount ?? 1;
//         deliveryDate = shipment.deliveryDate;
//         expectedDeliveryDate = shipment.expectedDeliveryDate;
//       });
//     } else {
//       // Initialize with default values for new orders
//       packageAttributes = PackageAttributes(
//         isFragile: false,
//         needsPackaging: false,
//         hasDangerousMaterials: false,
//         isNonOpenable: false,
//         canBeFolded: false,
//         measurementForbidden: false,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     deliveryCostController.dispose();
//     addressDescController.dispose();
//     recipientNameController.dispose();
//     phoneController.dispose();
//     codAmountController.dispose();
//     trackingNumberController.dispose();
//     contentController.dispose();
//     weightController.dispose();
//     notesController.dispose();
//     citySearchController.dispose();
//     paymentMethodSearchController.dispose();
//     collectionMethodSearchController.dispose();
//     serviceTypeSearchController.dispose();
//     customerSearchController.dispose();
//     driverSearchController.dispose();
//     super.dispose();
//   }

//   void _handleSubmit(AppProvider appProvider) {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       String initialStatus;
//       Map<String, dynamic> driverInfo = {};

//       switch (selectedPickupLocation) {
//         case 'من عنوان الزبون':
//           initialStatus = 'الطلبات الجديدة';
//           break;
//         case 'مع السائق':
//           if (appProvider.selectedDriver == null) {
//             ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('الرجاء اختيار السائق')));
//             return;
//           }
//           initialStatus = 'في المركبة';
//           driverInfo = {
//             'driverId': appProvider.selectedDriver!.userid,
//             'driverName': appProvider.selectedDriver!.username,
//           };
//           break;
//         case 'في الفرع':
//           initialStatus = 'في الفرع';
//           break;
//         default:
//           initialStatus = 'الطلبات الجديدة';
//       }

//       final shipmentData = Shipment(
//           orderId: _isEditMode
//               ? widget.shipment!.orderId
//               : DateTime.now()
//                   .millisecondsSinceEpoch
//                   .toString()
//                   .replaceRange(0, 2, ''),
//           username: appProvider.selectedCustomer?.username,
//           userId: appProvider.selectedCustomer?.userid,
//           profileImageUrl: appProvider.selectedCustomer?.profileImage,
//           driverId:
//               _isEditMode ? widget.shipment!.driverId : driverInfo['driverId'],
//           driverName: _isEditMode
//               ? widget.shipment!.driverName
//               : driverInfo['driverName'],
//           packageAttributes: packageAttributes,
//           deliveryCost: double.parse(deliveryCostController.text),
//           collectionMethod: selectedCollectionMethod,
//           recipientName: recipientNameController.text.trim(),
//           phoneNumber: phoneController.text.trim(),
//           city: selectedCityPlace ?? '',
//           addressDescription: addressDescController.text.trim(),
//           paymentMethod: selectedPaymentMethod,
//           codAmount: double.parse(codAmountController.text),
//           serviceType: selectedServiceType,
//           trackingNumber: trackingNumberController.text.trim(),
//           contents: contentController.text.trim(),
//           weight: double.tryParse(weightController.text) ?? 0,
//           notes: notesController.text.trim(),
//           parcelCount: parcelCount,
//           userphone: appProvider.selectedCustomer?.phoneNumber,
//           customerlocation: appProvider.selectedCustomer?.city,
//           status: _isEditMode ? widget.shipment!.status : initialStatus,
//           createdAt: _isEditMode ? widget.shipment!.createdAt : DateTime.now(),
//           lastUpdated: DateTime.now(),
//           deliveryDate: deliveryDate,
//           expectedDeliveryDate:
//               expectedDeliveryDate ?? DateTime.now().add(Duration(days: 3)),
//           cashPossession: _isEditMode
//               ? widget.shipment!.cashPossession
//               : CashPossession.receiver,
//           logs: _isEditMode
//               ? [
//                   ...widget.shipment!.logs,
//                   ShipmentLog(
//                       date: DateTime.now(),
//                       text: 'تم تحديث الشحنة',
//                       status: initialStatus,
//                       userName:
//                           FirebaseAuth.instance.currentUser?.displayName ??
//                               "مجهول")
//                 ]
//               : [
//                   ShipmentLog(
//                       date: DateTime.now(),
//                       text: 'تمت إضافة الشحنة',
//                       status: 'الطلبات الجديدة',
//                       userName:
//                           FirebaseAuth.instance.currentUser?.displayName ??
//                               "مجهول")
//                 ],
//           selectedItems: showInventorySection ? selectedInventoryItems : null,
//           isShipmentWithItems: showInventorySection);

//       if (_isEditMode) {
//         appProvider.updateOrder(shipmentData.toMap());
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('تم تحديث الطلب بنجاح')));
//         }
//       } else {
//         appProvider.addOrder(shipmentData.toMap());
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('تمت إضافة الطلب بنجاح')));
//         }
//       }

//       // Handle different submit actions
//       switch (_submitAction) {
//         case 'save_and_print':
//           PrintHandler().printShipmentReceipt([shipmentData]);
//           appProvider.selectedCustomer = null;
//           appProvider.selectedCityPlace = null;
//           appProvider.selectedDriver = null;
//           Navigator.pop(context);
//           break;
//         case 'save_and_close':
//           appProvider.selectedCustomer = null;
//           appProvider.selectedCityPlace = null;
//           appProvider.selectedDriver = null;
//           Navigator.pop(context);
//           break;
//         case 'save_and_continue':
//           // Clear form fields
//           _formKey.currentState!.reset();
//           deliveryCostController.clear();
//           addressDescController.clear();
//           recipientNameController.clear();
//           phoneController.clear();
//           codAmountController.clear();
//           trackingNumberController.clear();
//           contentController.clear();
//           weightController.clear();
//           notesController.clear();

//           setState(() {
//             selectedCity = null;
//             appProvider.selectedCityPlace = null;
//             selectedCityPlace = null;
//             selectedPaymentMethod = 'إحضار';
//             selectedCollectionMethod = 'كاش';
//             selectedServiceType = 'اعتيادي';
//             parcelCount = 1;
//             deliveryDate = null;
//             expectedDeliveryDate = null;
//             packageAttributes = PackageAttributes(
//               isFragile: false,
//               needsPackaging: false,
//               hasDangerousMaterials: false,
//               isNonOpenable: false,
//               canBeFolded: false,
//               measurementForbidden: false,
//             );
//             showInventorySection = false;
//             selectedInventoryItems.clear();
//           });
//           break;
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     document.onKeyDown.listen((event) {
//       if (event.key == 'Tab') {
//         event.preventDefault();
//       }
//     });

//     bool isDesktop = MediaQuery.of(context).size.width >= 1100;
//     if (widget.isWhatsapp) {
//       isDesktop = false;
//     }
//     return Consumer<AppProvider>(
//       builder: (context, appProvider, child) {
//         bool isMobile = MediaQuery.of(context).size.width < 600;
//         return Directionality(
//           textDirection: TextDirection.rtl,
//           child: Container(
//             color: background,
//             width: isMobile
//                 ? MediaQuery.of(context).size.width
//                 : MediaQuery.of(context).size.width * .70,
//             child: Form(
//               key: _formKey,
//               child: isDesktop
//                   ? Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           flex: 1,
//                           child: SingleChildScrollView(
//                             padding: EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Expanded(
//                                         child:
//                                             _buildSenderSection(appProvider)),
//                                     Expanded(
//                                         child: _buildPickupLocationSection(
//                                             appProvider)),
//                                   ],
//                                 ),
//                                 _buildRecipientSection(appProvider),
//                                 _buildPaymentSection(),
//                                 _buildServiceSection(),
//                                 _buildGoodsSection(appProvider),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           flex: 1,
//                           child: SingleChildScrollView(
//                             padding: EdgeInsets.all(16),
//                             child: _buildPackageDetailsSection(appProvider),
//                           ),
//                         ),
//                       ],
//                     )
//                   : SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 _buildPickupLocationSection(appProvider),
//                                 _buildSenderSection(appProvider),
//                                 _buildRecipientSection(appProvider),
//                                 _buildPaymentSection(),
//                                 _buildServiceSection(),
//                                 _buildGoodsSection(appProvider),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(16),
//                             child: _buildPackageDetailsSection(appProvider),
//                           ),
//                         ],
//                       ),
//                     ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Icon(getIconForSection(title), color: primary),
//           const SizedBox(width: 8),
//           Text(
//             title,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPackageDetailsSection(AppProvider appProvider) {
//     return Card(
//       elevation: 1,
//       color: background,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildParcelCounter(),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildTextField(
//                     isRequired: false,
//                     controller: trackingNumberController,
//                     label: 'رقم الإرسالية التجارية',
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: _buildTextField(
//                     isRequired: false,
//                     controller: weightController,
//                     label: 'الوزن (كجم)',
//                     keyboardType: TextInputType.number,
//                   ),
//                 ),
//               ],
//             ),
//             _buildTextField(
//               controller: contentController,
//               label: 'محتويات الطرد',
//               maxLines: 2,
//               isRequired: false,
//             ),
//             _buildTextField(
//               controller: notesController,
//               label: 'ملاحظات',
//               maxLines: 2,
//               isRequired: false,
//             ),
//             _buildDateFields(),
//             _buildPackageAttributesSwitches(),
//             _buildSubmitButton(appProvider),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildParcelCounter() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text('عدد العناصر', style: TextStyle(fontWeight: FontWeight.bold)),
//         Row(
//           children: [
//             IconButton(
//               icon: Icon(Icons.remove_circle_outline, color: primary),
//               onPressed: () {
//                 if (parcelCount > 1) setState(() => parcelCount--);
//               },
//             ),
//             Text('$parcelCount'),
//             IconButton(
//               icon: Icon(Icons.add_circle_outline, color: primary),
//               onPressed: () => setState(() => parcelCount++),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildPackageAttributesSwitches() {
//     return Column(
//       children: [
//         _buildSwitch(
//             'قابل للكسر',
//             packageAttributes.isFragile,
//             (value) => setState(() => packageAttributes = PackageAttributes(
//                   isFragile: value,
//                   needsPackaging: packageAttributes.needsPackaging,
//                   hasDangerousMaterials:
//                       packageAttributes.hasDangerousMaterials,
//                   isNonOpenable: packageAttributes.isNonOpenable,
//                   canBeFolded: packageAttributes.canBeFolded,
//                   measurementForbidden: packageAttributes.measurementForbidden,
//                 ))),
//         _buildSwitch(
//             'بحاجة للتغليف',
//             packageAttributes.needsPackaging,
//             (value) => setState(() => packageAttributes = PackageAttributes(
//                   isFragile: packageAttributes.isFragile,
//                   needsPackaging: value,
//                   hasDangerousMaterials:
//                       packageAttributes.hasDangerousMaterials,
//                   isNonOpenable: packageAttributes.isNonOpenable,
//                   canBeFolded: packageAttributes.canBeFolded,
//                   measurementForbidden: packageAttributes.measurementForbidden,
//                 ))),
//         // Add other switches similarly
//       ],
//     );
//   }

//   Widget _buildSubmitButton(AppProvider appProvider) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: primary,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             padding: EdgeInsets.symmetric(vertical: 16),
//           ),
//           onPressed: _isLoading ? null : () => _handleSubmit(appProvider),
//           child: Container(
//             width: double.infinity,
//             alignment: Alignment.center,
//             child:
//                 _isLoading ? const CircularProgressIndicator() : Text('إرسال'),
//           ),
//         ),
//         // Radio buttons
//         Row(
//           children: [
//             Expanded(
//               child: ListTile(
//                 title: Text('حفظ وطباعة'),
//                 leading: Radio<String>(
//                   value: 'save_and_print',
//                   groupValue: _submitAction,
//                   onChanged: (String? value) {
//                     setState(() => _submitAction = value!);
//                   },
//                   activeColor: primary,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListTile(
//                 title: Text('حفظ وإغلاق'),
//                 leading: Radio<String>(
//                   value: 'save_and_close',
//                   groupValue: _submitAction,
//                   onChanged: (String? value) {
//                     setState(() => _submitAction = value!);
//                   },
//                   activeColor: primary,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         ListTile(
//           title: Text('حفظ ومتابعة الإضافة'),
//           leading: Radio<String>(
//             value: 'save_and_continue',
//             groupValue: _submitAction,
//             onChanged: (String? value) {
//               setState(() => _submitAction = value!);
//             },
//             activeColor: primary,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Switch(
//             value: value,
//             onChanged: onChanged,
//             activeColor: primary,
//             activeTrackColor: secprimary.withOpacity(0.5),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPickupLocationButton(
//       String text, bool isSelected, Function() onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         margin: EdgeInsets.symmetric(horizontal: 2),
//         padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//         decoration: BoxDecoration(
//           color: isSelected ? primary : Colors.white,
//           borderRadius: BorderRadius.circular(6),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 2,
//                     offset: Offset(0, 1),
//                   )
//                 ]
//               : null,
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: TextStyle(
//               color: isSelected ? Colors.white : Colors.black87,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               fontSize: 13,
//             ),
//             textAlign: TextAlign.center,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPickupLocationSection(AppProvider appProvider) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('موقع الاستلام'),
//         SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.grey.shade200,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           padding: EdgeInsets.all(4),
//           child: Row(
//             children: [
//               Expanded(
//                 child: _buildPickupLocationButton(
//                   'من الزبون',
//                   selectedPickupLocation == 'من عنوان الزبون',
//                   () => setState(
//                       () => selectedPickupLocation = 'من عنوان الزبون'),
//                 ),
//               ),
//               Expanded(
//                 child: _buildPickupLocationButton(
//                   'مع السائق',
//                   selectedPickupLocation == 'مع السائق',
//                   () => setState(() => selectedPickupLocation = 'مع السائق'),
//                 ),
//               ),
//               Expanded(
//                 child: _buildPickupLocationButton(
//                   'في الفرع',
//                   selectedPickupLocation == 'في الفرع',
//                   () => setState(() => selectedPickupLocation = 'في الفرع'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (selectedPickupLocation == 'مع السائق') ...[
//           SizedBox(height: 16),
//           SearchableDropdown<Driver>(
//             label: 'السائق',
//             value: appProvider.selectedDriver,
//             items: appProvider.drivers,
//             onChanged: (value) =>
//                 setState(() => appProvider.selectedDriver = value),
//             searchController: driverSearchController,
//             hint: 'اختر السائق',
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildSenderSection(AppProvider appProvider) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('معلومات المرسل'),
//         SearchableDropdown<Customer>(
//           label: 'المتجر/الزبون',
//           value: appProvider.selectedCustomer,
//           items: appProvider.customers,
//           onChanged: (value) {
//             setState(() => appProvider.selectedCustomer = value);
//             calculateDeliveryCost(appProvider);
//           },
//           searchController: customerSearchController,
//           hint: 'اختر المتجر/الزبون',
//         ),
//         // if (appProvider.selectedCustomer != null) ...[
//         //   SizedBox(height: 8),
//         //   Card(
//         //     elevation: 1,
//         //     color: Colors.white,
//         //     child: Padding(
//         //       padding: const EdgeInsets.all(12.0),
//         //       child: Column(
//         //         crossAxisAlignment: CrossAxisAlignment.start,
//         //         children: [
//         //           _buildInfoRow('المدينة:',
//         //               appProvider.selectedCustomer!.city ?? 'غير محدد'),
//         //           _buildInfoRow(
//         //               'العنوان:', appProvider.selectedCustomer!.address),
//         //           _buildInfoRow(
//         //               'رقم الهاتف:', appProvider.selectedCustomer!.phoneNumber),
//         //         ],
//         //       ),
//         //     ),
//         //   ),
//         // ],
//       ],
//     );
//   }



//   Widget _buildRecipientSection(AppProvider appProvider) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('معلومات المستلم'),
//         Row(
//           children: [
//             Expanded(
//               child: _buildTextField(
//                   controller: recipientNameController, label: 'اسم المستلم'),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: KeyboardListener(
//                 focusNode: phoneFocusNode,
//                 onKeyEvent: (event) {
//                   if (event.logicalKey == LogicalKeyboardKey.tab) {
//                     print("tab");
//                     Future.delayed(Duration(milliseconds: 0), () {
//                       FocusScope.of(context).requestFocus(selectedCityFocusNode);
//                     });
//                   }
//                 },
//                 child: _buildTextField(
//                   controller: phoneController,
//                   label: 'رقم الجوال',
//                 ),
//               ),
//             ),
//           ],
//         ),
//         Row(
//           children: [
//             Expanded(
//               child: SearchableDropdown<String>(
//                 focusNode: selectedCityFocusNode,
//                 label: 'عنوان المستلم',
//                 value: selectedCityPlace,
//                 items: appProvider.citiesAndPlacesNames,
//                 onChanged: (value) {
//                   setState(() => selectedCityPlace = value);
//                   selectedCity = value!.split(" ")[0];

//                   calculateDeliveryCost(appProvider);
//                 },
//                 searchController: citySearchController,
//                 hint: 'اختر المدينة',
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: _buildTextField(
//                   controller: addressDescController, label: 'وصف العنوان'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildPaymentSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('التحصيل'),
//         Row(
//           children: [
//             Expanded(
//               child: _buildTextField(
//                 controller: deliveryCostController,
//                 label: 'سعر التوصيل',
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: _buildTextField(
//                 controller: codAmountController,
//                 label: 'التحصيل شامل التوصيل',
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//           ],
//         ),
//         Row(
//           children: [
//             Expanded(
//               child: SearchableDropdown<String>(
//                 label: 'طريقة الدفع',
//                 value: selectedPaymentMethod,
//                 items: paymentMethods,
//                 onChanged: (value) =>
//                     setState(() => selectedPaymentMethod = value!),
//                 searchController: paymentMethodSearchController,
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: SearchableDropdown<String>(
//                 label: 'طريقة التحصيل',
//                 value: selectedCollectionMethod,
//                 items: collectionMethods,
//                 onChanged: (value) =>
//                     setState(() => selectedCollectionMethod = value!),
//                 searchController: collectionMethodSearchController,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildServiceSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // _buildSectionTitle('الخدمة والطلب'),
//         SearchableDropdown<String>(
//           label: 'نوع الخدمة',
//           value: selectedServiceType,
//           items: serviceTypes,
//           onChanged: (value) => setState(() => selectedServiceType = value!),
//           searchController: serviceTypeSearchController,
//         ),
//       ],
//     );
//   }

//   Widget _buildGoodsSection(AppProvider appProvider) {
//     if (appProvider.selectedCustomer == null) {
//       return SizedBox.shrink();
//     }

//     return StreamBuilder<Inventory>(
//         stream: appProvider
//             .getCustomerInventoryStream(appProvider.selectedCustomer!.userid),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           final inventory = snapshot.data;
//           final items = inventory?.items ?? [];

//           if (items.isEmpty) {
//             return SizedBox.shrink();
//           }

//           return Card(
//             elevation: 1,
//             color: background,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildSectionTitle('البضائع'),
//                       Switch(
//                         value: showInventorySection,
//                         onChanged: (value) {
//                           setState(() {
//                             showInventorySection = value;
//                             if (!value) {
//                               selectedInventoryItems.clear();
//                             }
//                           });
//                         },
//                         activeColor: primary,
//                       ),
//                     ],
//                   ),
//                   if (showInventorySection) ...[
//                     const SizedBox(height: 16),
//                     ...List.generate(
//                       items.length,
//                       (index) {
//                         final item = items[index];
//                         final isSelected =
//                             selectedInventoryItems.containsKey(item.id);
//                         final quantity = selectedInventoryItems[item.id] ?? 0;

//                         return Card(
//                           margin: EdgeInsets.symmetric(vertical: 4),
//                           child: ListTile(
//                             title: Text(item.name),
//                             subtitle: Text(
//                               'المخزون المتاح: ${item.quantity}${item.price != null ? ' - السعر: ${item.price}' : ''}',
//                             ),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 if (isSelected) ...[
//                                   IconButton(
//                                     icon: Icon(Icons.remove_circle_outline,
//                                         color: primary),
//                                     onPressed: () {
//                                       setState(() {
//                                         if (quantity > 1) {
//                                           selectedInventoryItems[item.id!] =
//                                               quantity - 1;
//                                         } else {
//                                           selectedInventoryItems
//                                               .remove(item.id);
//                                         }
//                                       });
//                                     },
//                                   ),
//                                   Text('$quantity'),
//                                   IconButton(
//                                     icon: Icon(Icons.add_circle_outline,
//                                         color: primary),
//                                     onPressed: item.quantity > quantity
//                                         ? () {
//                                             setState(() {
//                                               selectedInventoryItems[item.id!] =
//                                                   quantity + 1;
//                                             });
//                                           }
//                                         : null,
//                                   ),
//                                 ],
//                                 Checkbox(
//                                   value: isSelected,
//                                   activeColor: primary,
//                                   onChanged: (bool? value) {
//                                     setState(() {
//                                       if (value == true) {
//                                         selectedInventoryItems[item.id!] = 1;
//                                       } else {
//                                         selectedInventoryItems.remove(item.id);
//                                       }
//                                     });
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ).toList(),
//                     if (selectedInventoryItems.isNotEmpty) ...[
//                       const SizedBox(height: 16),
//                       Text(
//                         'العناصر المحددة: ${selectedInventoryItems.length}',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: primary,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ],
//               ),
//             ),
//           );
//         });
//   }

//   Widget _buildDateFields() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildDatePicker(
//             'تاريخ التوصيل المتوقع',
//             deliveryDate,
//             (date) => setState(() => deliveryDate = date),
//           ),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: _buildDatePicker(
//             'تاريخ التسليم المتوقع',
//             expectedDeliveryDate,
//             (date) => setState(() => expectedDeliveryDate = date),
//           ),
//         ),
//       ],
//     );
//   }

//   IconData getIconForSection(String title) {
//     switch (title) {
//       case 'معلومات المرسل':
//         return Icons.location_on;
//       case 'معلومات المستلم':
//         return Icons.person;
//       case 'التحصيل':
//         return Icons.monetization_on;
//       case 'الخدمة والطلب':
//         return Icons.local_shipping;
//       default:
//         return Icons.info;
//     }
//   }

//   Widget _buildTextField({
//     required String label,
//     bool isRequired = true,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//     TextEditingController? controller,
//     int? maxLines,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextFormField(
//         controller: controller,
//         maxLines: maxLines ?? 1,
//         decoration: InputDecoration(
//           labelText: isRequired ? '$label *' : label,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Colors.grey),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Colors.grey.shade300),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: primary),
//           ),
//           filled: true,
//           fillColor: Colors.white,
//         ),
      
//         keyboardType: keyboardType,
//         validator: validator ??
//             (value) {
//               if (isRequired && (value == null || value.isEmpty)) {
//                 return 'هذا الحقل مطلوب';
//               }
//               return null;
//             },
            
//         textAlign: TextAlign.right,
//       ),
//     );
//   }

//   Widget _buildDatePicker(
//       String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: InkWell(
//         onTap: () async {
//           final DateTime? picked = await showDatePicker(
//             context: context,
//             initialDate: DateTime.now(),
//             firstDate: DateTime.now(),
//             lastDate: DateTime.now().add(Duration(days: 365)),
//             builder: (context, child) {
//               return Theme(
//                 data: Theme.of(context).copyWith(
//                   colorScheme: ColorScheme.light(
//                     primary: primary,
//                     onPrimary: Colors.white,
//                     surface: background,
//                   ),
//                 ),
//                 child: child!,
//               );
//             },
//           );
//           if (picked != null) {
//             onDateSelected(picked);
//           }
//         },
//         child: Container(
//           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//             color: Colors.white,
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Icon(Icons.calendar_today, color: primary),
//               Text(
//                 selectedDate != null
//                     ? intl.DateFormat('yyyy-MM-dd').format(selectedDate)
//                     : label,
//                 style: TextStyle(
//                   color: selectedDate != null ? Colors.black : Colors.grey,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void calculateDeliveryCost(AppProvider appProvider) {
//     if (selectedCity != null && appProvider.selectedCustomer != null) {
//       // Find customer-specific shipping route

//       UserShippingRoute? customerRoute =
//           appProvider.userShippingRoutes.firstWhere(
//         (route) => route.userId == appProvider.selectedCustomer!.userid,
//         orElse: () => appProvider.userShippingRoutes
//             .firstWhere((route) => route.userId == 'main'),
//       );

//       // Find matching route for selected city
//       ShippingRoute? matchingRoute = customerRoute.shippingRoute.firstWhere(
//         (route) =>
//             route.to == selectedCity &&
//             route.from == appProvider.selectedCustomer!.city,
//         orElse: () {
//           // If no customer-specific route found, try main route
//           UserShippingRoute mainRoute = appProvider.userShippingRoutes
//               .firstWhere((route) => route.userId == 'main');
//           return mainRoute.shippingRoute.firstWhere(
//               (route) =>
//                   route.to == selectedCity &&
//                   route.from == appProvider.selectedCustomer!.city, orElse: () {
//             UserShippingRoute mainRoute = appProvider.userShippingRoutes
//                 .firstWhere((route) => route.userId == 'main');
//             return mainRoute.shippingRoute.firstWhere(
//                 (route) =>
//                     route.to == appProvider.selectedCustomer!.city &&
//                     route.from == selectedCity, orElse: () {
//               return ShippingRoute(
//                 from: '',
//                 to: '',
//                 deliveryPrice: 0,
//                 returnPrice: 0,
//                 returnBeforeDeliveryPrice: 0,
//               );
//             });
//           });
//         },
//       );

//       if (matchingRoute.deliveryPrice > 0) {
//         setState(() {
//           deliveryCostController.text = matchingRoute.deliveryPrice.toString();
//         });
//       }
//     }
//   }
// }


