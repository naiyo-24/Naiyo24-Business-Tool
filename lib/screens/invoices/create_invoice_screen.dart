import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/customer_model.dart';
import '../../models/invoice_line_item.dart';
import '../../models/invoice_model.dart';
import '../../notifiers/auth_notifier.dart';
import '../../notifiers/invoice_notifier.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import 'widgets/invoice_autocomplete_fields.dart';
import 'widgets/invoice_line_item_row.dart';
import 'package:intl/intl.dart';
import '../../widgets/send_options_dialog.dart';

/// Full "Create New Invoice" screen.
///
/// Flow:
///   1. Select or add customer         → CustomerAutocomplete
///   2. Search and add line items      → ItemSearchAutocomplete + LineItemRow
///   3. Review totals / enter payment  → InvoiceTotalsCard
///   4. Save / Save & Print            → InvoiceNotifier.saveInvoice()
class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState
    extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── State ──────────────────────────────────────────────────────────────────
  CustomerModel? _selectedCustomer;
  List<InvoiceLineItem> _lineItems = [];
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  String _paymentMethod = 'Cash';
  double _paidAmount = 0;
  bool _isSaving = false;

  // ── Computed totals ────────────────────────────────────────────────────────
  double get _subTotal =>
      _lineItems.fold(0, (s, i) => s + (i.rate * i.qty));
  double get _totalDiscount =>
      _lineItems.fold(0, (s, i) => s + i.discountAmount);
  double get _totalGst =>
      _lineItems.fold(0, (s, i) => s + i.gstAmount);
  double get _grandTotal => _subTotal - _totalDiscount + _totalGst;

  Future<bool> _onWillPop() async {
    if (_selectedCustomer == null && _lineItems.isEmpty) {
      return true;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?', style: AppTextStyles.h2),
        content: Text('You have unsaved changes. Are you sure you want to discard them?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Discard', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final isMedium = MediaQuery.of(context).size.width >= 900;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: DashboardAppBar(email: authState.userEmail, showBackButton: true),
        drawer: !isMedium
            ? Drawer(
                child: SideNavigation(
                  email: authState.userEmail,
                  onLogout: () =>
                      ref.read(authNotifierProvider.notifier).logout(),
                  currentRoute: AppRoutes.invoices,
                ),
              )
            : null,
        body: Row(
          children: [
            if (isMedium)
              SideNavigation(
                email: authState.userEmail,
                onLogout: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                currentRoute: AppRoutes.invoices,
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: isDesktop
                    ? _desktopLayout()
                    : _mobileLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop: two-column layout ─────────────────────────────────────────────
  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left – main invoice editor
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: AppSpacing.lg),
                _invoiceMetaRow(),
                const SizedBox(height: AppSpacing.lg),
                _customerSection(),
                const SizedBox(height: AppSpacing.xl),
                _lineItemsSection(),
              ],
            ),
          ),
        ),
        // Right – totals + actions sidebar
        Container(
          width: 340,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                InvoiceTotalsCard(
                  subTotal: _subTotal,
                  totalDiscount: _totalDiscount,
                  totalGst: _totalGst,
                  roundOff: 0,
                  grandTotal: _grandTotal,
                  paidAmount: _paidAmount,
                  paymentMethod: _paymentMethod,
                  onPaidAmountChanged: (v) =>
                      setState(() => _paidAmount = v),
                  onPaymentMethodChanged: (v) =>
                      setState(() => _paymentMethod = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                _actionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile: single column layout ──────────────────────────────────────────
  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: AppSpacing.lg),
          _invoiceMetaRow(),
          const SizedBox(height: AppSpacing.lg),
          _customerSection(),
          const SizedBox(height: AppSpacing.xl),
          _lineItemsSection(),
          const SizedBox(height: AppSpacing.xl),
          InvoiceTotalsCard(
            subTotal: _subTotal,
            totalDiscount: _totalDiscount,
            totalGst: _totalGst,
            roundOff: 0,
            grandTotal: _grandTotal,
            paidAmount: _paidAmount,
            paymentMethod: _paymentMethod,
            onPaidAmountChanged: (v) => setState(() => _paidAmount = v),
            onPaymentMethodChanged: (v) =>
                setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          _actionButtons(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
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
        Expanded(
          child: Text('Create New Invoice', style: AppTextStyles.h1),
        ),
      ],
    );
  }

  Widget _invoiceMetaRow() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          // Auto-generated invoice number preview
          _metaField(
            label: 'Invoice No.',
            value: 'Auto-generated on save',
            icon: Icons.tag_rounded,
          ),
          // Invoice date picker
          _metaDateField(
            label: 'Invoice Date',
            date: _invoiceDate,
            onPicked: (d) => setState(() => _invoiceDate = d),
          ),
          // Due date picker
          _metaDateField(
            label: 'Due Date',
            date: _dueDate,
            onPicked: (d) => setState(() => _dueDate = d),
          ),
        ],
      ),
    );
  }

  Widget _metaField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaDateField({
    required String label,
    required DateTime date,
    required void Function(DateTime) onPicked,
  }) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) onPicked(picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/'
                    '${date.year}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('1. Select Customer', Icons.person_rounded),
        const SizedBox(height: AppSpacing.md),
        // Customer autocomplete + Add New Client button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomerAutocomplete(
                selectedCustomer: _selectedCustomer,
                onSelected: (c) => setState(() => _selectedCustomer = c),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.newClient),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
              icon: const Icon(Icons.person_add_rounded,
                  size: 16, color: Colors.white),
              label: const Text(
                'Add New Client',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        // Customer details card (shown after selection)
        if (_selectedCustomer != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CustomerDetailsCard(customer: _selectedCustomer!),
        ],
      ],
    );
  }

  Widget _lineItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('2. Add Products / Services', Icons.add_shopping_cart_rounded),
        const SizedBox(height: AppSpacing.md),

        // Item search autocomplete + Add New Product button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ItemSearchAutocomplete(
                onSelected: (item) {
                  setState(() => _lineItems = [..._lineItems, item]);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.newProduct),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
              icon: const Icon(Icons.add_box_rounded,
                  size: 16, color: Colors.white),
              label: const Text(
                'Add New Product',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Line items table
        if (_lineItems.isEmpty)
          _emptyItemsHint()
        else
          _lineItemsTable(),

        // Clear all
        if (_lineItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _lineItems = []),
              icon: const Icon(Icons.delete_sweep_rounded,
                  size: 16, color: AppColors.error),
              label: Text('Clear All',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.error)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _lineItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Minimum width required to show all columns without squishing
          const double minTableWidth = 720;
          final double tableWidth = constraints.maxWidth > minTableWidth
              ? constraints.maxWidth
              : minTableWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: tableWidth,
                maxWidth: tableWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LineItemsHeader(),
                  ..._lineItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return LineItemRow(
                      key: ValueKey(item.id),
                      item: item,
                      index: i,
                      onChanged: (updated) {
                        setState(() {
                          _lineItems = [
                            for (final li in _lineItems)
                              li.id == updated.id ? updated : li,
                          ];
                        });
                      },
                      onDelete: () {
                        setState(() {
                          _lineItems =
                              _lineItems.where((li) => li.id != item.id).toList();
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyItemsHint() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_shopping_cart_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Search and add products or services above.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save Invoice
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveInvoice,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded, size: 20, color: Colors.white),
          label: Text(
            _isSaving ? 'Saving...' : 'Save Invoice',
            style:
                AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Save & Send Invoice
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveAndSendInvoice,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
          label: Text(
            _isSaving ? 'Saving...' : 'Save & Send',
            style:
                AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Cancel
        OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          child: Text('Cancel',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  // ── Save logic ─────────────────────────────────────────────────────────────

  Future<void> _saveInvoice() async {
    await _saveInvoiceInternal(navigate: true);
  }

  Future<InvoiceModel?> _saveInvoiceInternal({required bool navigate}) async {
    // Validate form
    if (!_formKey.currentState!.validate()) return null;
    if (_selectedCustomer == null) {
      _showError('Please select a customer.');
      return null;
    }
    if (_lineItems.isEmpty) {
      _showError('Add at least one product or service.');
      return null;
    }

    setState(() => _isSaving = true);

    // Small artificial delay for UX feedback
    await Future.delayed(const Duration(milliseconds: 400));

    final invoice = InvoiceModel(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: '', // auto-assigned by InvoiceNotifier
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerMobile: _selectedCustomer!.mobile,
      customerAddress: _selectedCustomer!.address,
      customerGst: _selectedCustomer!.gstNumber,
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      lineItems: _lineItems,
      paymentMethod: _paymentMethod,
      paidAmount: _paidAmount,
    );

    final saved =
        ref.read(invoiceNotifierProvider.notifier).saveInvoice(invoice);

    if (!mounted) return null;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${saved.invoiceNo} created for ${saved.customerName}!',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (navigate) {
      // Navigate to invoice list
      context.go(AppRoutes.invoices);
    }
    return saved;
  }

  Future<void> _saveAndSendInvoice() async {
    final saved = await _saveInvoiceInternal(navigate: false);
    if (saved != null && mounted) {
      _showSendOptionsDialog(context, saved);
    }
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.h2),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );
}

// ─── Customer Details Card (shown after selection) ────────────────────────────

class _CustomerDetailsCard extends StatelessWidget {
  const _CustomerDetailsCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              customer.name[0].toUpperCase(),
              style: AppTextStyles.h2
                  .copyWith(color: Colors.white, fontSize: 18),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (customer.mobile.isNotEmpty)
                  _detail(Icons.phone_rounded, customer.mobile),
                if (customer.address != null)
                  _detail(
                      Icons.location_on_rounded, customer.address!),
                if (customer.gstNumber != null)
                  _detail(Icons.business_rounded, customer.gstNumber!),
              ],
            ),
          ),
          // Credit info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _chip('Credit Limit',
                  '₹${customer.creditLimit.toStringAsFixed(0)}'),
              const SizedBox(height: 4),
              _chip('Opening Bal.',
                  '₹${customer.openingBalance.toStringAsFixed(0)}',
                  color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _chip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary, fontSize: 10)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.primary)),
        ],
      ),
    );
  }
}
