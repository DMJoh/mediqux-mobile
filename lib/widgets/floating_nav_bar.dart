import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';

class NavBarItem {
  const NavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// A floating, inset, blurred-glass pill nav bar with a gradient "spotlight"
/// indicator around the selected item — replaces the stock docked Material
/// [NavigationBar] with something closer to the current wave of Android nav
/// patterns (and the web app's gradient active-state highlight). Icon-only
/// (no labels) so every tab stays a fixed, evenly-spaced size regardless of
/// label length or screen width.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<NavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: glass.glass,
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              border: Border.all(color: glass.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavItem(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(22)),
    );
    return Material(
      color: Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Tooltip(
          message: item.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: selected ? glass.accentGradient : null,
              borderRadius: const BorderRadius.all(Radius.circular(22)),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: glass.gradientStart.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              item.icon,
              size: 26,
              color: selected ? Colors.white : glass.muted,
            ),
          ),
        ),
      ),
    );
  }
}
