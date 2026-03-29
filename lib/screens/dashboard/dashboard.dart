// import 'package:durub_ali/aiAgent/aiAgentSidePanal.dart';
// import 'package:durub_ali/aiAgent/tools.dart';
import 'package:good_line_delivery/screens/settings/ExcelImportSettingsScreen.dart';
import 'package:provider/provider.dart';
import 'package:good_line_delivery/aiAgent/aiAgentSidePanal.dart';
import 'package:good_line_delivery/aiAgent/tools.dart';
import 'package:good_line_delivery/screens/dashboard/header/showSideDrawerDialog.dart';

import '../settings/PackageTypesScreen.dart';
import '../PricingCalculator/driverPricingCalculator.dart';
import '../aiUsage/AiUsageScreen.dart';

import '../../shared/appProvider.dart';
import '../../shared/constants.dart';

import '../../main.dart';
import '../Accounting/BankAccounts.dart';
import '../Accounting/ExpensesScreen.dart';
import '../Accounting/StatisticsScreen.dart';
import '../AreaManagement/AreaManagement.dart';
import '../InventoryManagement/InventoryManagementScreen.dart';
import '../Shelves/ShelvesManagementScreen.dart';
import '../ManageShipments/ManageShipmentsScreen/ManageShipmentsScreen.dart';
import '../ReturnedOrders/AllReturnedorders.dart';
import '../ReturnedOrders/ReturnedOrdersScreen.dart' show ReturnedOrdersScreen;
import '../BundledShipments/BundledShipmentsScreen.dart';
import '../warehouse/SupplyOrdersScreen.dart';
import 'drawer/SideDrawer.dart';
import '../users/DriversScreen.dart';
import '../users/EmployeesScreen.dart';
import '../users/CustomersScreen.dart';
import '../../whatsapp/Whatsapp.dart';
import 'package:flutter/material.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../Accounting/Accounting.dart';
import '../AddOrder/AddOrderForm.dart';
import '../PricingCalculator/PricingCalculator.dart';
import '../VehicleManagement/VehicleListScreen.dart';
import '../exportedInvoices/ExportedInvoices.dart';
import '../receiptedInvoices/ReceiptedInvoices.dart';
import 'dashboardScreen.dart';
import 'header/header.dart';
import '../files/FilesScreen.dart';
import '../NationalBilling/NationalBillingScreen.dart';
import '../Tours/ToursScreen.dart';
import '../Tours/CollectionToursScreen.dart';
import 'package:draggable_float_widget/draggable_float_widget.dart';

class dashboard extends StatefulWidget {
  const dashboard({super.key});

  @override
  State<dashboard> createState() => _dashboardState();
}

class _dashboardState extends State<dashboard> {
  int selectedIndex = 1;
  bool _hasInternet = true;
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;
  late StreamController<OperateEvent> eventStreamController;

