import 'dispatch_item.dart';
import 'dispatch_status.dart';

class DispatchRecord {
  final String id;
  final String dispatchCode;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String invoiceNumber;
  final DateTime? invoiceDate;
  final double invoiceAmount;
  final String transporterName;
  final String vehicleNumber;
  final String vehicleType;
  final String driverName;
  final String driverPhone;
  final String builtyNumber;
  final DateTime? builtyDate;
  final String notes;
  final DispatchStatus status;
  final List<DispatchItem> items;
  final String? builtyDocumentName;
  final String? finalInvoiceDocumentName;
  final String? deliveryProofDocumentName;
  final DateTime createdAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;

  const DispatchRecord({
    required this.id,
    required this.dispatchCode,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.invoiceNumber,
    this.invoiceDate,
    this.invoiceAmount = 0.0,
    required this.transporterName,
    required this.vehicleNumber,
    this.vehicleType = 'Truck',
    required this.driverName,
    required this.driverPhone,
    required this.builtyNumber,
    this.builtyDate,
    this.notes = '',
    required this.status,
    this.items = const [],
    this.builtyDocumentName,
    this.finalInvoiceDocumentName,
    this.deliveryProofDocumentName,
    required this.createdAt,
    this.dispatchedAt,
    this.deliveredAt,
  });

  double get totalItemsQuantity =>
      items.fold(0.0, (sum, item) => sum + item.quantity);

  double get totalAmount => invoiceAmount;

  DispatchRecord copyWith({
    String? id,
    String? dispatchCode,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? invoiceNumber,
    DateTime? invoiceDate,
    double? invoiceAmount,
    String? transporterName,
    String? vehicleNumber,
    String? vehicleType,
    String? driverName,
    String? driverPhone,
    String? builtyNumber,
    DateTime? builtyDate,
    String? notes,
    DispatchStatus? status,
    List<DispatchItem>? items,
    String? builtyDocumentName,
    String? finalInvoiceDocumentName,
    String? deliveryProofDocumentName,
    DateTime? createdAt,
    DateTime? dispatchedAt,
    DateTime? deliveredAt,
  }) {
    return DispatchRecord(
      id: id ?? this.id,
      dispatchCode: dispatchCode ?? this.dispatchCode,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      transporterName: transporterName ?? this.transporterName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      builtyNumber: builtyNumber ?? this.builtyNumber,
      builtyDate: builtyDate ?? this.builtyDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      items: items ?? this.items,
      builtyDocumentName: builtyDocumentName ?? this.builtyDocumentName,
      finalInvoiceDocumentName:
          finalInvoiceDocumentName ?? this.finalInvoiceDocumentName,
      deliveryProofDocumentName:
          deliveryProofDocumentName ?? this.deliveryProofDocumentName,
      createdAt: createdAt ?? this.createdAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
