import 'package:flutter/material.dart';

class TitleContainer extends StatelessWidget {
  final Widget child;

  const TitleContainer({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: child,
    );
  }
}