  @override
  void initState() {
    super.initState();
    eventStreamController = StreamController.broadcast();
    eventStreamController.add(OperateEvent.OPERATE_HIDE);

    //_checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Error checking connectivity: $e');
      setState(() {
        _hasInternet = false;
      });
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _hasInternet = result != ConnectivityResult.none;
    });
  }

  void onTileSelected(int index) {
    if (MediaQuery.of(context).size.width < 1100) {
      Navigator.pop(context);
    }
    if (MediaQuery.of(context).size.width < 700) {
      setState(() {
        selectedIndex = 1;
      });
      if (index != 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكنك الدخول إلى هذه الصفحة على الجوال'),
          ),
        );
      }
      return;
    }

    if (userPermissions?.contains(drawerTitles[index]) ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ليس لديك صلاحيات للدخول إلى هذه الصفحة"),
        ),
      );

      return;
    }

    setState(() {
      selectedIndex = index;
    });

    // Close drawer on mobile when item is selected
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (!_hasInternet) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.signal_wifi_off, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkConnectivity,
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          endDrawer: AddOrderForm(),
          // Add drawer for mobile view
          drawer: !isDesktop
              ? SideDrawer(
                  selectedIndex: selectedIndex,
                  onTileSelected: onTileSelected,
                )
              : null,
          body: false
              ? Center(
                  child: Text(
                      'we dont support mobile right now please open from desktop'),
                )
              : Stack(
                  children: [
                    Row(
                      children: [
                        // Show SideDrawer only in desktop mode
                        if (isDesktop)
                          SideDrawer(
                            selectedIndex: selectedIndex,
                            onTileSelected: onTileSelected,
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              // Add AppBar for mobile view to show drawer icon
                              if (!isDesktop)
                                AppBar(
                                  title: Text(
                                    KcompanyName,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  centerTitle: true,
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  leading: Builder(
                                    builder: (context) => IconButton(
                                      icon: const Icon(Icons.menu,
                                          color: Colors.black),
                                      onPressed: () =>
                                          Scaffold.of(context).openDrawer(),
                                    ),
                                  ),
                                  actions: [SizedBox()],
                                ),
                              header(),
                              Expanded(
                                child: _getScreenForIndex(selectedIndex),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    DraggableFloatWidget(
                        child: MouseRegion(
                          onEnter: (_) {
                            eventStreamController
                                .add(OperateEvent.OPERATE_SHOW);
                          },
                          onExit: (_) {
                            eventStreamController
                                .add(OperateEvent.OPERATE_HIDE);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(5),
                            child: Material(
                              color: Colors.transparent,
                              child: Icon(
                                Icons.smart_toy,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        eventStreamController: eventStreamController,
                        config: DraggableFloatWidgetBaseConfig(
                            exposedPartWidthWhenHidden: 10,
                            delayShowDuration: Duration.zero,
                            isFullScreen: false,
                            initPositionYInTop: true,
                            initPositionXInLeft: false,
                            initPositionYMarginBorder: 50,
                            borderBottom: 20 + defaultBorderWidth,
                            borderLeft: 0,
                            borderRight: 0),
                        onTap: () {
                          showSideDrawerDialog(
                              context: context,
                              width: MediaQuery.of(context).size.width * 0.3,
                              side: DrawerSide.right,
                              child: AiAgentSidePanal(
                                  onUsage: (usage) {
                                    // usage is a Usage object
                                    appProvider.saveAiUsage(usage.toJson());
                                  },
                                  onClosed: () {
                                    Navigator.pop(context);
                                  },
                                  checkFunctionCalls:
                                      (functionCall, chat) async {
                                    return await appProvider
                                        .handleAiAgentFunctionCall(
                                            functionCall, chat);
                                  },
                                  tools: [
                                    addShipmentTool(
                                      customers: appProvider.customers,
                                      cities: appProvider.citiesAndPlacesNames,
                                      drivers: appProvider.drivers,
                                    ),
                                    assignDriverTool(
                                      drivers: appProvider.drivers,
                                    ),
                                    getOrdersInfoTool()
                                  ],
                                  prompts: [
                                    "تقدر تساعدني بايه؟",
                                    "اريد اضافة شحنة",
                                    "كيف اضيف عميل جديد؟",
                                    "كيف اضيف سائق جديد؟",
                                    "كيف اتابع الشحنات؟",
                                  ]));
                        }),
                  ],
                ),
        ),
      );
    });
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return dashboardScreen();
      case 1:
      case 2:
        return ManageShipmentsScreen(selectedIndex: index);
      case 3:
        return VehicleListScreen();
      case 4:
        return DriversScreen();
      case 5:
        return CustomersScreen();
      case 6:
      case 7:
      case 8:
        return Accounting(selectedIndex: index);
      case 9:
        return ExportedInvoices();
      case 10:
        return PriceCalculator();
      case 11:
        return StatisticsScreen();
      case 12:
        return ExpensesScreen();
      case 13:
        return FilesScreen();
      case 14:
        return Whatsapp();
      case 15:
        return AreaManagement();
      case 16:
      case 37:
      case 38:
        return AllReturnedOrders(sectionIndex: index);
      case 17:
      case 32:
      case 33:
      case 34:
      case 35:
      case 36:
        return ReturnedOrdersScreen(sectionIndex: index);
      case 18:
        return BankAccountsScreen();
      case 19:
        return ReceiptedInvoices();
      case 20:
        return InventoryManagementScreen();
      case 21:
        return DriverPricingCalculator();
      case 22:
        return ShelvesManagementScreen();
      case 23:
        return AiUsageScreen();
      case 24:
        return BundledShipmentsScreen();
      case 25:
        return NationalBillingScreen();
      case 26:
        return SupplyOrdersScreen();
      case 27:
        return ToursScreen();
      case 28:
        return CollectionToursScreen();
      case 29:
        return EmployeesScreen();
      case 30:
        return ExcelImportSettingsScreen();
      case 31:
        return PackageTypesScreen();
      default:
        // Fallback for any unexpected index values
        return dashboardScreen(); // Return default dashboard as fallback
    }
  }
}
