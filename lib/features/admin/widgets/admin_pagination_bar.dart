import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Professional 2026-style visual pagination bar for admin data tables.
/// Provides page size selection, item count summary, and interactive page buttons.
class AdminPaginationBar extends StatelessWidget {
  final int currentPage; // 1-indexed
  final int totalItems;
  final int rowsPerPage;
  final List<int> availableRowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;
  final String itemName; // e.g. "vegetables", "branches", "orders"

  const AdminPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.availableRowsPerPage = const [10, 25, 50],
    this.itemName = 'items',
  });

  int get totalPages => (totalItems / rowsPerPage).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final startItem = ((currentPage - 1) * rowsPerPage) + 1;
    final endItem = (currentPage * rowsPerPage).clamp(1, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final countSummary = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Showing ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
              Text(
                '$startItem–$endItem',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                ' of ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
              Text(
                '$totalItems',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                ' $itemName',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 16,
                width: 1,
                color: AppColors.neutral300,
              ),
              const SizedBox(width: 16),
              Text(
                'Per page: ',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.neutral600,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: rowsPerPage,
                  isDense: true,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: AppColors.neutral700,
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral800,
                  ),
                  items: availableRowsPerPage.map((n) {
                    return DropdownMenuItem<int>(
                      value: n,
                      child: Text('$n'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      onRowsPerPageChanged(val);
                    }
                  },
                ),
              ),
            ],
          );

          final pageControls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous Button
              OutlinedButton.icon(
                onPressed: currentPage > 1
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 16),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neutral800,
                  disabledForegroundColor: AppColors.neutral400,
                  side: BorderSide(
                    color: currentPage > 1
                        ? AppColors.neutral300
                        : AppColors.neutral200,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Numbered Page Buttons
              ..._buildPageNumbers(),

              const SizedBox(width: 8),

              // Next Button
              OutlinedButton(
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neutral800,
                  disabledForegroundColor: AppColors.neutral400,
                  side: BorderSide(
                    color: currentPage < totalPages
                        ? AppColors.neutral300
                        : AppColors.neutral200,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next'),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: countSummary),
                const SizedBox(height: 12),
                Center(child: pageControls),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              countSummary,
              pageControls,
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final widgets = <Widget>[];
    const maxVisible = 5;

    int start = 1;
    int end = totalPages;

    if (totalPages > maxVisible) {
      if (currentPage <= 3) {
        end = maxVisible;
      } else if (currentPage >= totalPages - 2) {
        start = totalPages - (maxVisible - 1);
      } else {
        start = currentPage - 2;
        end = currentPage + 2;
      }
    }

    if (start > 1) {
      widgets.add(_buildPageButton(1));
      if (start > 2) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '…',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral400),
            ),
          ),
        );
      }
    }

    for (int p = start; p <= end; p++) {
      widgets.add(_buildPageButton(p));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '…',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral400),
            ),
          ),
        );
      }
      widgets.add(_buildPageButton(totalPages));
    }

    return widgets;
  }

  Widget _buildPageButton(int pageNumber) {
    final isSelected = pageNumber == currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 34,
      height: 34,
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onPageChanged(pageNumber),
          child: Center(
            child: Text(
              '$pageNumber',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.neutral700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
