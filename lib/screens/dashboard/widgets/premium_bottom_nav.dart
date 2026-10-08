import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../theme/app_theme.dart';

class PremiumBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Stream<int> pendingJobsCountStream;

  const PremiumBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.pendingJobsCountStream,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildItem(context, 0, Iconsax.home_2, 'Home'),
                  _buildItem(context, 1, Iconsax.receipt_item, 'Jobs'),
                  _buildItem(context, 2, Iconsax.wallet_2, 'Wallet'),
                  _buildItem(context, 4, Iconsax.profile_circle, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    final isCompact = MediaQuery.sizeOf(context).width < 420;
    final color = isSelected
        ? AppTheme.primaryColor
        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.65) ?? Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: () => onDestinationSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected && !isCompact ? 10 : 8,
            vertical: isSelected ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(context, index, icon, color),
              if (isSelected) ...[
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    BuildContext context,
    int index,
    IconData icon,
    Color color,
  ) {
    final iconWidget = Icon(icon, color: color, size: 22);
    if (index != 1) return iconWidget;

    return StreamBuilder<int>(
      stream: pendingJobsCountStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return iconWidget;
        return Badge(
          label: Text(count.toString()),
          backgroundColor: Colors.red,
          textColor: Colors.white,
          child: iconWidget,
        );
      },
    );
  }
}
