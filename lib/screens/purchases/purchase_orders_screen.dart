import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../notifiers/purchase_order_notifier.dart';
import '../../notifiers/auth_notifier.dart';
import '../../models/purchase_order_model.dart';
import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/loading_placeholder.dart';

bool _isFirstLoadPO = true;
final asyncPurchaseOrderProvider = FutureProvider.autoDispose((ref) async {
  ref.onDispose(() => _isFirstLoadPO = true);
  final data = ref.watch(purchaseOrderNotifierProvider);
  if (_isFirstLoadPO) {
    await Future.delayed(const Duration(seconds: 1));
    _isFirstLoadPO = false;
  }
  return data;
});


class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  POStatus? _filterStatus;

  void _logout(BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  void _handleExport(BuildContext context, List<PurchaseOrderModel> pos) {
    final csvContent = [
      'PO Number,Date,Vendor,Title,Amount,Status',
      ...pos.map((p) => '${p.poNumber},${p.date.toIso8601String().split('T')[0]},"${p.vendorName}","${p.title}",${p.totalAmount},${p.status.name}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Purchase Order Export*',
      'Total POs: ${pos.length}',
      ...pos.map((p) => '- ${p.poNumber} | ${p.vendorName} | ₹${p.totalAmount} (${p.status.name.toUpperCase()})')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Purchase Orders Report',
      '==============================================',
      'PO Number\tDate\tVendor\tTotal\tStatus',
      ...pos.map((p) => '${p.poNumber}\t${p.date.toIso8601String().split('T')[0]}\t${p.vendorName}\t₹${p.totalAmount}\t${p.status.name}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Purchase Orders',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'purchase_orders',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final asyncPos = ref.watch(asyncPurchaseOrderProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isDesktop
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(context),
                currentRoute: AppRoutes.purchaseOrders,
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newPurchaseOrder),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create PO', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        children: [
          if (isDesktop)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () => _logout(context),
              currentRoute: AppRoutes.purchaseOrders,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      final titleRow = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => context.go(AppRoutes.dashboard),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  size: 20, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.shopping_bag_rounded,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Purchase Orders', style: AppTextStyles.h1),
                                const SizedBox(height: 4),
                                Text('Manage and track all your purchase orders.', style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      );
                      final actionButtons = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              final currentPos = ref.read(purchaseOrderNotifierProvider);
                              final currentFiltered = _filterStatus == null
                                  ? currentPos
                                  : currentPos.where((p) => p.status == _filterStatus).toList();
                              _handleExport(context, currentFiltered);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.md),
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded,
                                size: 18, color: AppColors.textPrimary),
                            label: Text('Export',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: () => context.push(AppRoutes.newPurchaseOrder),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Purchase Order'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              ),
                            ),
                          ),
                        ],
                      );
                      if (isWide) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: titleRow),
                            const SizedBox(width: AppSpacing.md),
                            actionButtons,
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleRow,
                          const SizedBox(height: AppSpacing.md),
                          actionButtons,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Filter chips
                  Row(
                    children: [
                      Text('Filter by Status: ', style: AppTextStyles.bodyMedium),
                      const SizedBox(width: AppSpacing.sm),
                      _filterChip('All', _filterStatus == null, () => setState(() => _filterStatus = null)),
                      const SizedBox(width: AppSpacing.sm),
                      _filterChip('Unpaid', _filterStatus == POStatus.unpayed, () => setState(() => _filterStatus = POStatus.unpayed)),
                      const SizedBox(width: AppSpacing.sm),
                      _filterChip('Paid', _filterStatus == POStatus.payed, () => setState(() => _filterStatus = POStatus.payed)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Table
                  asyncPos.when(
                    loading: () => const LoadingPlaceholder(
                        message: 'Loading purchase orders...'),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (pos) {
                      final filteredPos = _filterStatus == null
                          ? pos
                          : pos.where((p) => p.status == _filterStatus).toList();

                      final totalUnpayed = pos
                          .where((p) => p.status == POStatus.unpayed)
                          .fold(0.0, (sum, p) => sum + p.totalAmount);

                      if (pos.isEmpty) {
                        return EmptyStatePlaceholder(
                          icon: Icons.shopping_bag_outlined,
                          title: 'No purchase orders found',
                          message: 'Create a new purchase order to track expenses.',
                          actionLabel: 'Create PO',
                          onAction: () => context.push(AppRoutes.newPurchaseOrder),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                                headingTextStyle: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                                dividerThickness: 1,
                                dataRowMaxHeight: 64,
                                dataRowMinHeight: 64,
                                columns: const [
                                  DataColumn(label: Text('PO NUMBER')),
                                  DataColumn(label: Text('DATE')),
                                  DataColumn(label: Text('VENDOR')),
                                  DataColumn(label: Text('TOTAL AMOUNT')),
                                  DataColumn(label: Text('STATUS')),
                                ],
                                rows: filteredPos.map((po) {
                                  final isPayed = po.status == POStatus.payed;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(po.poNumber, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
                                      DataCell(Text(DateFormat('MMM dd, yyyy').format(po.date), style: AppTextStyles.bodyMedium)),
                                      DataCell(Text(po.vendorName, style: AppTextStyles.bodyMedium)),
                                      DataCell(Text('₹${po.totalAmount.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
                                      DataCell(
                                        Tooltip(
                                          message: 'Tap to toggle status',
                                          child: InkWell(
                                            onTap: () => ref.read(purchaseOrderNotifierProvider.notifier).toggleStatus(po.id),
                                            borderRadius: BorderRadius.circular(100),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isPayed
                                                    ? AppColors.success.withValues(alpha: 0.1)
                                                    : AppColors.error.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(100),
                                                border: Border.all(
                                                  color: isPayed ? AppColors.success : AppColors.error,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPayed ? Icons.check_circle_rounded : Icons.warning_rounded,
                                                    size: 14,
                                                    color: isPayed ? AppColors.success : AppColors.error,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    isPayed ? 'Paid' : 'Unpaid',
                                                    style: AppTextStyles.labelLarge.copyWith(
                                                      color: isPayed ? AppColors.success : AppColors.error,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          // Total Unpaid Summary Banner
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Unpaid Balance',
                                      style: AppTextStyles.labelLarge.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${totalUnpayed.toStringAsFixed(2)}',
                                      style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: AppTextStyles.labelLarge.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
    );
  }
}
