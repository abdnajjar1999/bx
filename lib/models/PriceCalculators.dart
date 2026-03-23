class UserShippingRoute {
  final List<ShippingRoute> shippingRoute;
  final String userId;
  UserShippingRoute({required this.shippingRoute, required this.userId});
  factory UserShippingRoute.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> routes =
        List<Map<String, dynamic>>.from(json['routes']);
    print(routes);
    return UserShippingRoute(
      shippingRoute: routes.map((x) => ShippingRoute.fromJson(x)).toList(),
      userId: json["userId"],
    );
  }
}

class ShippingRoute {
  final String from;
  final String to;
  final double deliveryPrice;
  final double returnPrice;
  final double returnBeforeDeliveryPrice;
  final String? packageTypeName;

  ShippingRoute({
    required this.from,
    required this.to,
    required this.deliveryPrice,
    required this.returnPrice,
    required this.returnBeforeDeliveryPrice,
    this.packageTypeName = 'العادية',
  });
  toJson() => {
        'from': from,
        'to': to,
        'deliveryPrice': deliveryPrice,
        'returnPrice': returnPrice,
        'returnBeforeDeliveryPrice': returnBeforeDeliveryPrice,
        'packageTypeName': packageTypeName ?? 'العادية',
      };
  factory ShippingRoute.fromJson(Map<String, dynamic> json) => ShippingRoute(
        from: json["from"],
        to: json["to"],
        deliveryPrice: json["deliveryPrice"] != null
            ? double.parse(json["deliveryPrice"].toString())
            : 0.0,
        returnPrice: json["returnPrice"] != null
            ? double.parse(json["returnPrice"].toString())
            : 0.0,
        returnBeforeDeliveryPrice: json["returnBeforeDeliveryPrice"] != null
            ? double.parse(json["returnBeforeDeliveryPrice"].toString())
            : 0.0,
        packageTypeName: json["packageTypeName"] ?? 'العادية',
      );

  factory ShippingRoute.fromCsv(List<dynamic> row) {
    return ShippingRoute(
      from: row[0].toString(),
      to: row[1].toString(),
      deliveryPrice: double.tryParse(row[2].toString()) ?? 0.0,
      returnPrice: double.tryParse(row[3].toString()) ?? 0.0,
      returnBeforeDeliveryPrice: double.tryParse(row[4].toString()) ?? 0.0,
    );
  }
}
