import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/process_payment.dart';

// Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPaymentEvent extends PaymentEvent {
  final String productId;
  final String sellerId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic> paymentDetails;
  final bool useEscrow;

  const ProcessPaymentEvent({
    required this.productId,
    required this.sellerId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentDetails,
    this.useEscrow = true,
  });

  @override
  List<Object?> get props => [
        productId,
        sellerId,
        amount,
        currency,
        paymentMethod,
        paymentDetails,
        useEscrow,
      ];
}

class ConfirmDeliveryEvent extends PaymentEvent {
  final String paymentId;
  final String? feedback;

  const ConfirmDeliveryEvent({
    required this.paymentId,
    this.feedback,
  });

  @override
  List<Object?> get props => [paymentId, feedback];
}

class LoadPaymentHistoryEvent extends PaymentEvent {
  final String userId;

  const LoadPaymentHistoryEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {
  final String? message;

  const PaymentLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class PaymentSuccess extends PaymentState {
  final Payment payment;
  final EscrowTransaction? escrowTransaction;

  const PaymentSuccess({
    required this.payment,
    this.escrowTransaction,
  });

  @override
  List<Object?> get props => [payment, escrowTransaction];
}

class PaymentFailure extends PaymentState {
  final String error;

  const PaymentFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class EscrowReleased extends PaymentState {
  final EscrowTransaction escrowTransaction;

  const EscrowReleased(this.escrowTransaction);

  @override
  List<Object?> get props => [escrowTransaction];
}

class PaymentHistoryLoaded extends PaymentState {
  final List<Payment> payments;

  const PaymentHistoryLoaded(this.payments);

  @override
  List<Object?> get props => [payments];
}

// BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ProcessPaymentUseCase _processPaymentUseCase;
  final ConfirmDeliveryAndReleaseEscrowUseCase _confirmDeliveryUseCase;

  PaymentBloc({
    required ProcessPaymentUseCase processPaymentUseCase,
    required ConfirmDeliveryAndReleaseEscrowUseCase confirmDeliveryUseCase,
  })  : _processPaymentUseCase = processPaymentUseCase,
        _confirmDeliveryUseCase = confirmDeliveryUseCase,
        super(PaymentInitial()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<ConfirmDeliveryEvent>(_onConfirmDelivery);
    on<LoadPaymentHistoryEvent>(_onLoadPaymentHistory);
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Processing payment...'));

    try {
      final result = await _processPaymentUseCase.execute(
        buyerId: 'current_user_id', // TODO: Get from auth service
        sellerId: event.sellerId,
        productId: event.productId,
        amount: event.amount,
        currency: event.currency,
        paymentMethod: event.paymentMethod,
        paymentDetails: event.paymentDetails,
        useEscrow: event.useEscrow,
      );

      if (result.success && result.payment != null) {
        emit(PaymentSuccess(
          payment: result.payment!,
          escrowTransaction: result.escrowTransaction,
        ));
      } else {
        emit(PaymentFailure(result.error ?? 'Payment failed'));
      }
    } catch (e) {
      emit(PaymentFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmDelivery(
    ConfirmDeliveryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Confirming delivery...'));

    try {
      final result = await _confirmDeliveryUseCase.execute(
        buyerId: 'current_user_id', // TODO: Get from auth service
        paymentId: event.paymentId,
        feedback: event.feedback,
      );

      if (result.success && result.escrowTransaction != null) {
        emit(EscrowReleased(result.escrowTransaction!));
      } else {
        emit(PaymentFailure(result.error ?? 'Failed to release escrow'));
      }
    } catch (e) {
      emit(PaymentFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Loading payment history...'));

    try {
      // TODO: Implement payment history loading
      // This would use a repository to fetch user's payment history
      const payments = <Payment>[];
      emit(const PaymentHistoryLoaded(payments));
    } catch (e) {
      emit(PaymentFailure('Failed to load payment history: ${e.toString()}'));
    }
  }
}