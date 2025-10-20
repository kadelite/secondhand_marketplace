import '../entities/payment.dart';

abstract class PaymentRepository {
  // Payment Processing
  Future<Payment> createPayment({
    required String buyerId,
    required String sellerId,
    required String productId,
    required double amount,
    required String currency,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? metadata,
  });

  Future<Payment> processPayment({
    required String paymentId,
    required Map<String, dynamic> paymentDetails,
  });

  Future<Payment> capturePayment(String paymentId);
  Future<Payment> cancelPayment(String paymentId);
  Future<Payment> refundPayment(String paymentId, {double? amount});

  // Escrow Management
  Future<EscrowTransaction> holdPaymentInEscrow({
    required String paymentId,
    required double amount,
    bool buyerConfirmationRequired = true,
    DateTime? autoReleaseDate,
    String? holdReason,
  });

  Future<EscrowTransaction> releaseEscrowPayment({
    required String escrowId,
    required String buyerId,
    String? releaseReason,
  });

  Future<EscrowTransaction> refundEscrowPayment({
    required String escrowId,
    String? refundReason,
  });

  // Payment Queries
  Future<Payment?> getPayment(String paymentId);
  Future<List<Payment>> getPaymentsByUser(String userId);
  Future<List<Payment>> getPaymentsByProduct(String productId);
  Future<List<Payment>> getPaymentsByStatus(PaymentStatus status);

  // Escrow Queries
  Future<EscrowTransaction?> getEscrowTransaction(String escrowId);
  Future<List<EscrowTransaction>> getEscrowTransactionsByPayment(String paymentId);
  Future<List<EscrowTransaction>> getPendingEscrowTransactions();

  // Seller Payouts
  Future<void> processPayout({
    required String sellerId,
    required double amount,
    required String currency,
    required Map<String, dynamic> payoutDetails,
  });

  // Fraud Detection
  Future<double> calculateRiskScore({
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? transactionData,
  });

  Future<bool> isTransactionSuspicious({
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? metadata,
  });

  // Payment Methods
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods(String userId);
  Future<String> addPaymentMethod({
    required String userId,
    required PaymentMethod type,
    required Map<String, dynamic> paymentMethodData,
  });
  Future<void> removePaymentMethod(String paymentMethodId);

  // Analytics
  Future<Map<String, dynamic>> getPaymentAnalytics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<double> calculateTotalEarnings({
    required String sellerId,
    DateTime? startDate,
    DateTime? endDate,
  });
}