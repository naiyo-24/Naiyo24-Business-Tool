import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/invoice_line_item.dart';
import '../../models/invoice_model.dart';
import '../../notifiers/auth_notifier.dart';
import '../../notifiers/invoice_notifier.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import 'widgets/record_payment_dialog.dart';

/// Full Invoice Detail / View screen.
///
/// Displays:
///   - Invoice metadata (number, dates, status)
///   - Customer snapshot
///   - Line items breakdown table
///   - Financial summary (sub-total, discount, GST, grand total)
///   - Payment status (paid / due)
///   - "Record Payment" button to update payment
class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final invoice =
        ref.watch(invoiceNotifierProvider.notifier).findById(invoiceId);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (invoice == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(email: authState.userEmail, showBackButton: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: AppSpacing.md),
              Text('Invoice not found.',
                  style: AppTextStyles.h2
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(AppRoutes.invoices),
                child: const Text('Back to Invoices'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail, showBackButton: true),
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  // ── Page header bar ──────────────────────────────────────────
                  _HeaderBar(invoice: invoice),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Main content (two-column on desktop) ─────────────────────
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _InvoiceMeta(invoice: invoice),
                                  const SizedBox(height: AppSpacing.lg),
                                  _CustomerCard(invoice: invoice),
                                  const SizedBox(height: AppSpacing.lg),
                                  _LineItemsTable(invoice: invoice),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xl),
                            SizedBox(
                              width: 300,
                              child: Column(
                                children: [
                                  _FinancialSummary(invoice: invoice),
                                  const SizedBox(height: AppSpacing.lg),
                                  _PaymentPanel(invoice: invoice),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _InvoiceMeta(invoice: invoice),
                            const SizedBox(height: AppSpacing.lg),
                            _CustomerCard(invoice: invoice),
                            const SizedBox(height: AppSpacing.lg),
                            _LineItemsTable(invoice: invoice),
                            const SizedBox(height: AppSpacing.lg),
                            _FinancialSummary(invoice: invoice),
                            const SizedBox(height: AppSpacing.lg),
                            _PaymentPanel(invoice: invoice),
                          ],
                        ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header bar with back button + action buttons ─────────────────────────────

class _HeaderBar extends ConsumerWidget {
  const _HeaderBar({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final titleRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.invoices);
                }
              },
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
                  Text(invoice.invoiceNo, style: AppTextStyles.h1),
                  Text('Invoice Details',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        );
        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (invoice.status != InvoiceStatus.paid) ...[
              FilledButton.icon(
                onPressed: () => _showRecordPayment(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.md)),
                ),
                icon: const Icon(Icons.payments_rounded,
                    size: 18, color: Colors.white),
                label: Text('Record Payment',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: Colors.white)),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.returnItemsPath(invoice.id)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.md)),
              ),
              icon: const Icon(Icons.assignment_return_rounded,
                  size: 18, color: AppColors.warning),
              label: Text('Return',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.warning)),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.md)),
              ),
              icon: const Icon(Icons.delete_rounded,
                  size: 18, color: AppColors.error),
              label: Text('Delete',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.error)),
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
    );
  }

  void _showRecordPayment(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => RecordPaymentDialog(invoice: invoice),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
            'Delete ${invoice.invoiceNo} for ${invoice.customerName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              ref
                  .read(invoiceNotifierProvider.notifier)
                  .deleteInvoice(invoice.id);
              Navigator.pop(ctx);
              context.go(AppRoutes.invoices);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Invoice Meta Row ─────────────────────────────────────────────────────────

class _InvoiceMeta extends StatelessWidget {
  const _InvoiceMeta({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final (statusLabel, statusColor) = switch (invoice.status) {
      InvoiceStatus.paid => ('PAID', AppColors.success),
      InvoiceStatus.partial => ('PARTIAL', AppColors.warning),
      InvoiceStatus.due => ('DUE', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.md,
        children: [
          _metaTile('Invoice No.',
              invoice.invoiceNo, Icons.tag_rounded, AppColors.primary),
          _metaTile('Invoice Date',
              fmt(invoice.invoiceDate), Icons.calendar_today_rounded,
              AppColors.textSecondary),
          _metaTile('Due Date',
              fmt(invoice.dueDate), Icons.event_rounded,
              AppColors.textSecondary),
          _metaTile('Payment Method',
              invoice.paymentMethod, Icons.payment_rounded,
              AppColors.textSecondary),
          // Status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppBorderRadius.full),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(statusLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                        color: statusColor, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaTile(
      String label, String value, IconData icon, Color iconColor) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Customer Card ────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            child: Text(
              invoice.customerName[0].toUpperCase(),
              style: AppTextStyles.h2
                  .copyWith(color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bill To',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(invoice.customerName,
                    style: AppTextStyles.h2),
                const SizedBox(height: 4),
                _row(Icons.phone_rounded, invoice.customerMobile),
                if (invoice.customerAddress != null)
                  _row(Icons.location_on_rounded,
                      invoice.customerAddress!),
                if (invoice.customerGst != null)
                  _row(Icons.business_rounded,
                      'GSTIN: ${invoice.customerGst!}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

// ─── Line Items Table ─────────────────────────────────────────────────────────

class _LineItemsTable extends StatelessWidget {
  const _LineItemsTable({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            color: AppColors.surfaceVariant,
            child: Text('Line Items',
                style: AppTextStyles.labelLarge
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                  bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _hdr('ITEM', flex: 4),
                _hdr('QTY', flex: 1, center: true),
                _hdr('RATE', flex: 2, right: true),
                _hdr('DISC%', flex: 1, center: true),
                _hdr('GST%', flex: 1, center: true),
                _hdr('AMOUNT', flex: 2, right: true),
              ],
            ),
          ),
          // Data rows
          ...invoice.lineItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return _ItemRow(item: item, isEven: i.isEven);
          }),
          // Totals footer
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border:
                  Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 9,
                  child: Text('Total',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${invoice.grandTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(String t,
      {int flex = 1, bool center = false, bool right = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
        textAlign: right
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.isEven});
  final InvoiceLineItem item;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final isProduct = item.itemType == LineItemType.product;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isEven ? AppColors.surface : AppColors.background,
        border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isProduct
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : const Color(0xFF0284C7)
                            .withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.xs),
                  ),
                  child: Text(
                    isProduct ? 'P' : 'S',
                    style: AppTextStyles.caption.copyWith(
                      color: isProduct
                          ? AppColors.primary
                          : const Color(0xFF0284C7),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(item.code,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.qty.toStringAsFixed(
                  item.qty % 1 == 0 ? 0 : 2),
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.rate.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.discountPercent.toStringAsFixed(0)}%',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.gstPercent.toStringAsFixed(0)}%',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.totalAmount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Financial Summary Card ───────────────────────────────────────────────────

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Summary',
              style: AppTextStyles.labelLarge
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _row('Sub Total', '₹${invoice.subTotal.toStringAsFixed(2)}'),
          if (invoice.totalDiscount > 0)
            _row('Discount',
                '- ₹${invoice.totalDiscount.toStringAsFixed(2)}',
                color: AppColors.success),
          _row('GST', '₹${invoice.totalGst.toStringAsFixed(2)}'),
          if (invoice.roundOff != 0)
            _row('Round Off',
                '${invoice.roundOff >= 0 ? '+' : ''}₹${invoice.roundOff.toStringAsFixed(2)}'),
          const Divider(color: AppColors.border, height: AppSpacing.xl),
          _row('Grand Total',
              '₹${invoice.grandTotal.toStringAsFixed(2)}',
              bold: true, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}

// ─── Payment Panel ────────────────────────────────────────────────────────────

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (invoice.status) {
      InvoiceStatus.paid => (AppColors.success, 'Fully Paid'),
      InvoiceStatus.partial => (AppColors.warning, 'Partially Paid'),
      InvoiceStatus.due => (AppColors.error, 'Payment Due'),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Status',
              style: AppTextStyles.labelLarge
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),

          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  invoice.status == InvoiceStatus.paid
                      ? Icons.check_circle_rounded
                      : invoice.status == InvoiceStatus.partial
                          ? Icons.timelapse_rounded
                          : Icons.warning_rounded,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(statusLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Amount rows
          _amtRow('Invoice Amount',
              '₹${invoice.grandTotal.toStringAsFixed(2)}',
              AppColors.textPrimary),
          _amtRow('Amount Paid',
              '₹${invoice.paidAmount.toStringAsFixed(2)}',
              AppColors.success),
          const Divider(color: AppColors.border, height: AppSpacing.lg),
          _amtRow('Balance Due',
              '₹${invoice.dueAmount.toStringAsFixed(2)}',
              invoice.dueAmount > 0
                  ? AppColors.error
                  : AppColors.success,
              bold: true),
        ],
      ),
    );
  }

  Widget _amtRow(String label, String value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                  fontSize: bold ? 15 : 14)),
        ],
      ),
    );
  }
}
