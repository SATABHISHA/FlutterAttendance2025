import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
