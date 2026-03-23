import 'package:dropdown_button2/dropdown_button2.dart';
import 'widgets/NewPricingEntryForm.dart';
import '../dashboard/header/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/customer.dart';
import '../../models/PriceCalculators.dart';
import '../../shared/appProvider.dart';
import '../ManageShipments/widget/CustomScrollbar.dart';

class PriceCalculator extends StatefulWidget {
  const PriceCalculator({Key? key}) : super(key: key);

  @override
  State<PriceCalculator> createState() => _PriceCalculatorState();
}

class _PriceCalculatorState extends State<PriceCalculator> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();
  bool _showNewPricingForm = false;
  ShippingRoute? _editingRoute;

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Widget _buildGroupedPricingTables(AppProvider appProvider) {
    if (appProvider.selectedShippingRoute == null ||
        appProvider.selectedShippingRoute!.shippingRoute.isEmpty) {
      return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد تسعيرات متوفرة')));
    }

    // Group routes by packageTypeName
    Map<String, List<ShippingRoute>> groupedRoutes = {};
    for (var route in appProvider.selectedShippingRoute!.shippingRoute) {
      String type = route.packageTypeName ?? 'العادية';
      if (!groupedRoutes.containsKey(type)) {
        groupedRoutes[type] = [];
      }
      groupedRoutes[type]!.add(route);
    }

    return Column(
      children: groupedRoutes.entries.map((entry) {
        String typeName = entry.key;
        List<ShippingRoute> routes = entry.value;

        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            'تسعيرة $typeName',
            style: TextStyle(fontWeight: FontWeight.bold, color: primary),
          ),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                  columns: const [
                    DataColumn(label: SizedBox(width: 30)),
                    DataColumn(label: Text('من المنطقة')),
                    DataColumn(label: Padding(padding: EdgeInsets.all(8.0), child: Text('إلى المنطقة'))),
                    DataColumn(label: Padding(padding: EdgeInsets.all(8.0), child: Text('سعر التوصيل'))),
                    DataColumn(label: Padding(padding: EdgeInsets.all(8.0), child: Text('سعر الإرجاع'))),
                    DataColumn(label: Padding(padding: EdgeInsets.all(8.0), child: Text('سعر الإرجاع قبل التوصيل'))),
                    DataColumn(label: Padding(padding: EdgeInsets.all(8.0), child: Text(''))),
                  ],
                  rows: routes.map((route) => DataRow(
                      cells: [
                        const DataCell(Icon(Icons.arrow_forward)),
                        DataCell(Text(route.from)),
                        DataCell(Text(route.to)),
                        DataCell(Text(route.deliveryPrice.toString())),
                        DataCell(Text(route.returnPrice.toString())),
                        DataCell(route.returnBeforeDeliveryPrice > 0 ? Text(route.returnBeforeDeliveryPrice.toString()) : const Text('0')),
                        DataCell(Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    _editingRoute = route;
                                    _showNewPricingForm = true;
                                  });
                                },
                                icon: Icon(Icons.edit, color: primary)),
                            IconButton(
                                onPressed: () {
                                  appProvider.deleteShippingRoute(route);
                                },
                                icon: Icon(Icons.delete, color: Colors.red[400])),
                          ],
                        )),
                      ],
                  )).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "حاسبه الاسعار",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primary),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DropdownButton2<Customer>(
                      isExpanded: true,
                      customButton: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                appProvider.selectedCustomer?.username ??
                                    'المتجر/الزبون',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (appProvider.selectedCustomer != null)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    appProvider.selectedCustomer = null;
                                    appProvider
                                        .selectedShippingRoute = appProvider
                                            .userShippingRoutes.isNotEmpty
                                        ? appProvider.userShippingRoutes
                                            .where((e) => e.userId == 'main')
                                            .first
                                        : null;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 20),
                              )
                            else
                              const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      items: appProvider.customers.map((Customer value) {
                        return DropdownMenuItem<Customer>(
                          value: value,
                          child: Text(
                            value.username,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          appProvider.selectedCustomer = value!;
                          List<UserShippingRoute> shippingRoutes = appProvider
                              .userShippingRoutes
                              .where(
                                  (element) => element.userId == value.userid)
                              .toList();
                          appProvider.selectedShippingRoute =
                              shippingRoutes.isNotEmpty
                                  ? shippingRoutes[0]
                                  : null;
                        });
                      },
                      dropdownSearchData: DropdownSearchData(
                        searchController: textEditingController,
                        searchInnerWidgetHeight: 50,
                        searchInnerWidget: Container(
                          height: 50,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: TextFormField(
                            expands: true,
                            maxLines: null,
                            controller: textEditingController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'بحث عن زبون...',
                              hintStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        searchMatchFn: (item, searchValue) {
                          return item.value!.username
                              .toLowerCase()
                              .contains(searchValue.toLowerCase());
                        },
                      ),
                      onMenuStateChange: (isOpen) {
                        if (!isOpen) {
                          textEditingController.clear();
                        }
                      },
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: () => appProvider.importPricesFromExcel(context),
                  icon: const Icon(Icons.file_download),
                  label: const Text('استيراد من Excel'),
                  style: TextButton.styleFrom(foregroundColor: primary),
                ),
                TextButton.icon(
                  onPressed: () => appProvider.exportPricesToExcel(context),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('تصدير إلى Excel'),
                  style: TextButton.styleFrom(foregroundColor: primary),
                ),
                // TextButton.icon(
                //   onPressed: () {},
                //   icon: const Icon(Icons.local_shipping),
                //   label: const Text('عرض الحركات'),
                //   style: TextButton.styleFrom(foregroundColor: primary),
                // ),
                // TextButton.icon(
                //   onPressed: () {},
                //   icon: const Icon(Icons.person_add),
                //   label: const Text('تخصيص المستخدم للزبون'),
                //   style: TextButton.styleFrom(foregroundColor: primary),
                // ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showNewPricingForm = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة تسعيرة جديدة'),
                  style: TextButton.styleFrom(foregroundColor: primary),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _buildGroupedPricingTables(appProvider),
              ),
            ),
            if (_showNewPricingForm)
              NewPricingEntryForm(
                appProvider: appProvider,
                initialRoute: _editingRoute,
                onClose: () {
                  setState(() {
                    _showNewPricingForm = false;
                    _editingRoute = null;
                  });
                },
                onSubmit: (route) {
                  if (_editingRoute != null) {
                    appProvider.replaceShippingRoute(_editingRoute!, route);
                  } else {
                    appProvider.updatePriceCalculator(route);
                  }
                },
              ),
          ],
        ),
      );
    });
  }
}
