import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FilterChipsRow extends StatefulWidget {
  final List<String> filters;
  final String? selectedFilter;
  final Function(String?)? onFilterChanged;

  const FilterChipsRow({
    Key? key,
    required this.filters,
    this.selectedFilter,
    this.onFilterChanged,
  }) : super(key: key);

  @override
  State<FilterChipsRow> createState() => _FilterChipsRowState();
}

class _FilterChipsRowState extends State<FilterChipsRow> {
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
  }

  @override
  void didUpdateWidget(FilterChipsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFilter != oldWidget.selectedFilter) {
      _selectedFilter = widget.selectedFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.neutralGray300.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.paddingLarge,
          vertical: AppSizing.paddingSmall,
        ),
        children: [
          // "All" filter chip
          Padding(
            padding: const EdgeInsets.only(right: AppSizing.paddingSmall),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedFilter == null,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? null : _selectedFilter;
                });
                widget.onFilterChanged?.call(_selectedFilter);
              },
              labelStyle: _selectedFilter == null
                  ? AppTextStyles.filterChipSelectedText
                  : AppTextStyles.filterChipText,
              backgroundColor: AppTheme.neutralGray100,
              selectedColor: AppTheme.primaryTeal.withOpacity(0.12),
              checkmarkColor: AppTheme.primaryTeal,
              side: BorderSide(
                color: _selectedFilter == null
                    ? AppTheme.primaryTeal
                    : AppTheme.neutralGray300,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusXLarge),
              ),
            ),
          ),

          // Filter chips for each filter option
          ...widget.filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSizing.paddingSmall),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? filter : null;
                  });
                  widget.onFilterChanged?.call(_selectedFilter);
                },
                labelStyle: isSelected
                    ? AppTextStyles.filterChipSelectedText
                    : AppTextStyles.filterChipText,
                backgroundColor: AppTheme.neutralGray100,
                selectedColor: AppTheme.primaryTeal.withOpacity(0.12),
                checkmarkColor: AppTheme.primaryTeal,
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryTeal
                      : AppTheme.neutralGray300,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusXLarge),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Simple filter chip for basic use cases
class SimpleFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const SimpleFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.paddingLarge,
          vertical: AppSizing.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryTeal.withOpacity(0.12)
              : AppTheme.neutralGray100,
          border: Border.all(
            color: isSelected ? AppTheme.primaryTeal : AppTheme.neutralGray300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppSizing.radiusXLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSizing.iconSmall,
                color: isSelected ? AppTheme.primaryTeal : AppTheme.neutralGray600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: isSelected
                  ? AppTextStyles.filterChipSelectedText
                  : AppTextStyles.filterChipText,
            ),
          ],
        ),
      ),
    );
  }
}