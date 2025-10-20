import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.showText = false,
    this.textColor,
  });

  final double size;
  final bool showText;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: size * 0.1,
                offset: Offset(0, size * 0.05),
              ),
            ],
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            'SecondHand',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Marketplace',
            style: TextStyle(
              fontSize: size * 0.15,
              color: (textColor ?? Colors.white).withOpacity(0.8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}