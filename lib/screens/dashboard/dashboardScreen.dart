import '../ManageShipments/DeliveryReceiveDialog.dart';

import 'widget/customBox.dart';
import '../../shared/appProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/Shipment.dart';
import '../../models/customer.dart';

class dashboardScreen extends StatefulWidget {
  const dashboardScreen({super.key});

  @override
  State<dashboardScreen> createState() => _dashboardScreenState();
}

class _dashboardScreenState extends State<dashboardScreen> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 20, right: 15),
          alignment: Alignment.topRight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                alignment: Alignment.topRight,
                child: const Text(
                  "المخلص",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: customBox(
                    title: 'الطلبات الجديدة',
                    is_color: true,
                    count: appProvider.orders
                        .where((status) => status.status == "الطلبات الجديدة")
                        .length
                        .toString(),
                  )),
                  Expanded(
                      child: customBox(
                    title: 'بأنتظار تعيين السائق',
                    count: appProvider.orders
                        .where(
                            (status) => status.status == "بأنتظار تعيين السائق")
                        .length
                        .toString(),
                  )),
                  Expanded(
                      child: customBox(
                    title: 'في المركبة',
                    count: appProvider.orders
                        .where((status) => status.status == "في المركبة")
                        .length
                        .toString(),
                  )),
                  Expanded(
                      child: customBox(
                    title: 'تم إرجاعها',
                    count: appProvider.orders
                        .where((status) => status.status == "تم إرجاعها")
                        .length
                        .toString(),
                  )),
                  Expanded(
                      child: customBox(
                    title: 'مؤجلة لوقت اخر',
                    count: appProvider.orders
                        .where((status) => status.status == "مؤجلة لوقت اخر")
                        .length
                        .toString(),
                  )),
                  Expanded(
                      child: customBox(
                    title: 'مغلقة',
                    count: appProvider.orders
                        .where((status) => status.status == "مغلقة")
                        .length
                        .toString(),
                  )),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 500,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.white,
                          child: ListView.builder(
                            itemCount: appProvider.drivers.length,
                            itemBuilder: (context, index) {
                              final driver = appProvider.drivers[index];
                              final location =
                                  _parseLocation(driver.location ?? '');
                              int ordersCount = appProvider.orders
                                  .where((order) =>
                                      order.driverId == driver.userid &&
                                      order.status == "تم توصيلها")
                                  .length;
                              int ordersCount1 = appProvider.orders
                                  .where((order) =>
                                      order.driverId == driver.userid)
                                  .length;
                              double ordersReachedPercentage = (appProvider
                                          .orders
                                          .where((order) =>
                                              order.driverId == driver.userid &&
                                              order.status == "تم توصيلها")
                                          .length /
                                      ordersCount1) *
                                  100;

                              return InkWell(
                                onTap: () {
                                  _mapController.move(location, 12);
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(driver
                                                .profileImage ??
                                            'https://via.placeholder.com/150'),
                                        radius: 25,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              driver.username ?? 'غير معروف',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              driver.phone ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              driver.address ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          // معاينه button
                                          IconButton(
                                              onPressed: () {
                                                showDeliveryDialog(
                                                    context, index,
                                                    driverId: driver.userid);
                                              },
                                              icon: Icon(Icons.preview)),

                                          Text(
                                            '${ordersReachedPercentage.isNaN ? 0.0 : ordersReachedPercentage.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),

                                          Text(
                                            " طرد $ordersCount",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: const MapOptions(
                            initialCenter:
                                LatLng(31.9539, 35.9106), // Amman coordinates
                            initialZoom: 10.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: appProvider.drivers.map((driver) {
                                final location =
                                    _parseLocation(driver.location ?? '');
                                return Marker(
                                  point: location,
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                              driver.username ?? 'غير معروف'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('الهاتف: ${driver.phone}'),
                                              Text(
                                                  'العنوان: ${driver.address}'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.car_rental,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "أعلى عوائد المتاجر",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Handle Excel export
                                },
                                icon: const Icon(Icons.file_download),
                                label: const Text("Excel"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          buildStoreBarChart(
                              appProvider.orders, appProvider.customers),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: appProvider.orders.length > 6
                                  ? 6
                                  : appProvider.orders.length,
                              itemBuilder: (context, index) {
                                var ordersByStore = appProvider.orders
                                    .where((order) => order.username != null)
                                    .fold<Map<String, int>>({}, (map, order) {
                                      map[order.username!] =
                                          (map[order.username!] ?? 0) + 1;
                                      return map;
                                    })
                                    .entries
                                    .toList()
                                  ..sort((a, b) => b.value.compareTo(a.value));

                                if (index < ordersByStore.length) {
                                  return _buildStoreListItem(
                                    ordersByStore[index].key,
                                    ordersByStore[index].value.toString(),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "النقل حسب المدينة",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Handle Excel export
                                },
                                icon: const Icon(Icons.file_download),
                                label: const Text("Excel"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          buildBarChart(appProvider.orders),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<FlSpot> getLineChartData(List<Shipment> orders) {
    // Group orders by day and count them
    Map<DateTime, int> ordersByDay = {};
    for (var order in orders) {
      final date = DateTime(
          order.createdAt.year, order.createdAt.month, order.createdAt.day);
      ordersByDay[date] = (ordersByDay[date] ?? 0) + 1;
    }

    // Sort dates and create spots
    var sortedDates = ordersByDay.keys.toList()..sort();
    List<FlSpot> spots = [];

    // If we have data, normalize it to the chart
    if (sortedDates.isNotEmpty) {
      for (int i = 0; i < sortedDates.length; i++) {
        spots.add(FlSpot(
          i.toDouble(),
          ordersByDay[sortedDates[i]]!.toDouble(),
        ));
      }
    }

    // If no data, return empty chart
    if (spots.isEmpty) {
      return [const FlSpot(0, 0)];
    }

    return spots;
  }

  Widget buildLineChart() {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: getLineChartData(appProvider.orders),
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildBarChart(List<Shipment> orders) {
    // Count orders by city
    Map<String, int> ordersByCity = {};
    for (var order in orders) {
      ordersByCity[order.city.split(' ')[0]] =
          (ordersByCity[order.city.split(' ')[0]] ?? 0) + 1;
    }

    // Sort cities by order count
    var sortedCities = ordersByCity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 8 cities
    var topCities = sortedCities.take(8).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topCities.isEmpty ? 100 : (topCities.first.value * 1.2),
          barGroups: List.generate(topCities.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: topCities[index].value.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < topCities.length) {
                    return Transform.rotate(
                      angle: -0.5,
                      child: SizedBox(
                        width: 50,
                        child: Text(
                          topCities[value.toInt()].key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Widget buildStoreBarChart(List<Shipment> orders, List<Customer> customers) {
    // Count orders by customer/store
    Map<String, int> ordersByStore = {};
    for (var order in orders) {
      if (order.username != null) {
        ordersByStore[order.username!] =
            (ordersByStore[order.username!] ?? 0) + 1;
      }
    }

    // Sort stores by order count
    var sortedStores = ordersByStore.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 6 stores
    var topStores = sortedStores.take(6).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topStores.isEmpty ? 100 : (topStores.first.value * 1.2),
          barGroups: List.generate(topStores.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: topStores[index].value.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < topStores.length) {
                    return Transform.rotate(
                      angle: -0.5,
                      child: SizedBox(
                        width: 50,
                        child: Text(
                          topStores[value.toInt()].key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreListItem(String name, String count) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(name),
            ],
          ),
          Text("طرد $count"),
        ],
      ),
    );
  }

  Widget _buildCityListItem(String city, String count) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_city,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(city),
            ],
          ),
          Text("طرد $count"),
        ],
      ),
    );
  }
}

LatLng _parseLocation(String location) {
  try {
    final parts = location.split(',');
    return LatLng(
      double.parse(parts[0].trim()),
      double.parse(parts[1].trim()),
    );
  } catch (e) {
    // Return default location (Amman) if parsing fails
    return LatLng(31.9539, 35.9106);
  }
}
