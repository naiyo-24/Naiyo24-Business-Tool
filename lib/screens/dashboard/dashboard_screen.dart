import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../notifiers/auth_notifier.dart';
import '../products/widgets/product_form_dialog.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/chat_support_popup.dart';

import '../../cards/stat_card.dart';
import '../../cards/activity_card.dart';
import '../../cards/feature_block_card.dart';

/// Dashboard screen shown after successful login.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(ref, context),
                currentRoute: AppRoutes.dashboard,
              ),
            )
          : null,
      body: Row(
        children: [
          // Side navigation (desktop only)
          if (MediaQuery.of(context).size.width >= 900)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () => _logout(ref, context),
              currentRoute: AppRoutes.dashboard,
            ),

          // Main content
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(email: authState.userEmail),
                    const SizedBox(height: AppSpacing.xxl),

                    _StatsGrid(),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    _GettingStartedGrid(),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showChatSupportPopup(context),
        backgroundColor: const Color(0xFF6D28D9),
        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
        label: const Text('Chat Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _logout(WidgetRef ref, BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }
}

// ─── Profile Header ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    // Derive display name from email (e.g. "naiyodemo@gmail.com" → "Demo")
    String displayName = 'Demo User';
    if (email != null && email!.contains('@')) {
      final raw = email!.split('@').first;
      displayName = raw
          .split(RegExp(r'[._\-]'))
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    const companyName = 'Naiyo24';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 500;

        final avatarAndText = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello $displayName',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome to $companyName!',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final button = FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo booking coming soon')),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE91E8C),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          icon: const Icon(Icons.desktop_mac_outlined, size: 16),
          label: const Text(
            'Book A Demo',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              avatarAndText,
              const SizedBox(height: AppSpacing.lg),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: avatarAndText),
            const SizedBox(width: AppSpacing.lg),
            button,
          ],
        );
      },
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  static const List<Map<String, dynamic>> _statsData = [
    {
      'title': 'Total Revenue',
      'value': '₹2,48,500',
      'change': '+12.5%',
      'isPositive': true,
      'icon': Icons.currency_rupee_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Pending Invoices',
      'value': '14',
      'change': '-3 from last month',
      'isPositive': true,
      'icon': Icons.receipt_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Active Clients',
      'value': '38',
      'change': '+5 new',
      'isPositive': true,
      'icon': Icons.people_rounded,
      'color': Color(0xFF22C55E),
    },
    {
      'title': 'Overdue',
      'value': '₹18,200',
      'change': '+2 invoices',
      'isPositive': false,
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFEF4444),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double cardWidth;
        if (width > 1200) {
          cardWidth = (width - (AppSpacing.lg * 3)) / 4;
        } else if (width > 600) {
          cardWidth = (width - AppSpacing.lg) / 2;
        } else {
          cardWidth = width;
        }

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: _statsData.map((data) {
            return Container(
              width: cardWidth,
              constraints: const BoxConstraints(
                minHeight: 120,
              ),
              child: StatCard(
                title: data['title'] as String,
                value: data['value'] as String,
                change: data['change'] as String,
                isPositive: data['isPositive'] as bool,
                icon: data['icon'] as IconData,
                color: data['color'] as Color,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  static const List<Map<String, dynamic>> _actions = [
    {'icon': Icons.receipt_long_rounded, 'label': 'New Invoice', 'color': AppColors.primary, 'route': AppRoutes.newInvoice},
    {'icon': Icons.description_outlined, 'label': 'New Quotation', 'color': Color(0xFF06B6D4), 'route': AppRoutes.newQuotation},
    {'icon': Icons.person_add_rounded, 'label': 'Add Client', 'color': Color(0xFF22C55E), 'route': AppRoutes.newClient},
    {'icon': Icons.inventory_2_outlined, 'label': 'Add Product', 'color': Color(0xFFF59E0B), 'route': AppRoutes.newProduct},
    {'icon': Icons.bar_chart_rounded, 'label': 'View Report', 'color': Color(0xFF8B5CF6), 'route': AppRoutes.reports},
    {'icon': Icons.send_rounded, 'label': 'Send Reminder', 'color': Color(0xFFEF4444), 'route': AppRoutes.sendReminder},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: _actions
              .map((a) => ActionChip(
                    avatar: Icon(a['icon'] as IconData, size: 18, color: a['color'] as Color),
                    label: Text(
                      a['label'] as String,
                      style: AppTextStyles.labelLarge.copyWith(color: Colors.black87),
                    ),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    ),
                    onPressed: () {
                      if (a['label'] == 'Add Product') {
                        showDialog(
                          context: context,
                          builder: (_) => const ProductFormDialog(),
                        );
                      } else if (a['route'] != null) {
                        context.push(a['route'] as String);
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Getting Started Grid ─────────────────────────────────────────────────────

class _GettingStartedGrid extends StatelessWidget {
  static const _blocks = [
    _BlockData(
      icon: Icons.receipt_long_rounded,
      iconColor: AppColors.primary,
      title: 'Invoices',
      description:
          'Create professional GST invoices, track payment status, send reminders to clients, and download PDFs instantly.',
      actionLabel: 'Create New Invoice',
      route: AppRoutes.newInvoice,
      listRoute: AppRoutes.invoices,
    ),
    _BlockData(
      icon: Icons.description_rounded,
      iconColor: Color(0xFF06B6D4),
      title: 'Quotations',
      description:
          'Send accurate estimates to clients and convert approved quotations into invoices with a single click.',
      actionLabel: 'Create New Quotation',
      route: AppRoutes.newQuotation,
      listRoute: AppRoutes.quotations,
    ),
    _BlockData(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFFF59E0B),
      title: 'Expenses',
      description:
          'Record purchase orders, vendor bills, and day-to-day expenses to keep your books accurate and up to date.',
      actionLabel: 'Record New Purchase',
      route: AppRoutes.newPurchaseOrder,
      listRoute: AppRoutes.purchaseOrders,
    ),
    _BlockData(
      icon: Icons.people_rounded,
      iconColor: Color(0xFF22C55E),
      title: 'Client Management',
      description:
          'Maintain a full client directory with contact details, billing history, and outstanding balance tracking.',
      actionLabel: 'Add New Client',
      route: AppRoutes.newClient,
      listRoute: AppRoutes.clients,
    ),
  
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Getting Started', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double cardWidth;
            if (width > 1200) {
              cardWidth = (width - (AppSpacing.lg * 3)) / 4;
            } else if (width > 800) {
              cardWidth = (width - (AppSpacing.lg * 2)) / 3;
            } else if (width > 500) {
              cardWidth = (width - AppSpacing.lg) / 2;
            } else {
              cardWidth = width;
            }
            
            return Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: _blocks.map((b) {
                return SizedBox(
                  width: cardWidth,
                  child: FeatureBlockCard(
                    icon: b.icon,
                    iconColor: b.iconColor,
                    title: b.title,
                    description: b.description,
                    actionLabel: b.actionLabel,
                    onAction: () => context.push(b.route),
                    onCardTap: () => context.push(b.listRoute),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Immutable data holder for a single Getting Started block.
class _BlockData {
  const _BlockData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.route,
    required this.listRoute,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final String route;
  final String listRoute;
}

