import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Infinite-scroll footer — loading spinner only (no page counters).
class ScrollPaginationFooter extends StatelessWidget {
  const ScrollPaginationFooter({
    super.key,
    required this.isLoadingMore,
  });

  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    if (!isLoadingMore) {
      return const SizedBox(height: 12);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

void attachScrollLoadMore(
  ScrollController controller,
  VoidCallback onLoadMore, {
  double threshold = 220,
}) {
  controller.addListener(() {
    if (!controller.hasClients) return;
    final pos = controller.position;
    if (pos.pixels >= pos.maxScrollExtent - threshold) {
      onLoadMore();
    }
  });
}
