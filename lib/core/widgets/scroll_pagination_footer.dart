import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Orders-style infinite scroll footer — stats + loading indicator (no prev/next).
class ScrollPaginationFooter extends StatelessWidget {
  const ScrollPaginationFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasNextPage,
    required this.from,
    required this.to,
    required this.total,
    this.page,
    this.totalPages,
  });

  final bool isLoadingMore;
  final bool hasNextPage;
  final int from;
  final int to;
  final int total;
  final int? page;
  final int? totalPages;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    final pageLabel = page != null && totalPages != null && totalPages! > 0
        ? ' · Page $page of $totalPages'
        : '';

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 14, 10, 10),
      child: Column(
        children: [
          if (isLoadingMore)
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            )
          else if (hasNextPage)
            const SizedBox(height: 4),
          const SizedBox(height: 8),
          Text(
            '$from-$to of $total$pageLabel',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
