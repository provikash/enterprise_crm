class DispatchItem {
  final String id;
  final String name;
  final String sku;
  final double quantity;
  final String unit;
  final double unitPrice;

  const DispatchItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    this.unit = 'Pcs',
    this.unitPrice = 0.0,
  });

  double get totalPrice => quantity * unitPrice;

  DispatchItem copyWith({
    String? id,
    String? name,
    String? sku,
    double? quantity,
    String? unit,
    double? unitPrice,
  }) {
    return DispatchItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
      };

  factory DispatchItem.fromJson(Map<String, dynamic> json) => DispatchItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? 'Pcs',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );
}
