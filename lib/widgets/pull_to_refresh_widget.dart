import 'package:flutter/material.dart';

/// 🔄 A reusable pull-to-refresh wrapper
class PullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
