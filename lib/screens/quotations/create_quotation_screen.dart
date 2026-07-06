import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/customer_model.dart';
import '../../models/invoice_line_item.dart';
import '../../models/quotation_model.dart';
import '../../notifiers/auth_notifier.dart';
import '../../notifiers/quotation_notifier.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/send_options_dialog.dart';
import '../invoices/widgets/invoice_autocomplete_fields.dart';
import '../invoices/widgets/invoice_line_item_row.dart';

class CreateQuotationScreen extends ConsumerStatefulWidget {
  const CreateQuotationScreen({super.key});

  @override
  ConsumerState<CreateQuotationScreen> createState() =>
      _CreateQuotationScreenState();
}

class _CreateQuotationScreenState
    extends ConsumerState<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerModel? _selectedCustomer;
  List<InvoiceLineItem> _lineItems = [];
  DateTime _quotationDate = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 15));
  String _paymentTerms = 'Net 15 Days';
  String _currency = 'INR - Indian Rupee (₹)';
  
  final _referenceController = TextEditingController();
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _attachedFilePath;
  String? _attachedFileName;

  bool _isSaving = false;

  @override
  void dispose() {
    _referenceController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subTotal =>
      _lineItems.fold(0, (s, i) => s + (i.rate * i.qty));
  double get _totalDiscount =>
      _lineItems.fold(0, (s, i) => s + i.discountAmount);
  double get _totalGst =>
      _lineItems.fold(0, (s, i) => s + i.gstAmount);
  double get _taxableAmount => _subTotal - _totalDiscount;
  double get _grandTotal => _taxableAmount + _totalGst;

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
                  currentRoute: AppRoutes.quotations,
                ),
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMedium)
              SideNavigation(
                email: authState.userEmail,
                onLogout: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                currentRoute: AppRoutes.quotations,
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: isDesktop ? _desktopLayout() : _mobileLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: AppSpacing.lg),
                _metaRow(),
                const SizedBox(height: AppSpacing.xl),
                _customerSection(),
                const SizedBox(height: AppSpacing.xl),
                _lineItemsSection(),
                const SizedBox(height: AppSpacing.xl),
                _termsAndConditionsSection(),
                const SizedBox(height: AppSpacing.xl),
                _notesSection(),
              ],
            ),
          ),
        ),
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
                _quotationSummaryCard(),
                const SizedBox(height: AppSpacing.lg),
                _rightPaneControls(),
                const SizedBox(height: AppSpacing.xl),
                _actionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: AppSpacing.lg),
          _metaRow(),
          const SizedBox(height: AppSpacing.lg),
          _customerSection(),
          const SizedBox(height: AppSpacing.xl),
          _lineItemsSection(),
          const SizedBox(height: AppSpacing.xl),
          _termsAndConditionsSection(),
          const SizedBox(height: AppSpacing.xl),
          _notesSection(),
          const SizedBox(height: AppSpacing.xl),
          _quotationSummaryCard(),
          const SizedBox(height: AppSpacing.lg),
          _rightPaneControls(),
          const SizedBox(height: AppSpacing.lg),
          _actionButtons(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

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
        const Icon(Icons.assignment_rounded,
            color: AppColors.primary, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Quotation', style: AppTextStyles.h1),
              Text('Create and send professional quotations to your customers', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow() {
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
          _metaField(
            label: 'Quotation No.',
            value: '# Auto-generated on save',
            icon: Icons.tag_rounded,
          ),
          _metaDateField(
            label: 'Quotation Date',
            date: _quotationDate,
            onPicked: (d) => setState(() => _quotationDate = d),
          ),
          _metaDateField(
            label: 'Valid Until',
            date: _validUntil,
            onPicked: (d) => setState(() => _validUntil = d),
          ),
          _metaTextField(
            label: 'Reference (Optional)',
            controller: _referenceController,
            hint: 'e.g. PO No., Project Name',
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
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
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
      width: 180,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _metaTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.surface,
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
      ],
    );
  }

  Widget _lineItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('2. Add Products / Services', Icons.add_shopping_cart_rounded),
        const SizedBox(height: AppSpacing.md),
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
        if (_lineItems.isEmpty)
          _emptyItemsHint()
        else
          _lineItemsTable(),
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
      width: double.infinity,
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
            'No products or services added yet.\nSearch and add products or services above.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _termsAndConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('3. Terms & Conditions', Icons.description_outlined),
            OutlinedButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('Attach Document'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        if (_attachedFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.file_present_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(_attachedFileName!, style: AppTextStyles.bodySmall),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _attachedFilePath = null;
                      _attachedFileName = null;
                    });
                  },
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _termsController,
          maxLines: 4,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Enter terms and conditions...',
            hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
  
  Future<void> _pickAttachment() async {
    final result = await FilePicker.pickFiles();
    if (result != null) {
      setState(() {
        _attachedFileName = result.files.single.name;
        _attachedFilePath = result.files.single.path;
      });
    }
  }

  Widget _notesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('4. Notes (Optional)', Icons.notes_rounded),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Add any notes for this quotation...',
            hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _quotationSummaryCard() {
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
          Text('Quotation Summary', style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.lg),
          _summaryRow('Sub Total', _subTotal),
          _summaryRow('Discount', _totalDiscount),
          _summaryRow('Taxable Amount', _taxableAmount),
          _summaryRow('GST', _totalGst),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Tax coming soon')),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                  Text(' Add Tax', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: AppTextStyles.h4),
              Text('₹${_grandTotal.toStringAsFixed(2)}', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text('₹${amount.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _rightPaneControls() {
    final daysLeft = _validUntil.difference(DateTime.now()).inDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Payment Terms'),
        DropdownButtonFormField<String>(
          value: _paymentTerms,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          items: ['Net 15 Days', 'Net 30 Days', 'Due on Receipt']
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppTextStyles.bodyMedium)))
              .toList(),
          onChanged: (v) => setState(() => _paymentTerms = v!),
        ),
        const SizedBox(height: AppSpacing.md),
        _fieldLabel('Currency'),
        DropdownButtonFormField<String>(
          value: _currency,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          items: ['INR - Indian Rupee (₹)', 'USD - US Dollar (\$)']
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppTextStyles.bodyMedium)))
              .toList(),
          onChanged: (v) => setState(() => _currency = v!),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFF86EFAC)),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valid Until', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '${_validUntil.day.toString().padLeft(2, '0')}/'
                    '${_validUntil.month.toString().padLeft(2, '0')}/'
                    '${_validUntil.year}',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Days Left', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text('$daysLeft Days', style: AppTextStyles.caption.copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                ],
              ),
              const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _isSaving ? null : () => _saveQuotation(showSendDialog: false),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 18, color: Colors.white),
          label: Text('Save Quotation', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: _isSaving ? null : () => _saveQuotation(showSendDialog: true),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
          child: Text('Save & Send', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: BorderSide.none,
          ),
          child: Text('Cancel', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Future<void> _saveQuotation({bool showSendDialog = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showError('Please select a customer.');
      return;
    }
    if (_lineItems.isEmpty) {
      _showError('Add at least one product or service.');
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final quotation = QuotationModel(
      id: 'qt-${DateTime.now().millisecondsSinceEpoch}',
      quotationNo: 'QT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerMobile: _selectedCustomer!.mobile,
      customerAddress: _selectedCustomer!.address,
      customerGst: _selectedCustomer!.gstNumber,
      quotationDate: _quotationDate,
      validUntil: _validUntil,
      reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
      lineItems: _lineItems,
      paymentTerms: _paymentTerms,
      currency: _currency,
      terms: _termsController.text.isNotEmpty ? _termsController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      attachedFilePath: _attachedFilePath,
    );

    ref.read(quotationNotifierProvider.notifier).addQuotation(quotation);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${quotation.quotationNo} created for ${quotation.customerName}!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (showSendDialog) {
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
        barrierDismissible: false,
        builder: (_) => SendOptionsDialog(
          title: 'Quotation',
          whatsappText: waContent,
          pdfContent: pdfContent,
          filenamePrefix: 'quotation_${quotation.quotationNo}',
          onClose: () {
            context.go(AppRoutes.quotations);
          },
        ),
      );
    } else {
      context.go(AppRoutes.quotations);
    }
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
