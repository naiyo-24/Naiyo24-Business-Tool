import 'package:flutter/material.dart';
import 'skeleton_list_loader.dart';

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key, this.message = 'Loading data...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return const SkeletonListLoader();
  }
}
