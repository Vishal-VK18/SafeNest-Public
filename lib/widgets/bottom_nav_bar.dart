// lib/widgets/bottom_nav_bar.dart
//
// A premium animated bottom navigation bar for SafeNest.
// Active tab expands into a horizontal coral pill (icon + label).
// Inactive tabs show icon only and collapse smoothly.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data model for a single navigation tab.
class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

/// A fully custom animated bottom navigation bar.
///
/// The active tab expands horizontally into a rounded pill showing
/// icon + label side-by-side. Inactive tabs display the icon only.
/// All transitions animate over 300ms with ease-in-out curves.
///
/// ```dart
/// SafeNestBottomNavBar(
///   selectedIndex: _currentIndex,
///   onTabChange: (index, label) {
///     setState(() => _currentIndex = index);
///   },
/// )
/// ```
class SafeNestBottomNavBar extends StatefulWidget {
  /// Currently selected tab index.
  final int selectedIndex;

  /// Called when a tab is tapped. Provides the index and label.
  final Function(int index, String label)? onTabChange;

  /// Accent colour for the active tab icon, text, and pill background.
  /// Defaults to coral [Color(0xFFFF6F61)].
  final Color activeColor;

  /// Colour for inactive tab icons.
  /// Defaults to [Color(0xFFB0B0B0)].
  final Color inactiveColor;

  /// Background colour of the navigation bar itself.
  /// Defaults to [Colors.white].
  final Color backgroundColor;

  const SafeNestBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onTabChange,
    this.activeColor = const Color(0xFFFF6F61),
    this.inactiveColor = const Color(0xFFB0B0B0),
    this.backgroundColor = Colors.white,
  });

  @override
  State<SafeNestBottomNavBar> createState() => _SafeNestBottomNavBarState();
}

class _SafeNestBottomNavBarState extends State<SafeNestBottomNavBar> {
  static const List<BottomNavItem> _tabs = [
    BottomNavItem(icon: Icons.home, label: 'Home'),
    BottomNavItem(icon: Icons.show_chart, label: 'Journey'),
    BottomNavItem(icon: Icons.watch, label: 'Devices'),
    BottomNavItem(icon: Icons.history, label: 'History'),
    BottomNavItem(icon: Icons.person, label: 'Profile'),
  ];

  static const Duration _animDuration = Duration(milliseconds: 300);
  static const Curve _animCurve = Curves.easeInOut;
  static const double _barHeight = 70.0;

  void _handleTap(int index) {
    if (index == widget.selectedIndex) return;
    widget.onTabChange?.call(index, _tabs[index].label);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: _barHeight + bottomPadding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_tabs.length, (i) {
            final isSelected = widget.selectedIndex == i;
            return _NavTabItem(
              item: _tabs[i],
              isSelected: isSelected,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
              animDuration: _animDuration,
              animCurve: _animCurve,
              onTap: () => _handleTap(i),
            );
          }),
        ),
      ),
    );
  }
}

/// A single tab that expands into a pill when active.
///
/// Active  → [coral pill bg] Icon ─ 8px ─ Text
/// Inactive → [transparent]  Icon only
class _NavTabItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final Duration animDuration;
  final Curve animCurve;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    required this.animDuration,
    required this.animCurve,
  });

  @override
  Widget build(BuildContext context) {
    // Soft coral wash for the active pill background
    final pillColor = isSelected
        ? activeColor.withValues(alpha: 0.12)
        : Colors.transparent;

    final iconColor = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: animDuration,
        curve: animCurve,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon — always visible
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: animDuration,
              curve: animCurve,
              child: Icon(
                item.icon,
                size: 24,
                color: iconColor,
              ),
            ),

            // Label — only when selected, slides + fades in
            AnimatedSize(
              duration: animDuration,
              curve: animCurve,
              clipBehavior: Clip.none,
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.0,
                          duration: animDuration,
                          curve: animCurve,
                          child: AnimatedSlide(
                            offset: isSelected
                                ? Offset.zero
                                : const Offset(-0.3, 0),
                            duration: animDuration,
                            curve: animCurve,
                            child: Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: activeColor,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
