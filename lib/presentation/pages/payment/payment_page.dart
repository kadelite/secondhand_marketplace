import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/payment/payment_bloc.dart';
import '../../widgets/payment/payment_method_selector.dart';
import '../../widgets/payment/payment_summary_card.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/product.dart';

class PaymentPage extends StatefulWidget {
  final Product product;
  final String sellerId;
  final double totalAmount;

  const PaymentPage({
    super.key,
    required this.product,
    required this.sellerId,
    required this.totalAmount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? selectedPaymentMethod;
  Map<String, dynamic> paymentDetails = {};
  bool useEscrow = true;
  bool agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        elevation: 0,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _showPaymentSuccessDialog(context, state.payment);
          } else if (state is PaymentFailure) {
            _showPaymentFailureDialog(context, state.error);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Summary
                    PaymentSummaryCard(
                      product: widget.product,
                      totalAmount: widget.totalAmount,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Method Selection
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    PaymentMethodSelector(
                      selectedMethod: selectedPaymentMethod,
                      onMethodSelected: (method, details) {
                        setState(() {
                          selectedPaymentMethod = method;
                          paymentDetails = details;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Buyer Protection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.security, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Buyer Protection',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your payment is protected with our escrow service. '
                              'The seller will only receive payment after you confirm '
                              'satisfactory delivery.',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: useEscrow,
                                  onChanged: (value) {
                                    setState(() {
                                      useEscrow = value ?? true;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text('Enable buyer protection (Recommended)'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Terms and Conditions
                    Row(
                      children: [
                        Checkbox(
                          value: agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              agreedToTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: const [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Loading overlay
              if (state is PaymentLoading)
                const LoadingOverlay(message: 'Processing payment...'),
            ],
          );
        },
      ),
      
      // Payment Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _canProcessPayment() ? _processPayment : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: Text(
              'Pay \$${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canProcessPayment() {
    return selectedPaymentMethod != null && 
           agreedToTerms && 
           paymentDetails.isNotEmpty;
  }

  void _processPayment() {
    if (!_canProcessPayment()) return;

    context.read<PaymentBloc>().add(
      ProcessPaymentEvent(
        productId: widget.product.id,
        sellerId: widget.sellerId,
        amount: widget.totalAmount,
        currency: 'USD',
        paymentMethod: selectedPaymentMethod!,
        paymentDetails: paymentDetails,
        useEscrow: useEscrow,
      ),
    );
  }

  void _showPaymentSuccessDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transaction ID: ${payment.transactionId}'),
            const SizedBox(height: 8),
            if (payment.escrowHoldId != null)
              const Text(
                'Your payment is held in escrow for buyer protection. '
                'The seller will receive payment after delivery confirmation.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailureDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: const Text('Payment Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}