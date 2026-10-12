import '../entities/dispatch_item.dart';

class CreateDispatchInput {
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
  final List<DispatchItem> items;

  const CreateDispatchInput({
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
    this.items = const [],
  });

  String? validate() {
    if (customerName.trim().isEmpty) return 'Customer name is required';
    if (customerPhone.trim().isEmpty) return 'Customer phone is required';
    if (deliveryAddress.trim().isEmpty) return 'Delivery address is required';
    if (invoiceNumber.trim().isEmpty) return 'Invoice number is required';
    if (vehicleNumber.trim().isEmpty) return 'Vehicle number is required';
    if (driverName.trim().isEmpty) return 'Driver name is required';
    if (builtyNumber.trim().isEmpty) return 'Builty / LR number is required';
    if (items.isEmpty) return 'At least one dispatch item is required';
    return null;
  }
}
