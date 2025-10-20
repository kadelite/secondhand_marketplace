import 'package:equatable/equatable.dart';

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  bankTransfer,
}

enum PaymentStatus {
  pending,
  authorized,
  captured,
  completed,
  failed,
  refunded,
  disputed,
  cancelled,
}

enum TransactionType {
  purchase,
  refund,
  payout,
  escrowHold,
  escrowRelease,
}

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.transactionId,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.transactionType,
    this.stripePaymentIntentId,
    this.paypalOrderId,
    this.escrowHoldId,
    this.feeAmount = 0.0,
    this.netAmount,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.metadata = const {},
  });

  final String id;
  final String transactionId;
  final String buyerId;
  final String sellerId;
  final String productId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final TransactionType transactionType;
  final String? stripePaymentIntentId;
  final String? paypalOrderId;
  final String? escrowHoldId;
  final double feeAmount;
  final double? netAmount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final Map<String, dynamic> metadata;

  Payment copyWith({
    String? id,
    String? transactionId,
    String? buyerId,
    String? sellerId,
    String? productId,
    double? amount,
    String? currency,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    TransactionType? transactionType,
    String? stripePaymentIntentId,
    String? paypalOrderId,
    String? escrowHoldId,
    double? feeAmount,
    double? netAmount,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      paypalOrderId: paypalOrderId ?? this.paypalOrderId,
      escrowHoldId: escrowHoldId ?? this.escrowHoldId,
      feeAmount: feeAmount ?? this.feeAmount,
      netAmount: netAmount ?? this.netAmount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
        buyerId,
        sellerId,
        productId,
        amount,
        currency,
        paymentMethod,
        status,
        transactionType,
        stripePaymentIntentId,
        paypalOrderId,
        escrowHoldId,
        feeAmount,
        netAmount,
        createdAt,
        completedAt,
        failureReason,
        metadata,
      ];
}

class EscrowTransaction extends Equatable {
  const EscrowTransaction({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.releasedAt,
    this.buyerConfirmationRequired = true,
    this.autoReleaseDate,
    this.holdReason,
  });

  final String id;
  final String paymentId;
  final double amount;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime? releasedAt;
  final bool buyerConfirmationRequired;
  final DateTime? autoReleaseDate;
  final String? holdReason;

  @override
  List<Object?> get props => [
        id,
        paymentId,
        amount,
        status,
        createdAt,
        releasedAt,
        buyerConfirmationRequired,
        autoReleaseDate,
        holdReason,
      ];
}

enum EscrowStatus {
  held,
  released,
  disputed,
  refunded,
}