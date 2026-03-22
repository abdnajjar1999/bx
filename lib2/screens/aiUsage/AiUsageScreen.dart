import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../aiAgent/tools.dart';
import '../../shared/appProvider.dart';
import '../../aiAgent/aiAgentSidePanal.dart';

class AiUsageScreen extends StatefulWidget {
  const AiUsageScreen({Key? key}) : super(key: key);

  @override
  State<AiUsageScreen> createState() => _AiUsageScreenState();
}

class _AiUsageScreenState extends State<AiUsageScreen> {
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime.now();
double addShipmentCost = 0;
double otherCost = 0;
int addShipmentLimit = 500;
int otherLimit = 500;
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Get usage data for selected date range
        final Usage dateRangeUsage = Usage.dateUsage(
          appProvider.aiUsages,
          startDate,
          endDate,
        );

        final List<Usage> dateRangeUsageList = Usage.dateUsageList(
          appProvider.aiUsages,
          startDate,
          endDate,
        );
        final List<String> dateRangeFunctionCalls =
            dateRangeUsage.functionCalls;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and date filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إحصائيات استخدام الذكاء الاصطناعي',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Row(
                      children: [
                        _buildDatePicker(
                          label: 'من',
                          selectedDate: startDate,
                          onDateSelected: (date) {
                            if (date != null) {
                              setState(() => startDate = date);
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildDatePicker(
                          label: 'إلى',
                          selectedDate: endDate,
                          onDateSelected: (date) {
                            if (date != null) {
                              setState(() => endDate = date);
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildQuickDateButton('اليوم', () {
                          setState(() {
                            startDate = DateTime(DateTime.now().year,
                                DateTime.now().month, DateTime.now().day);
                            endDate = DateTime.now();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildQuickDateButton('هذا الأسبوع', () {
                          setState(() {
                            startDate = DateTime.now().subtract(
                                Duration(days: DateTime.now().weekday - 1));
                            endDate = DateTime.now();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildQuickDateButton('هذا الشهر', () {
                          setState(() {
                            startDate = DateTime(
                                DateTime.now().year, DateTime.now().month, 1);
                            endDate = DateTime.now();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildQuickDateButton('الشهر الماضي', () {
                          setState(() {
                            final lastMonth = DateTime.now()
                                .subtract(Duration(days: DateTime.now().day));
                            startDate =
                                DateTime(lastMonth.year, lastMonth.month, 1);
                            endDate = DateTime(
                                DateTime.now().year, DateTime.now().month, 0);
                          });
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Statistics cards
                if(kDebugMode)
                Row(
                  children: [
                    Flexible(
                      child: _buildStatCard(
                        'عدد الاستخدامات',
                        dateRangeUsage.count.toString(),
                        Icons.touch_app,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: _buildStatCard(
                        'مجموع المدخلات',
                        NumberFormat('#,###')
                            .format(dateRangeUsage.promptTokenCount),
                        Icons.input,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: _buildStatCard(
                        'مجموع المخرجات',
                        NumberFormat('#,###')
                            .format(dateRangeUsage.candidatesTokenCount),
                        Icons.output,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: _buildStatCard(
                        'متوسط المدخلات لكل استخدام',
                        dateRangeUsage.count > 0
                            ? NumberFormat('#,###').format(
                                dateRangeUsage.promptTokenCount ~/
                                    dateRangeUsage.count)
                            : '0',
                        Icons.analytics,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Pricing Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money,
                                color: Colors.green, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'تفاصيل التسعير',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Flexible(
                              child: _buildPricingDetail(
                                'الحد الشهري المجاني للشحنات',
                                '$addShipmentLimit',
                                Icons.card_giftcard,
                                Colors.purple,
                                subtitle: 'لإضافة الشحنات',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: _buildPricingDetail(
                                'الحد الشهري المجاني للعمليات',
                                '$otherLimit',
                                Icons.card_giftcard,
                                Colors.purple,
                                subtitle: 'للعمليات الأخرى',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: _buildPricingDetail(
                                'الاستخدام الشهري',
                                dateRangeFunctionCalls.length.toString(),
                                Icons.history,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Flexible(
                              child: _buildPricingDetail(
                                'عدد إضافات الشحنات',
                                '${dateRangeFunctionCalls.where((call) => call == addShipmentToolName).length}',
                                Icons.local_shipping,
                                Colors.orange,
                                subtitle: '${addShipmentCost} AUD لكل إضافة بعد ${addShipmentLimit} شحنة',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: _buildPricingDetail(
                                'عدد العمليات الأخرى',
                                '${dateRangeFunctionCalls.where((call) => call != addShipmentToolName).length}',
                                Icons.miscellaneous_services,
                                Colors.indigo,
                                subtitle: '${otherCost} AUD لكل عملية بعد ${otherLimit} عملية',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: _buildPricingDetail(
                                'التكلفة الإجمالية',
                                () {
                                  final addShipmentCalls =
                                      dateRangeFunctionCalls
                                          .where(
                                              (call) => call == addShipmentToolName)
                                          .length;
                                  final otherCalls = dateRangeFunctionCalls
                                      .where((call) => call != addShipmentToolName)
                                      .length;

                                  final paidAddShipmentCalls =
                                      max(0, addShipmentCalls - addShipmentLimit);
                                  final paidOtherCalls =
                                      max(0, otherCalls - otherLimit);

                                    final cost = (paidAddShipmentCalls * addShipmentCost) +
                                      (paidOtherCalls * otherCost);
                                  return '${cost.toStringAsFixed(2)} AUD';
                                }(),
                                Icons.paid,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Usage over time chart
                SizedBox(
                  height: 400, // Fixed height for the chart section
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الاستخدام خلال الوقت',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 1,
                                  verticalInterval: 1,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.withOpacity(0.2),
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.withOpacity(0.2),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() <
                                                dateRangeUsageList.length) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              DateFormat('MM/dd').format(
                                                  dateRangeUsageList[
                                                          value.toInt()]
                                                      .timestamp),
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 12),
                                        );
                                      },
                                      reservedSize: 42,
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                minX: 0,
                                maxX:
                                    (dateRangeUsageList.length - 1).toDouble(),
                                minY: 0,
                                maxY: dateRangeUsageList.isEmpty
                                    ? 10
                                    : dateRangeUsageList
                                            .map((e) => e.count)
                                            .reduce((a, b) => a > b ? a : b) *
                                        1.2,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(
                                      dateRangeUsageList.length,
                                      (index) => FlSpot(
                                        index.toDouble(),
                                        dateRangeUsageList[index]
                                            .count
                                            .toDouble(),
                                      ),
                                    ),
                                    isCurved: true,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Function calls distribution chart
                SizedBox(
                  height: 400,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'توزيع العمليات',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: buildFunctionCallsBarChart(
                                dateRangeFunctionCalls),
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

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return Row(
      children: [
        Text(label),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            onDateSelected(picked);
          },
          child: Text(DateFormat('yyyy/MM/dd').format(selectedDate)),
        ),
      ],
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      child: Text(label),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingDetail(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildFunctionCallsBarChart(List<String> functionCalls) {
    // Count function calls by type
    Map<String, int> callsByType = {};
    for (var call in functionCalls) {
      callsByType[call] = (callsByType[call] ?? 0) + 1;
    }

    // Sort function types by call count
    var sortedCalls = callsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 8 function types
    var topCalls = sortedCalls.take(8).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topCalls.isEmpty ? 100 : (topCalls.first.value * 1.2),
        barGroups: List.generate(topCalls.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: topCalls[index].value.toDouble(),
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
                if (value.toInt() < topCalls.length) {
                  return Transform.rotate(
                    angle: -0.5,
                    child: SizedBox(
                      width: 80,
                      child: Text(
                        topCalls[value.toInt()].key,
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
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}
