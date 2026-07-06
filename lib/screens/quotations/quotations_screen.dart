import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../models/quotation_model.dart';
import '../../notifiers/auth_notifier.dart';
import '../../notifiers/quotation_notifier.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/send_options_dialog.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/loading_placeholder.dart';

bool _isFirstLoadQuo = true;
final asyncQuotationProvider = FutureProvider.autoDispose((ref) async {
  ref.onDispose(() => _isFirstLoadQuo = true);
  final data = ref.watch(quotationNotifierProvider);
  if (_isFirstLoadQuo) {
    await Future.delayed(const Duration(seconds: 1));
    _isFirstLoadQuo = false;
  }
  return data;
});

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  String _searchQuery = '';

  void _logout(BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  Color _getStatusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.accepted:
        return AppColors.success;
      case QuotationStatus.rejected:
        return AppColors.error;
      case QuotationStatus.sent:
        return const Color(0xFF06B6D4);
      case QuotationStatus.viewed:
        return const Color(0xFF8B5CF6); // Purple
      case QuotationStatus.expired:
        return const Color(0xFFF59E0B); // Orange/Amber
      case QuotationStatus.draft:
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.viewed:
        return 'Viewed';
      case QuotationStatus.expired:
        return 'Expired';
      case QuotationStatus.draft:
      default:
        return 'Draft';
    }
  }

  void _showSendOptionsDialog(BuildContext context, QuotationModel quotation) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final formatDate = DateFormat('dd MMM yyyy');
    
    final waContent = [
      '*Naiyo24 Quotation*',
      'Quotation No: ${quotation.quotationNo}',
      'Client: ${quotation.customerName}',
      'Amount: ${formatCurrency.format(quotation.grandTotal)}',
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Quotation',
      '========================================',
      'Quotation No: ${quotation.quotationNo}',
      'Client: ${quotation.customerName}',
      'Date: ${formatDate.format(quotation.quotationDate)}',
      'Amount: ${formatCurrency.format(quotation.grandTotal)}',
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => SendOptionsDialog(
        title: 'Quotation',
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'quotation_${quotation.quotationNo}',
        onClose: () {},
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, QuotationModel quotation) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text('Update Status', style: AppTextStyles.h2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.lg)),
          backgroundColor: AppColors.surface,
          children: QuotationStatus.values.map((status) {
            final isSelected = quotation.status == status;
            return SimpleDialogOption(
              onPressed: () {
                final updated = quotation.copyWith(status: status);
                ref.read(quotationNotifierProvider.notifier).updateQuotation(updated);
                Navigator.of(ctx).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _getStatusLabel(status),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _handleExport(BuildContext context, List<QuotationModel> quotations) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final formatDate = DateFormat('dd MMM yyyy');

    final csvContent = [
      'Quotation No,Client,Date,Amount,Status',
      ...quotations.map((q) => '${q.quotationNo},"${q.customerName}",${formatDate.format(q.quotationDate)},"${formatCurrency.format(q.grandTotal)}",${_getStatusLabel(q.status)}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Quotation Export*',
      'Total Quotations: ${quotations.length}',
      ...quotations.map((q) => '- ${q.quotationNo} | ${q.customerName} | ${formatCurrency.format(q.grandTotal)} (${_getStatusLabel(q.status)})')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Quotations Report',
      '========================================',
      'Quotation No\tClient\tDate\tAmount\tStatus',
      ...quotations.map((q) => '${q.quotationNo}\t${q.customerName}\t${formatDate.format(q.quotationDate)}\t${formatCurrency.format(q.grandTotal)}\t${_getStatusLabel(q.status)}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Quotations',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'quotations',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final asyncQuotations = ref.watch(asyncQuotationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isDesktop
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(context),
                currentRoute: AppRoutes.quotations,
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newQuotation),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Quotation', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        children: [
          if (isDesktop)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () => _logout(context),
              currentRoute: AppRoutes.quotations,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          const Icon(Icons.description_rounded,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quotations', style: AppTextStyles.h1),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Send estimates to clients and convert them to invoices.', style: AppTextStyles.bodyMedium),
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
                               final current = ref.read(quotationNotifierProvider);
                               final q = _searchQuery.toLowerCase();
                               final filtered = current.where((c) => c.customerName.toLowerCase().contains(q) || c.quotationNo.toLowerCase().contains(q)).toList();
                               _handleExport(context, filtered);
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
                            onPressed: () => context.push(AppRoutes.newQuotation),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.md),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded,
                                size: 18, color: Colors.white),
                            label: Text('Create Quotation',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white)),
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
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Filter bar
                  _buildFilterBar(),
                  const SizedBox(height: AppSpacing.lg),

                  // Quotations list / table
                  asyncQuotations.when(
                    loading: () => const LoadingPlaceholder(message: 'Loading quotations...'),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (data) {
                      final filtered = data.where((q) {
                        final query = _searchQuery.toLowerCase();
                        return q.customerName.toLowerCase().contains(query) ||
                               q.quotationNo.toLowerCase().contains(query);
                      }).toList();
                      
                      return _buildQuotationsTable(context, filtered);
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

  Widget _buildFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search by client name or quotation number...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Advanced filtering coming soon')),
                );
              },
              icon: const Icon(Icons.filter_list_rounded, size: 20),
              label: Text('Filter', style: AppTextStyles.labelLarge),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationsTable(BuildContext context, List<QuotationModel> quotations) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final formatDate = DateFormat('dd MMM yyyy');

    if (quotations.isEmpty) {
      return EmptyStatePlaceholder(
        icon: Icons.description_outlined,
        title: 'No quotations found',
        message: _searchQuery.isNotEmpty 
            ? 'No quotations matched your search.' 
            : 'No quotations yet.\nTap "Create Quotation" to get started.',
        actionLabel: 'Create Quotation',
        onAction: () => context.push(AppRoutes.newQuotation),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
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
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('QUOTATION ID')),
            DataColumn(label: Text('CLIENT')),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('AMOUNT')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: quotations.map((q) {
            final statusLabel = _getStatusLabel(q.status);
            final statusColor = _getStatusColor(q.status);
            return DataRow(
              cells: [
                DataCell(Text(q.quotationNo, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
                DataCell(Text(q.customerName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
                DataCell(Text(formatDate.format(q.quotationDate), style: AppTextStyles.caption)),
                DataCell(Text(formatCurrency.format(q.grandTotal), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
                DataCell(_buildStatusBadge(statusLabel, statusColor)),
                DataCell(Row(
                  children: [
                    Tooltip(
                      message: 'Change Status',
                      child: InkWell(
                        onTap: () => _showStatusUpdateDialog(context, q),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: 'Send Quotation',
                      child: InkWell(
                        onTap: () => _showSendOptionsDialog(context, q),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: 'Delete',
                      child: InkWell(
                        onTap: () {
                          ref.read(quotationNotifierProvider.notifier).deleteQuotation(q.id);
                        },
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // Empty blocks since we now use EmptyStatePlaceholder directly
  // and we replaced _buildHeaderCell and _buildCell functionality with DataTable cells


  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
