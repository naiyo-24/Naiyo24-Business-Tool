import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/invoice_model.dart';
import '../../notifiers/auth_notifier.dart';
import '../../notifiers/invoice_notifier.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/send_options_dialog.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/loading_placeholder.dart';

bool _isFirstLoadInv = true;
final asyncInvoicesProvider = FutureProvider.autoDispose((ref) async {
  ref.onDispose(() => _isFirstLoadInv = true);
  final data = ref.watch(invoiceNotifierProvider);
  if (_isFirstLoadInv) {
    await Future.delayed(const Duration(seconds: 1));
    _isFirstLoadInv = false;
  }
  return data;
});

/// Invoice List screen — shows all saved invoices from [InvoiceNotifier].
/// The "Create Invoice" button navigates to [AppRoutes.newInvoice].
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  InvoiceStatus? _filterStatus; // null = show all

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleExport(BuildContext context, List<InvoiceModel> invoices) {
    final csvContent = [
      'Invoice No,Date,Client,Subtotal,Tax,Total,Status',
      ...invoices.map((inv) => '${inv.invoiceNo},${inv.invoiceDate},"${inv.customerName}",${inv.subTotal},${inv.totalGst},${inv.grandTotal},${inv.status.name}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Invoice Export*',
      'Total Invoices: ${invoices.length}',
      ...invoices.map((inv) => '- ${inv.invoiceNo} | ${inv.customerName} | ₹${inv.grandTotal} (${inv.status.name.toUpperCase()})')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Invoices Report',
      '======================================',
      'Invoice No\tDate\tClient\tTotal\tStatus',
      ...invoices.map((inv) => '${inv.invoiceNo}\t${inv.invoiceDate}\t${inv.customerName}\t₹${inv.grandTotal}\t${inv.status.name}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Invoices',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'invoices',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final asyncInvoices = ref.watch(asyncInvoicesProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isDesktop
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go(AppRoutes.login);
                },
                currentRoute: AppRoutes.invoices,
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newInvoice),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create new invoice', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        children: [
          if (isDesktop)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () {
                ref.read(authNotifierProvider.notifier).logout();
                context.go(AppRoutes.login);
              },
              currentRoute: AppRoutes.invoices,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page header ─────────────────────────────────────────────
                  // NOTE: Do NOT use Wrap here — Wrap passes infinite width to
                  // its children which crashes OutlinedButton text layout.
                  // LayoutBuilder receives the actual bounded width from the
                  // Expanded+SingleChildScrollView ancestor above.
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;

                      // Shared widgets ──────────────────────────────────────────
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
                          const Icon(Icons.receipt_long_rounded,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoices', style: AppTextStyles.h1),
                                Text('Manage and track your customer invoices.',
                                    style: AppTextStyles.bodyMedium),
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
                              final currentInvoices = ref.read(invoiceNotifierProvider);
                              _handleExport(context, currentInvoices);
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
                            onPressed: () => context.push(AppRoutes.newInvoice),
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
                            label: Text('Create new invoice',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white)),
                          ),
                        ],
                      );

                      // Wide: single row with title left, actions right ─────────
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

                      // Narrow: stacked column ──────────────────────────────────
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

                  // ── Invoice list ────────────────────────────────────────────
                  asyncInvoices.when(
                    loading: () => const LoadingPlaceholder(
                        message: 'Loading invoices...'),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (allInvoices) {
                      final filtered = allInvoices.where((inv) {
                        final q = _searchCtrl.text.toLowerCase();
                        final matchesSearch = q.isEmpty ||
                            inv.invoiceNo.toLowerCase().contains(q) ||
                            inv.customerName.toLowerCase().contains(q);
                        final matchesStatus =
                            _filterStatus == null || inv.status == _filterStatus;
                        return matchesSearch && matchesStatus;
                      }).toList()
                        ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryChips(invoices: allInvoices),
                          const SizedBox(height: AppSpacing.lg),
                          _filterBar(),
                          const SizedBox(height: AppSpacing.lg),
                          
                          if (filtered.isEmpty)
                            EmptyStatePlaceholder(
                              icon: Icons.receipt_long_outlined,
                              title: 'No invoices found',
                              message: (_searchCtrl.text.isNotEmpty || _filterStatus != null)
                                  ? 'No invoices matched your search.'
                                  : 'No invoices yet.\nTap "Create Invoice" to get started.',
                              actionLabel: 'Create Invoice',
                              onAction: () => context.push(AppRoutes.newInvoice),
                            )
                          else
                            _InvoiceDataTable(
                              invoices: filtered,
                              onDelete: _confirmDelete,
                            ),
                          
                          if (filtered.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                'Total Invoices: ${filtered.length}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
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

  Widget _filterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search by client name or invoice number...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Status filter dropdown
        DropdownButtonHideUnderline(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<InvoiceStatus?>(
              value: _filterStatus,
              hint: const Text('All Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(
                    value: InvoiceStatus.paid,
                    child: Text('Paid',
                        style: TextStyle(color: AppColors.success))),
                DropdownMenuItem(
                    value: InvoiceStatus.partial,
                    child: Text('Partial',
                        style: TextStyle(color: AppColors.warning))),
                DropdownMenuItem(
                    value: InvoiceStatus.due,
                    child: Text('Due',
                        style: TextStyle(color: AppColors.error))),
              ],
              onChanged: (v) => setState(() => _filterStatus = v),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(InvoiceModel inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
            'Delete ${inv.invoiceNo} for ${inv.customerName}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref
                  .read(invoiceNotifierProvider.notifier)
                  .deleteInvoice(inv.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Chips ────────────────────────────────────────────────────────────

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.invoices});
  final List<InvoiceModel> invoices;

  @override
  Widget build(BuildContext context) {
    final total = invoices.fold(0.0, (s, i) => s + i.grandTotal);
    final paid = invoices
        .where((i) => i.status == InvoiceStatus.paid)
        .length;
    final due = invoices
        .where((i) => i.status == InvoiceStatus.due)
        .fold(0.0, (s, i) => s + i.dueAmount);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _chip('Total Invoiced', '₹${total.toStringAsFixed(0)}',
            AppColors.primary, Icons.receipt_rounded),
        _chip('Paid Invoices', '$paid',
            AppColors.success, Icons.check_circle_rounded),
        _chip('Total Due', '₹${due.toStringAsFixed(0)}',
            AppColors.error, Icons.warning_rounded),
      ],
    );
  }

  Widget _chip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label: ',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Invoice Data Table ───────────────────────────────────────────────────────

class _InvoiceDataTable extends StatelessWidget {
  const _InvoiceDataTable({
    required this.invoices,
    required this.onDelete,
  });

  final List<InvoiceModel> invoices;
  final void Function(InvoiceModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppColors.surfaceVariant),
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columnSpacing: 20,
          headingTextStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
          columns: const [
            DataColumn(label: Text('INVOICE NO.')),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('CUSTOMER')),
            DataColumn(label: Text('TOTAL'), numeric: true),
            DataColumn(label: Text('PAID'), numeric: true),
            DataColumn(label: Text('DUE'), numeric: true),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTION')),
          ],
          rows: invoices.map((inv) {
            return DataRow(cells: [
              DataCell(Text(inv.invoiceNo,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600))),
              DataCell(Text(
                '${inv.invoiceDate.day.toString().padLeft(2, '0')}/'
                '${inv.invoiceDate.month.toString().padLeft(2, '0')}/'
                '${inv.invoiceDate.year}',
                style: AppTextStyles.caption,
              )),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.customerName,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(inv.customerMobile,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary)),
                ],
              )),
              DataCell(Text('₹${inv.grandTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700))),
              DataCell(Text('₹${inv.paidAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.success))),
              DataCell(Text('₹${inv.dueAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: inv.dueAmount > 0
                          ? AppColors.error
                          : AppColors.textSecondary))),
              DataCell(_InvoiceStatusBadge(status: inv.status)),
              DataCell(Row(children: [
                Tooltip(
                  message: 'View',
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.invoiceDetailPath(inv.id)),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.visibility_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Tooltip(
                  message: 'Send Invoice',
                  child: InkWell(
                    onTap: () => _showSendOptionsDialog(context, inv),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.send_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Tooltip(
                  message: 'Delete',
                  child: InkWell(
                    onTap: () => onDelete(inv),
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.sm),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_rounded,
                          size: 18, color: AppColors.error),
                    ),
                  ),
                ),
              ])),

            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showSendOptionsDialog(BuildContext context, InvoiceModel invoice) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    final waContent = [
      '*Naiyo24 Invoice*',
      'Invoice No: ${invoice.invoiceNo}',
      'Client: ${invoice.customerName}',
      'Amount: ${formatCurrency.format(invoice.grandTotal)}',
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Invoice',
      '========================================',
      'Invoice No: ${invoice.invoiceNo}',
      'Client: ${invoice.customerName}',
      'Amount: ${formatCurrency.format(invoice.grandTotal)}',
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => SendOptionsDialog(
        title: 'Invoice',
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'invoice_${invoice.invoiceNo}',
        onClose: () {},
      ),
    );
  }
}

// ─── Invoice Status Badge ─────────────────────────────────────────────────────

class _InvoiceStatusBadge extends StatelessWidget {
  const _InvoiceStatusBadge({required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InvoiceStatus.paid => ('Paid', AppColors.success),
      InvoiceStatus.partial => ('Partial', AppColors.warning),
      InvoiceStatus.due => ('Due', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

