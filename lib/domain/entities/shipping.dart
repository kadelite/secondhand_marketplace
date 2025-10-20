import 'package:equatable/equatable.dart';

enum CourierService {
  fedex,
  dhl,
  ups,
  usps,
  localCourier,
}

enum ShippingStatus {
  pending,
  labelCreated,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  failed,
  returned,
  cancelled,
}

enum ShippingType {
  standard,
  express,
  overnight,
  international,
}

class Shipping extends Equatable {
  const Shipping({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.buyerId,
    required this.productId,
    required this.fromAddress,
    required this.toAddress,
    required this.courierService,
    required this.shippingType,
    required this.status,
    this.trackingNumber,
    this.labelUrl,
    this.estimatedDelivery,
    this.actualDelivery,
    this.cost = 0.0,
    this.weight,
    this.dimensions,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  final String id;
  final String orderId;
  final String sellerId;
  final String buyerId;
  final String productId;
  final Address fromAddress;
  final Address toAddress;
  final CourierService courierService;
  final ShippingType shippingType;
  final ShippingStatus status;
  final String? trackingNumber;
  final String? labelUrl;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final double cost;
  final double? weight;
  final Dimensions? dimensions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  Shipping copyWith({
    String? id,
    String? orderId,
    String? sellerId,
    String? buyerId,
    String? productId,
    Address? fromAddress,
    Address? toAddress,
    CourierService? courierService,
    ShippingType? shippingType,
    ShippingStatus? status,
    String? trackingNumber,
    String? labelUrl,
    DateTime? estimatedDelivery,
    DateTime? actualDelivery,
    double? cost,
    double? weight,
    Dimensions? dimensions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return Shipping(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      productId: productId ?? this.productId,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      courierService: courierService ?? this.courierService,
      shippingType: shippingType ?? this.shippingType,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      labelUrl: labelUrl ?? this.labelUrl,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      cost: cost ?? this.cost,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        sellerId,
        buyerId,
        productId,
        fromAddress,
        toAddress,
        courierService,
        shippingType,
        status,
        trackingNumber,
        labelUrl,
        estimatedDelivery,
        actualDelivery,
        cost,
        weight,
        dimensions,
        createdAt,
        updatedAt,
        notes,
      ];
}

class Address extends Equatable {
  const Address({
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phoneNumber,
    this.isResidential = true,
  });

  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phoneNumber;
  final bool isResidential;

  @override
  List<Object?> get props => [
        fullName,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
        phoneNumber,
        isResidential,
      ];
}

class Dimensions extends Equatable {
  const Dimensions({
    required this.length,
    required this.width,
    required this.height,
    this.unit = 'cm',
  });

  final double length;
  final double width;
  final double height;
  final String unit;

  @override
  List<Object?> get props => [length, width, height, unit];
}

class TrackingUpdate extends Equatable {
  const TrackingUpdate({
    required this.id,
    required this.shippingId,
    required this.status,
    required this.location,
    required this.timestamp,
    this.description,
    this.estimatedDelivery,
  });

  final String id;
  final String shippingId;
  final ShippingStatus status;
  final String location;
  final DateTime timestamp;
  final String? description;
  final DateTime? estimatedDelivery;

  @override
  List<Object?> get props => [
        id,
        shippingId,
        status,
        location,
        timestamp,
        description,
        estimatedDelivery,
      ];
}