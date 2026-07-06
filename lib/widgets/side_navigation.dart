import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/sidebar_provider.dart';

class SideNavigation extends ConsumerStatefulWidget {
  const SideNavigation({
    super.key,
    this.email,
    required this.onLogout,
    required this.currentRoute,
  });

  final String? email;
  final VoidCallback onLogout;
  final String currentRoute;

  @override
  ConsumerState<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends ConsumerState<SideNavigation> {
  // ── Flat top-level items (above Inventory) ─────────────────────────────────
  static const List<_NavItem> _topItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: AppRoutes.dashboard),
  ];

  // ── Inventory dropdown children ────────────────────────────────────────────
  static const List<_NavItem> _inventoryChildren = [
    _NavItem(icon: Icons.receipt_long_rounded,  label: 'Invoices',    route: AppRoutes.invoices),
    _NavItem(icon: Icons.description_rounded,   label: 'Quotations',  route: AppRoutes.quotations),
    _NavItem(icon: Icons.people_rounded,        label: 'Clients',     route: AppRoutes.clients),
    _NavItem(icon: Icons.inventory_2_rounded,   label: 'Products',    route: AppRoutes.products),
  ];

  // ── Purchases dropdown children ───────────────────────────────────────────
  static const List<_NavItem> _purchasesChildren = [
    _NavItem(icon: Icons.store_rounded,         label: 'Manage Vendors',  route: AppRoutes.vendors),
    _NavItem(icon: Icons.shopping_bag_rounded,  label: 'Purchase Orders', route: AppRoutes.purchaseOrders),
  ];

  // ── Flat bottom items (below Purchases) ────────────────────────────────────
  static const List<_NavItem> _bottomItems = [
    _NavItem(icon: Icons.history_rounded,     label: 'History',          route: AppRoutes.reports),
    _NavItem(icon: Icons.settings_rounded,    label: 'Settings',         route: AppRoutes.settings),
  ];

  bool _inventoryExpanded = false;
  bool _purchasesExpanded = false;

  /// Returns true if any inventory child is the current active route,
  /// so the parent tile stays highlighted even when collapsed.
  bool get _isInventoryActive => _inventoryChildren.any(
    (item) => widget.currentRoute == item.route,
  );

  bool get _isPurchasesActive => _purchasesChildren.any(
    (item) => widget.currentRoute == item.route,
  );

  @override
  void initState() {
    super.initState();
    // Auto-expand inventory group on load if a child route is active.
    _inventoryExpanded = _isInventoryActive;
    _purchasesExpanded = _isPurchasesActive;
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(sidebarExpandedProvider);

    // When the sidebar collapses, also collapse the dropdowns.
    if (!isExpanded && (_inventoryExpanded || _purchasesExpanded)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {
          _inventoryExpanded = false;
          _purchasesExpanded = false;
        });
      });
    }

    return MouseRegion(
      onEnter: (_) => ref.read(sidebarExpandedProvider.notifier).setExpanded(true),
      onExit:  (_) => ref.read(sidebarExpandedProvider.notifier).setExpanded(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isExpanded ? 260 : 70,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.border, width: 1)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  // ── User Profile Box ───────────────────────────────────────
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? AppSpacing.md : 4.0,
                      vertical: AppSpacing.sm,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.all(isExpanded ? AppSpacing.md : 8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (widget.email?.isNotEmpty == true)
                                  ? widget.email![0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demo User',
                                    style: AppTextStyles.labelLarge
                                        .copyWith(color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.email ?? '',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Top flat items (Dashboard) ─────────────────────────────
                  ..._topItems.map((item) {
                    final selected = widget.currentRoute == item.route;
                    return _NavTile(
                      item: item,
                      selected: selected,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (!selected) context.go(item.route);
                      },
                    );
                  }),

                  // ── Inventory Group ────────────────────────────────────────
                  _DropdownGroupTile(
                    isExpanded: isExpanded,
                    isActive: _isInventoryActive,
                    isOpen: _inventoryExpanded,
                    label: 'Inventory',
                    icon: Icons.warehouse_rounded,
                    onTap: () {
                      if (!isExpanded) {
                        ref.read(sidebarExpandedProvider.notifier).setExpanded(true);
                        setState(() {
                          _inventoryExpanded = true;
                          _purchasesExpanded = false;
                        });
                      } else {
                        setState(() => _inventoryExpanded = !_inventoryExpanded);
                      }
                    },
                  ),

                  // Animated children list
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: (_inventoryExpanded && isExpanded)
                        ? Column(
                            children: _inventoryChildren.map((item) {
                              final selected = widget.currentRoute == item.route;
                              return _DropdownChildTile(
                                item: item,
                                selected: selected,
                                onTap: () {
                                  if (!selected) context.go(item.route);
                                },
                              );
                            }).toList(),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Purchases & Expenses Group ─────────────────────────────
                  _DropdownGroupTile(
                    isExpanded: isExpanded,
                    isActive: _isPurchasesActive,
                    isOpen: _purchasesExpanded,
                    label: 'Purchases & Expenses',
                    icon: Icons.account_balance_wallet_rounded,
                    onTap: () {
                      if (!isExpanded) {
                        ref.read(sidebarExpandedProvider.notifier).setExpanded(true);
                        setState(() {
                          _purchasesExpanded = true;
                          _inventoryExpanded = false;
                        });
                      } else {
                        setState(() => _purchasesExpanded = !_purchasesExpanded);
                      }
                    },
                  ),

                  // Animated children list for purchases
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: (_purchasesExpanded && isExpanded)
                        ? Column(
                            children: _purchasesChildren.map((item) {
                              final selected = widget.currentRoute == item.route;
                              return _DropdownChildTile(
                                item: item,
                                selected: selected,
                                onTap: () {
                                  if (!selected) context.go(item.route);
                                },
                              );
                            }).toList(),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Bottom flat items (Purchases, Reports, Settings) ───────
                  ..._bottomItems.map((item) {
                    final selected = widget.currentRoute == item.route;
                    return _NavTile(
                      item: item,
                      selected: selected,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (!selected) context.go(item.route);
                      },
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _NavTile(
              item: const _NavItem(icon: Icons.logout_rounded, label: 'Logout', route: ''),
              selected: false,
              isExpanded: isExpanded,
              isErrorColor: true,
              onTap: widget.onLogout,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}

// ─── Inventory Group Parent Tile ──────────────────────────────────────────────
// Shows the "Inventory" label + a chevron that rotates when open.

class _DropdownGroupTile extends StatefulWidget {
  const _DropdownGroupTile({
    required this.isExpanded,
    required this.isActive,
    required this.isOpen,
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final bool isExpanded; // sidebar expanded/collapsed
  final bool isActive;   // any child is currently selected
  final bool isOpen;     // dropdown is open
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  State<_DropdownGroupTile> createState() => _DropdownGroupTileState();
}

class _DropdownGroupTileState extends State<_DropdownGroupTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor    = Colors.transparent;
    Color iconColor  = AppColors.textSecondary;
    Color textColor  = AppColors.textSecondary;

    if (widget.isActive && !_isHovered) {
      bgColor   = AppColors.primary.withValues(alpha: 0.08);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    if (_isHovered) {
      bgColor   = const Color(0xFF7C3AED);
      iconColor = Colors.white;
      textColor = Colors.white;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? AppSpacing.sm : 4.0,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: (widget.isActive && !_isHovered)
              ? Border(left: BorderSide(color: AppColors.primary, width: 4))
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded
                  ? AppSpacing.md
                  : (widget.isActive ? 6.0 : 8.0),
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: widget.isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // Inventory icon
                Icon(
                  widget.icon,
                  size: 20,
                  color: iconColor,
                ),
                if (widget.isExpanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Rotating chevron
                  AnimatedRotation(
                    turns: widget.isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Inventory Child Tile ─────────────────────────────────────────────────────
// Indented child row shown inside the expanded Inventory group.

class _DropdownChildTile extends StatefulWidget {
  const _DropdownChildTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DropdownChildTile> createState() => _DropdownChildTileState();
}

class _DropdownChildTileState extends State<_DropdownChildTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor   = Colors.transparent;
    Color iconColor = AppColors.textSecondary;
    Color textColor = AppColors.textSecondary;

    if (widget.selected && !_isHovered) {
      bgColor   = AppColors.primary.withValues(alpha: 0.10);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    if (_isHovered) {
      bgColor   = AppColors.primary.withValues(alpha: 0.06);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        // Extra left indent to show hierarchy
        margin: const EdgeInsets.only(left: 28, right: 8, top: 1, bottom: 1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                // Small vertical connector line
                Container(
                  width: 2,
                  height: 14,
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(widget.item.icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Standard Nav Tile ────────────────────────────────────────────────────────

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.isExpanded,
    required this.onTap,
    this.isErrorColor = false,
  });

  final _NavItem item;
  final bool selected;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isErrorColor;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isErrorColor ? AppColors.error : AppColors.primary;

    Color bgColor   = Colors.transparent;
    Color iconColor = AppColors.textSecondary;
    Color textColor = AppColors.textSecondary;

    if (widget.selected) {
      bgColor   = activeColor.withValues(alpha: 0.12);
      iconColor = activeColor;
      textColor = activeColor;
    }

    if (_isHovered) {
      bgColor   = widget.isErrorColor ? AppColors.error : const Color(0xFF7C3AED);
      iconColor = Colors.white;
      textColor = Colors.white;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? AppSpacing.sm : 4.0,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: (widget.selected && !_isHovered)
              ? Border(left: BorderSide(color: activeColor, width: 4))
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded
                  ? AppSpacing.md
                  : (widget.selected ? 6.0 : 8.0),
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: widget.isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(widget.item.icon, size: 20, color: iconColor),
                if (widget.isExpanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
