import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vegora_core/vegora_core.dart';

import 'admin_pagination_bar.dart';

/// Specification for a column in [AdminTableContainer].
class AdminTableColumn {
  final String title;
  final int flex;
  final double? fixedWidth;
  final Alignment alignment;

  const AdminTableColumn({
    required this.title,
    this.flex = 1,
    this.fixedWidth,
    this.alignment = Alignment.centerLeft,
  });
}

/// A single data row specification in [AdminTableContainer].
class AdminTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const AdminTableRow({required this.cells, this.onTap});
}

/// Professional 2026 SaaS-style responsive table container for admin consoles.
/// Automatically stretches columns across 100% of the available card width,
/// supports horizontal scroll on smaller viewports, smooth row hover micro-interactions,
/// and includes an attached pagination footer.
class AdminTableContainer extends StatelessWidget {
  final List<AdminTableColumn>? columns;
  final List<AdminTableRow>? rows;
  final Widget? child;
  final int currentPage;
  final int totalItems;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;
  final String itemName;
  final List<int> availableRowsPerPage;
  final double minWidth;
  final Widget? emptyWidget;

  const AdminTableContainer({
    super.key,
    this.columns,
    this.rows,
    this.child,
    required this.currentPage,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.itemName = 'items',
    this.availableRowsPerPage = const [10, 25, 50],
    this.minWidth = 1040,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Body with Full Width Layout & Smooth Scroll
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, minWidth);

              if (columns != null && rows != null) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Row
                        _buildHeaderRow(columns!),
                        // Body Rows or Empty State
                        if (rows!.isEmpty)
                          emptyWidget ?? _buildDefaultEmptyState()
                        else
                          for (final row in rows!)
                            _AdminTableRowWidget(columns: columns!, row: row),
                      ],
                    ),
                  ),
                );
              }

              // Fallback for custom child widget
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          ),

          // Pagination Bar Footer
          AdminPaginationBar(
            currentPage: currentPage,
            totalItems: totalItems,
            rowsPerPage: rowsPerPage,
            availableRowsPerPage: availableRowsPerPage,
            onPageChanged: onPageChanged,
            onRowsPerPageChanged: onRowsPerPageChanged,
            itemName: itemName,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(List<AdminTableColumn> cols) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final col in cols)
            col.fixedWidth != null
                ? SizedBox(
                    width: col.fixedWidth,
                    child: Align(
                      alignment: col.alignment,
                      child: Text(
                        col.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    flex: col.flex,
                    child: Align(
                      alignment: col.alignment,
                      child: Text(
                        col.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No $itemName found matching criteria.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTableRowWidget extends StatefulWidget {
  final List<AdminTableColumn> columns;
  final AdminTableRow row;

  const _AdminTableRowWidget({required this.columns, required this.row});

  @override
  State<_AdminTableRowWidget> createState() => _AdminTableRowWidgetState();
}

class _AdminTableRowWidgetState extends State<_AdminTableRowWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.row.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: InkWell(
        onTap: widget.row.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.columns.length; i++) ...[
                if (widget.columns[i].fixedWidth != null)
                  SizedBox(
                    width: widget.columns[i].fixedWidth,
                    child: Align(
                      alignment: widget.columns[i].alignment,
                      child: i < widget.row.cells.length
                          ? widget.row.cells[i]
                          : const SizedBox.shrink(),
                    ),
                  )
                else
                  Expanded(
                    flex: widget.columns[i].flex,
                    child: Align(
                      alignment: widget.columns[i].alignment,
                      child: i < widget.row.cells.length
                          ? widget.row.cells[i]
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
