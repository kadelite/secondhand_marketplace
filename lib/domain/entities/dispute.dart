import 'package:equatable/equatable.dart';

enum DisputeType {
  notAsDescribed,
  notReceived,
  damaged,
  counterfeit,
  returnsIssue,
  other,
}

enum DisputeStatus {
  open,
  awaitingBuyerResponse,
  awaitingSeller Response,
  underReview,
  resolved,
  escalated,
  closed,
  cancelled,
}

enum ReturnReason {
  notAsDescribed,
  damaged,
  changed mind,
  sizingIssue,
  defective,
  other,
}

enum ReturnStatus {
  requested,
  approved,
  denied,
  inTransit,
  received,
  refunded,
  completed,
  cancelled,
}

class Dispute extends Equatable {
  const Dispute({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    this.evidence = const [],
    this.amount,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolution,
    this.adminNotes,
    this.isEscalated = false,
    this.autoResolveDate,
  });

  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String productId;
  final DisputeType type;
  final DisputeStatus status;
  final String title;
  final String description;
  final List<String> evidence;
  final double? amount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final String? adminNotes;
  final bool isEscalated;
  final DateTime? autoResolveDate;

  Dispute copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    String? productId,
    DisputeType? type,
    DisputeStatus? status,
    String? title,
    String? description,
    List<String>? evidence,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolution,
    String? adminNotes,
    bool? isEscalated,
    DateTime? autoResolveDate,
  }) {
    return Dispute(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      adminNotes: adminNotes ?? this.adminNotes,
      isEscalated: isEscalated ?? this.isEscalated,
      autoResolveDate: autoResolveDate ?? this.autoResolveDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        buyerId,
        sellerId,
        productId,
        type,
        status,
        title,
        description,
        evidence,
        amount,
        createdAt,
        updatedAt,
        resolvedAt,
        resolution,
        adminNotes,
        isEscalated,
        autoResolveDate,
      ];
}

class ReturnRequest extends Equatable {
  const ReturnRequest({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.reason,
    required this.status,
    required this.description,
    this.images = const [],
    this.returnPolicy,
    this.shippingLabelUrl,
    this.trackingNumber,
    required this.createdAt,
    this.approvedAt,
    this.completedAt,
    this.refundAmount,
    this.restockingFee = 0.0,
    this.sellerNotes,
    this.adminNotes,
  });

  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String productId;
  final ReturnReason reason;
  final ReturnStatus status;
  final String description;
  final List<String> images;
  final ReturnPolicy? returnPolicy;
  final String? shippingLabelUrl;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final double? refundAmount;
  final double restockingFee;
  final String? sellerNotes;
  final String? adminNotes;

  ReturnRequest copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    String? productId,
    ReturnReason? reason,
    ReturnStatus? status,
    String? description,
    List<String>? images,
    ReturnPolicy? returnPolicy,
    String? shippingLabelUrl,
    String? trackingNumber,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? completedAt,
    double? refundAmount,
    double? restockingFee,
    String? sellerNotes,
    String? adminNotes,
  }) {
    return ReturnRequest(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      description: description ?? this.description,
      images: images ?? this.images,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      shippingLabelUrl: shippingLabelUrl ?? this.shippingLabelUrl,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      completedAt: completedAt ?? this.completedAt,
      refundAmount: refundAmount ?? this.refundAmount,
      restockingFee: restockingFee ?? this.restockingFee,
      sellerNotes: sellerNotes ?? this.sellerNotes,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        buyerId,
        sellerId,
        productId,
        reason,
        status,
        description,
        images,
        returnPolicy,
        shippingLabelUrl,
        trackingNumber,
        createdAt,
        approvedAt,
        completedAt,
        refundAmount,
        restockingFee,
        sellerNotes,
        adminNotes,
      ];
}

class ReturnPolicy extends Equatable {
  const ReturnPolicy({
    required this.id,
    required this.sellerId,
    this.acceptsReturns = true,
    this.returnPeriodDays = 30,
    this.restockingFeePercent = 0.0,
    this.buyerPaysShipping = true,
    this.conditions = const [],
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sellerId;
  final bool acceptsReturns;
  final int returnPeriodDays;
  final double restockingFeePercent;
  final bool buyerPaysShipping;
  final List<String> conditions;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        sellerId,
        acceptsReturns,
        returnPeriodDays,
        restockingFeePercent,
        buyerPaysShipping,
        conditions,
        description,
        createdAt,
        updatedAt,
      ];
}