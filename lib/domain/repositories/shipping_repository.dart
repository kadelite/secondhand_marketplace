import '../entities/shipping.dart';

abstract class ShippingRepository {
  // Shipping Creation and Management
  Future<Shipping> createShipment({
    required String orderId,
    required String sellerId,
    required String buyerId,
    required String productId,
    required Address fromAddress,
    required Address toAddress,
    required CourierService courierService,
    required ShippingType shippingType,
    double? weight,
    Dimensions? dimensions,
    String? notes,
  });

  Future<Shipping> updateShipment(String shippingId, Shipping updatedShipment);
  Future<void> cancelShipment(String shippingId);

  // Label Generation
  Future<String> generateShippingLabel({
    required String shippingId,
    required CourierService courierService,
    required Address fromAddress,
    required Address toAddress,
    required double weight,
    Dimensions? dimensions,
    ShippingType shippingType = ShippingType.standard,
  });

  Future<String?> getShippingLabel(String shippingId);

  // Courier API Integration
  Future<double> calculateShippingCost({
    required CourierService courierService,
    required Address fromAddress,
    required Address toAddress,
    required double weight,
    Dimensions? dimensions,
    ShippingType shippingType = ShippingType.standard,
  });

  Future<List<Map<String, dynamic>>> getShippingQuotes({
    required Address fromAddress,
    required Address toAddress,
    required double weight,
    Dimensions? dimensions,
  });

  // Tracking and Updates
  Future<List<TrackingUpdate>> getTrackingUpdates(String shippingId);
  Future<TrackingUpdate> getLatestTrackingUpdate(String shippingId);

  Future<void> updateTrackingStatus({
    required String shippingId,
    required ShippingStatus status,
    required String location,
    String? description,
    DateTime? estimatedDelivery,
  });

  Future<List<TrackingUpdate>> fetchTrackingFromCourier({
    required CourierService courierService,
    required String trackingNumber,
  });

  // Delivery Confirmation
  Future<void> confirmDelivery({
    required String shippingId,
    required DateTime deliveryTime,
    String? deliveryNotes,
    String? recipientName,
  });

  Future<void> reportDeliveryIssue({
    required String shippingId,
    required String issueDescription,
    List<String>? evidence,
  });

  // Shipping Queries
  Future<Shipping?> getShipment(String shippingId);
  Future<List<Shipping>> getShipmentsByOrder(String orderId);
  Future<List<Shipping>> getShipmentsBySeller(String sellerId);
  Future<List<Shipping>> getShipmentsByBuyer(String buyerId);
  Future<List<Shipping>> getShipmentsByStatus(ShippingStatus status);

  // Address Management
  Future<List<Address>> getSavedAddresses(String userId);
  Future<String> addAddress(String userId, Address address);
  Future<void> updateAddress(String addressId, Address address);
  Future<void> deleteAddress(String addressId);
  Future<Address> validateAddress(Address address);

  // Courier Service Management
  Future<List<CourierService>> getAvailableCouriers({
    required Address fromAddress,
    required Address toAddress,
  });

  Future<Map<String, dynamic>> getCourierServiceInfo(CourierService courier);

  // Bulk Operations
  Future<List<Shipping>> createBulkShipments(List<Map<String, dynamic>> shipmentData);
  Future<List<String>> generateBulkLabels(List<String> shippingIds);

  // Analytics
  Future<Map<String, dynamic>> getShippingAnalytics({
    required String sellerId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<double> getAverageDeliveryTime({
    required CourierService courierService,
    required Address fromAddress,
    required Address toAddress,
  });
}