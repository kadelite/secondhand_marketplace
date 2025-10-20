import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class ProcessPaymentUseCase {
  final PaymentRepository _paymentRepository;

  ProcessPaymentUseCase(this._paymentRepository);

  Future<PaymentResult> execute({
    required String buyerId,
    required String sellerId,
    required String productId,
    required double amount,
    required String currency,
    required PaymentMethod paymentMethod,
    required Map<String, dynamic> paymentDetails,
    bool useEscrow = true,
    bool requireBuyerConfirmation = true,
    Duration? escrowAutoReleaseDuration,
  }) async {
    try {
      // Step 1: Create payment record
      final payment = await _paymentRepository.createPayment(
        buyerId: buyerId,
        sellerId: sellerId,
        productId: productId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        metadata: {
          'useEscrow': useEscrow,
          'requireBuyerConfirmation': requireBuyerConfirmation,
          ...paymentDetails,
        },
      );

      // Step 2: Process payment through payment gateway
      final processedPayment = await _paymentRepository.processPayment(
        paymentId: payment.id,
        paymentDetails: paymentDetails,
      );

      // Check if payment failed
      if (processedPayment.status == PaymentStatus.failed) {
        return PaymentResult(
          success: false,
          payment: processedPayment,
          error: processedPayment.failureReason ?? 'Payment processing failed',
        );
      }

      // Step 3: Hold payment in escrow if required
      EscrowTransaction? escrowTransaction;
      if (useEscrow && processedPayment.status == PaymentStatus.captured) {
        final autoReleaseDate = escrowAutoReleaseDuration != null
            ? DateTime.now().add(escrowAutoReleaseDuration)
            : DateTime.now().add(const Duration(days: 7)); // Default 7 days

        escrowTransaction = await _paymentRepository.holdPaymentInEscrow(
          paymentId: processedPayment.id,
          amount: amount,
          buyerConfirmationRequired: requireBuyerConfirmation,
          autoReleaseDate: autoReleaseDate,
          holdReason: 'Buyer protection - awaiting delivery confirmation',
        );
      }

      return PaymentResult(
        success: true,
        payment: processedPayment,
        escrowTransaction: escrowTransaction,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class PaymentResult {
  final bool success;
  final Payment? payment;
  final EscrowTransaction? escrowTransaction;
  final String? error;

  PaymentResult({
    required this.success,
    this.payment,
    this.escrowTransaction,
    this.error,
  });
}

class ConfirmDeliveryAndReleaseEscrowUseCase {
  final PaymentRepository _paymentRepository;

  ConfirmDeliveryAndReleaseEscrowUseCase(this._paymentRepository);

  Future<EscrowReleaseResult> execute({
    required String buyerId,
    required String paymentId,
    String? feedback,
  }) async {
    try {
      // Get escrow transactions for this payment
      final escrowTransactions = await _paymentRepository
          .getEscrowTransactionsByPayment(paymentId);

      if (escrowTransactions.isEmpty) {
        return EscrowReleaseResult(
          success: false,
          error: 'No escrow transaction found for this payment',
        );
      }

      final escrowTransaction = escrowTransactions.first;

      // Release escrow payment
      final releasedEscrow = await _paymentRepository.releaseEscrowPayment(
        escrowId: escrowTransaction.id,
        buyerId: buyerId,
        releaseReason: feedback ?? 'Buyer confirmed delivery satisfaction',
      );

      return EscrowReleaseResult(
        success: true,
        escrowTransaction: releasedEscrow,
      );
    } catch (e) {
      return EscrowReleaseResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class EscrowReleaseResult {
  final bool success;
  final EscrowTransaction? escrowTransaction;
  final String? error;

  EscrowReleaseResult({
    required this.success,
    this.escrowTransaction,
    this.error,
  });
}