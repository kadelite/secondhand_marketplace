import 'package:flutter/material.dart';
import '../../../domain/entities/payment.dart';

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod method, Map<String, dynamic> details) onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Payment method tiles
        _buildPaymentMethodTile(
          method: PaymentMethod.creditCard,
          title: 'Credit/Debit Card',
          subtitle: 'Visa, MasterCard, American Express',
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 12),
        
        _buildPaymentMethodTile(
          method: PaymentMethod.paypal,
          title: 'PayPal',
          subtitle: 'Pay with your PayPal account',
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        
        _buildPaymentMethodTile(
          method: PaymentMethod.applePay,
          title: 'Apple Pay',
          subtitle: 'Pay with Touch ID or Face ID',
          icon: Icons.phone_iphone,
        ),
        const SizedBox(height: 12),
        
        _buildPaymentMethodTile(
          method: PaymentMethod.googlePay,
          title: 'Google Pay',
          subtitle: 'Pay with Google Pay',
          icon: Icons.android,
        ),
        
        // Card details form (shown when credit card is selected)
        if (widget.selectedMethod == PaymentMethod.creditCard) ...[
          const SizedBox(height: 24),
          _buildCardDetailsForm(),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = widget.selectedMethod == method;

    return Card(
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: widget.selectedMethod,
        onChanged: (PaymentMethod? value) {
          if (value != null) {
            _handleMethodSelection(value);
          }
        },
        title: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildCardDetailsForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Card holder name
            TextFormField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Card Holder Name',
                hintText: 'John Doe',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _updateCardDetails(),
            ),
            const SizedBox(height: 16),
            
            // Card number
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateCardDetails(),
            ),
            const SizedBox(height: 16),
            
            // Expiry and CVV
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/25',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateCardDetails(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    onChanged: (_) => _updateCardDetails(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMethodSelection(PaymentMethod method) {
    Map<String, dynamic> details = {};

    switch (method) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        // Card details will be updated via _updateCardDetails()
        details = _getCardDetails();
        break;
      case PaymentMethod.paypal:
        details = {'type': 'paypal'};
        break;
      case PaymentMethod.applePay:
        details = {'type': 'apple_pay'};
        break;
      case PaymentMethod.googlePay:
        details = {'type': 'google_pay'};
        break;
      case PaymentMethod.bankTransfer:
        details = {'type': 'bank_transfer'};
        break;
    }

    widget.onMethodSelected(method, details);
  }

  void _updateCardDetails() {
    if (widget.selectedMethod == PaymentMethod.creditCard) {
      final details = _getCardDetails();
      widget.onMethodSelected(PaymentMethod.creditCard, details);
    }
  }

  Map<String, dynamic> _getCardDetails() {
    return {
      'type': 'credit_card',
      'card_holder': _cardHolderController.text,
      'card_number': _cardNumberController.text,
      'expiry': _expiryController.text,
      'cvv': _cvvController.text,
      'is_complete': _cardHolderController.text.isNotEmpty &&
                     _cardNumberController.text.isNotEmpty &&
                     _expiryController.text.isNotEmpty &&
                     _cvvController.text.isNotEmpty,
    };
  }
}