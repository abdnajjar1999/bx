import 'package:flutter/material.dart';
import 'package:good_line_delivery/screens/ManageShipments/widget/CustomDropdown.dart';
import 'package:intl/intl.dart';

import '../../../main.dart';
import '../../../models/Driver.dart';
import '../../../models/Shelf.dart';
import '../../../models/Shipment.dart';
import '../../../shared/appProvider.dart';
import '../../../shared/constants.dart';
import '../widget/CustomTextField.dart';
import '../widget/CounterTextFormField.dart';

void showChangeStatusBottomSheet(
    {Shipment? shipment,
    required AppProvider appProvider,
    required BuildContext context,
    List<String> selectedOrderIds = const []}) {
  var status = shipment?.status;
  TextEditingController noteController = TextEditingController();
  TextEditingController returnedOrderCollectionController =
      TextEditingController(
          text: shipment?.returnedOrderCollection.toString() ?? '0.0');
  Shelf? shelf =
      appProvider.shelves.where((e) => e.id == shipment?.shelfId).firstOrNull;
  Driver? driver = appProvider.drivers
      .where((e) => e.userid == shipment?.driverId)
      .firstOrNull;
  String? shelfId = shipment?.shelfId;
  String? note;
  bool receivedMoneyFromCustomer = false;
  bool getMoneyFromUserPalance = false;
  OrderPossession orderPossession =
      shipment?.orderPossession ?? OrderPossession.branch;
  DateTime? postponementDate = shipment?.postponementDate;
  double newPrice = shipment?.deliveryCost ?? 0.0;
  bool priceChanged = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "تغيير الحالة ل ${shipment != null ? "1" : selectedOrderIds.length} طرد ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      //color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildDropdownField(
                    label: 'الحاله',
                    hint: 'اختر حالة',
                    value: status,
                    items: statusOptions.keys
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(left: 2),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(e),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    width: 16,
                                    height: 16,
                                  ),
                                  Text(e),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (["في المركبة", "تم إرجاعها", "تم توصيلها بشكل جزئي"]
                          .contains(value)) {
                        orderPossession = OrderPossession.driverShipping;
                      }
                      setState(() {
                        status = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if ([
                    "بانتظار تعيين السائق",
                    "بانتظار موافقة السائق",
                    "رفضها السائق",
                    "بانتظار التحميل",
                    "في المركبة",
                    "تم توصيلها",
                    "تم توصيلها بشكل جزئي",
                    "تم إرجاعها",
                    "مؤجلة لوقت آخر"
                  ].contains(status))
                    buildDropdownField(
                      isRequired: true,
                      items: appProvider.drivers
                          .map((driver) => DropdownMenuItem<Driver>(
                                value: driver,
                                child: Text(driver.username ?? ""),
                              ))
                          .toList(),
                      label:
                          'السائق${(status == "تم توصيلها" || status == "في المركبة") ? " *" : ""}',
                      hint: 'اختر سائق',
                      value: driver,
                      onChanged: (value) {
                        setState(() {
                          driver = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  if (status == "على الرفوف")
//make a dropdown to select shelf
                    buildDropdownField(
                      isRequired: true,
                      items: appProvider.shelves
                          .map((shelf) => DropdownMenuItem<Shelf>(
                                value: shelf,
                                child: Text(shelf.name ?? ""),
                              ))
                          .toList(),
                      label: status == "على الرفوف" ? 'الرف *' : 'الرف',
                      hint: 'اختر رف',
                      value: shelf,
                      onChanged: (value) {
                        setState(() {
                          shelf = value;
                          shelfId = value?.id;
                        });
                      },
                    ),
                  if (status == "مؤجلة لوقت آخر")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate:
                                          postponementDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Colors.yellow[700]!,
                                              onPrimary: Colors.black,
                                              onSurface: Colors.black,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        postponementDate = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          postponementDate != null
                                              ? 'تاريخ التأجيل: ${DateFormat('yyyy-MM-dd').format(postponementDate!)}'
                                              : 'اختر تاريخ التأجيل *',
                                          style: TextStyle(
                                            color: postponementDate != null
                                                ? Colors.black
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    postponementDate = DateTime.now()
                                        .add(const Duration(days: 1));
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow[700],
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                child: const Text('غداً'),
                              ),
                            ],
                          ),
                        ),
                        if (shipment != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                flex: 2,
                                child: Text('تعديل السعر:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CounterTextFormField(
                                    initialValue: newPrice,
                                    min: 0,
                                    step: 0.25,
                                    isInteger: false,
                                    onChanged: (value) {
                                      setState(() {
                                        newPrice =
                                            double.tryParse(value) ?? newPrice;
                                        priceChanged = true;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    newPrice = newPrice * 2;
                                    priceChanged = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow[700],
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                child: const Text('x2'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  if (status == "تم إرجاعها")
                    Column(
                      children: [
                        // قبل الوصول
                        RadioListTile<String>(
                          title: const Text('فشل بالتوصيل'),
                          value: 'فشل بالتوصيل',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = false;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('حادث'),
                          value: 'حادث',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = false;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('رفض قبل الوصول'),
                          value: 'رفض قبل الوصول',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = false;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('الغاء قبل الوصول'),
                          value: 'الغاء قبل الوصول',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = false;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('عدم رد'),
                          value: 'عدم رد',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = false;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('تجاوز عدد مرات المحاولات'),
                          value: 'تجاوز عدد مرات المحاولات',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = false;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('الغاء الطلب (قبل الوصول)'),
                          value: 'الغاء الطلب (قبل الوصول)',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = false;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),

                        // بعد الوصول
                        Text(
                          'بعد الوصول',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Divider(),
                        RadioListTile<String>(
                          title: const Text('الغاء الطلب (بعد الوصول)'),
                          value: 'الغاء الطلب (بعد الوصول)',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = true;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),

                        RadioListTile<String>(
                          title: const Text('مرجع مؤجل'),
                          value: 'مرجع مؤجل',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = true;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),

                        RadioListTile<String>(
                          title: const Text('لا رد بعد الوصول'),
                          value: 'لا رد بعد الوصول',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = true;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('رفض بعد الوصول'),
                          value: 'رفض بعد الوصول',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = true;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('عدم حضور'),
                          value: 'عدم حضور',
                          groupValue: note,
                          onChanged: (value) {
                            setState(() {
                              getMoneyFromUserPalance = true;
                              status = 'تم إرجاعها';
                              note = value;
                              noteController.text = value ?? '';
                            });
                          },
                        ),
                      ],
                    ),
                  if (["ملغاة", "تم إرجاعها"].contains(status))
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: CustomTextField(
                            readOnly: status == "تم إرجاعها",
                            onChanged: (value) {
                              setState(() {
                                note = value;
                              });
                            },
                            labelText: 'ملاحظات',
                            hintText: "ادخل ملاحظات",
                            prefixIcon: Icons.note,
                            controller: noteController,
                          ),
                        ),
                        if (status == "تم إرجاعها")
                          Column(
                            children: [
                              CheckboxListTile(
                                title: Text('المستلم دفع الاجور'),
                                value: receivedMoneyFromCustomer,
                                onChanged: (bool? value) {
                                  setState(() {
                                    receivedMoneyFromCustomer = value ?? false;
                                    if (receivedMoneyFromCustomer) {
                                      returnedOrderCollectionController.text =
                                          (shipment?.deliveryCost ?? 0.0)
                                              .toString();
                                    }
                                  });
                                },
                              ),
                              if (!receivedMoneyFromCustomer)
                                CustomTextField(
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                  labelText: 'اجور الطلب المرتجع المستلمة',
                                  hintText: "ادخل المبلغ المستلم",
                                  prefixIcon: Icons.money,
                                  controller: returnedOrderCollectionController,
                                  keyboardType: TextInputType.number,
                                ),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (status == "تم إرجاعها" ||
                      status == "في المركبة" ||
                      status == "تم توصيلها بشكل جزئي")
                    buildDropdownField(
                      items: OrderPossession.values
                          .where((e) => e.name.contains("driver"))
                          .map((e) => DropdownMenuItem<OrderPossession>(
                                value: e,
                                child: Text(e.nameAr),
                              ))
                          .toList(),
                      label: 'يوجد مع',
                      hint: 'اختر من يوجد معه',
                      value: orderPossession,
                      onChanged: (value) {
                        setState(() {
                          orderPossession = value;
                        });
                      },
                    ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (status == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('الرجاء اختيار الحالة'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if ((status == "بانتظار موافقة السائق" ||
                                    status == "رفضها السائق" ||
                                    status == "بانتظار التحميل" ||
                                    status == "في المركبة" ||
                                    status == "تم توصيلها" ||
                                    status == "تم توصيلها بشكل جزئي" ||
                                    status == "تم إرجاعها") &&
                                driver == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'يجب اختيار السائق عند تغيير الحالة'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (status == "على الرفوف" && shelfId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'يجب اختيار الرف عند تغيير الحالة إلى "على الرفوف"'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (status == "مؤجلة لوقت آخر" &&
                                postponementDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('يجب اختيار تاريخ التأجيل'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (shipment != null) {
                              appProvider.updateOrderStatus(
                                shipment.orderId,
                                status!,
                                driver,
                                note,
                                getMoneyFromUserPalance: (status == "ملغاة" ||
                                        status == "تم إرجاعها")
                                    ? receivedMoneyFromCustomer
                                        ? false
                                        : getMoneyFromUserPalance
                                    : null,
                                receivedMoneyFromCustomer: (status == "ملغاة" ||
                                        status == "تم إرجاعها")
                                    ? receivedMoneyFromCustomer
                                    : null,
                                returnedAfterDelivery: getMoneyFromUserPalance,
                                returnedOrderCollection: double.tryParse(
                                        returnedOrderCollectionController
                                            .text) ??
                                    0.0,
                                shelf: shelf,
                                orderPossession: orderPossession,
                                postponementDate: status == "مؤجلة لوقت آخر"
                                    ? postponementDate
                                    : null,
                              );
                              if (status == "مؤجلة لوقت آخر" &&
                                  priceChanged &&
                                  newPrice != shipment.deliveryCost) {
                                appProvider.updateOrderPrice(
                                  shipment.orderId,
                                  shipment.deliveryCost,
                                  newPrice,
                                  shipment.userId,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تغيير السعر بنجاح'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              selectedOrderIds.forEach((element) {
                                appProvider.updateOrderStatus(
                                    element, status!, driver, note,
                                    receivedMoneyFromCustomer:
                                        (status == "ملغاة" ||
                                                status == "تم إرجاعها")
                                            ? receivedMoneyFromCustomer
                                            : null,
                                    getMoneyFromUserPalance:
                                        (status == "ملغاة" ||
                                                status == "تم إرجاعها")
                                            ? receivedMoneyFromCustomer
                                                ? false
                                                : getMoneyFromUserPalance
                                            : null,
                                    returnedAfterDelivery:
                                        getMoneyFromUserPalance,
                                    returnedOrderCollection: double.tryParse(
                                            returnedOrderCollectionController
                                                .text) ??
                                        0.0,
                                    shelf: shelf,
                                    orderPossession: orderPossession,
                                    postponementDate: status == "مؤجلة لوقت آخر"
                                        ? postponementDate
                                        : null);
                              });
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'تم',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}
