import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../notifiers/auth_notifier.dart';
import '../../notifiers/vendor_notifier.dart';
import '../../notifiers/purchase_order_notifier.dart';
import '../../models/vendor_model.dart';
import '../../models/purchase_order_model.dart';
import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../vendors/widgets/vendor_form_dialog.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends ConsumerState<CreatePurchaseOrderScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _poNumberController;
  late final TextEditingController _dateController;

  VendorModel? _selectedVendor;
  final List<Map<String, dynamic>> _items = [
    {'desc': TextEditingController(), 'qty': TextEditingController(text: '1'), 'price': TextEditingController(text: '0')},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _poNumberController = TextEditingController(
        text: 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    _dateController =
        TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _poNumberController.dispose();
    _dateController.dispose();
    for (final item in _items) {
      (item['desc'] as TextEditingController).dispose();
      (item['qty'] as TextEditingController).dispose();
      (item['price'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add({
        'desc': TextEditingController(),
        'qty': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
      });
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      ((_items[index]['desc']) as TextEditingController).dispose();
      ((_items[index]['qty']) as TextEditingController).dispose();
      ((_items[index]['price']) as TextEditingController).dispose();
      setState(() => _items.removeAt(index));
    }
  }

  double _itemTotal(Map<String, dynamic> item) {
    final qty = double.tryParse((item['qty'] as TextEditingController).text) ?? 0;
    final price = double.tryParse((item['price'] as TextEditingController).text) ?? 0;
    return qty * price;
  }

  double get _totalAmount => _items.fold(0.0, (sum, item) => sum + _itemTotal(item));

  void _logout(BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  void _savePO() {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vendor first')));
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a PO title')));
      return;
    }

    final po = PurchaseOrderModel(
      id: '',
      poNumber: _poNumberController.text,
      title: _titleController.text,
      description: _descriptionController.text,
      vendorId: _selectedVendor!.id,
      vendorName: _selectedVendor!.name,
      date: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      totalAmount: _totalAmount,
      status: POStatus.unpayed,
    );

    ref.read(purchaseOrderNotifierProvider.notifier).addPurchaseOrder(po);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Purchase Order created successfully!')));
    context.pop();
  }

  Future<bool> _onWillPop() async {
    final titleEmpty = _titleController.text.isEmpty;
    final descEmpty = _descriptionController.text.isEmpty;
    final noVendor = _selectedVendor == null;
    final firstItemEmpty = _items.isEmpty || (_items.length == 1 &&
        (_items[0]['desc'] as TextEditingController).text.isEmpty &&
        (_items[0]['qty'] as TextEditingController).text == '1' &&
        (_items[0]['price'] as TextEditingController).text == '0');

    if (titleEmpty && descEmpty && noVendor && firstItemEmpty) {
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
    final vendors = ref.watch(vendorNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail, showBackButton: true),
      drawer: !isDesktop
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(context),
                currentRoute: AppRoutes.purchaseOrders,
              ),
            )
          : null,
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
                  // ── Page Header ─────────────────────────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Purchase Order', style: AppTextStyles.h1),
                          const SizedBox(height: 4),
                          Text('Fill in the details below to create a new PO.', style: AppTextStyles.bodyMedium),
                        ],
                      );
                      final actionButtons = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: _savePO,
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Submit'),
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
                            Flexible(child: titleBlock),
                            const SizedBox(width: AppSpacing.md),
                            actionButtons,
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleBlock,
                          const SizedBox(height: AppSpacing.md),
                          actionButtons,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── PO Title & Description ──────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Purchase Order Title',
                            hintStyle: AppTextStyles.h1.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          ),
                        ),
                        Divider(color: AppColors.border.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          controller: _descriptionController,
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Description — e.g., Office Supplies for Q3 2026',
                            hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Order By / Order To ─────────────────────────────────────
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Order By
                            _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Order By'),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      authState.userEmail?.isNotEmpty == true
                                          ? authState.userEmail![0].toUpperCase()
                                          : 'N',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Naiyo24 Business', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(authState.userEmail ?? 'admin@naiyo24.com', style: AppTextStyles.bodyMedium),
                                        const SizedBox(height: 2),
                                        Text('Sector 62, Noida, India', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                            const SizedBox(height: AppSpacing.lg),
                            // Order To
                            _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _sectionLabel('Order To'),
                                  TextButton.icon(
                                    onPressed: () {
                                      context.push(AppRoutes.newVendor);
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 15),
                                    label: const Text('New Vendor'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              DropdownButtonFormField<VendorModel>(
                                value: vendors.contains(_selectedVendor) ? _selectedVendor : null,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                hint: Text('Select a vendor', style: AppTextStyles.bodyMedium),
                                isExpanded: true,
                                items: vendors
                                    .map((v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v.name, style: AppTextStyles.bodyMedium),
                                        ))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedVendor = val),
                              ),
                              if (_selectedVendor != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedVendor!.name, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                                      if (_selectedVendor!.contactPerson.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(_selectedVendor!.contactPerson, style: AppTextStyles.bodyMedium),
                                      ],
                                      if (_selectedVendor!.address.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(_selectedVendor!.address, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order By
                            Expanded(
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('Order By'),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.primary,
                                          child: Text(
                                            authState.userEmail?.isNotEmpty == true
                                                ? authState.userEmail![0].toUpperCase()
                                                : 'N',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Naiyo24 Business', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                              const SizedBox(height: 2),
                                              Text(authState.userEmail ?? 'admin@naiyo24.com', style: AppTextStyles.bodyMedium),
                                              const SizedBox(height: 2),
                                              Text('Sector 62, Noida, India', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            // Order To
                            Expanded(
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _sectionLabel('Order To'),
                                        TextButton.icon(
                                          onPressed: () {
                                            context.push(AppRoutes.newVendor);
                                          },
                                          icon: const Icon(Icons.add_rounded, size: 15),
                                          label: const Text('New Vendor'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                        border: Border.all(color: AppColors.border),
                                        color: AppColors.background,
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<VendorModel>(
                                          isExpanded: true,
                                          value: _selectedVendor,
                                          hint: Text('Select Vendor', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                                          items: vendors.map((v) {
                                            return DropdownMenuItem<VendorModel>(
                                              value: v,
                                              child: Text(v.name, style: AppTextStyles.bodyMedium),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() => _selectedVendor = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── PO Number & Date ────────────────────────────────────────
                  _card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('PO Number'),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                controller: _poNumberController,
                                style: AppTextStyles.bodyMedium,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Date'),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                controller: _dateController,
                                style: AppTextStyles.bodyMedium,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Line Items ──────────────────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Items'),
                        const SizedBox(height: AppSpacing.md),

                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 5, child: Text('Description', style: AppTextStyles.labelLarge.copyWith(fontSize: 13, color: AppColors.textSecondary))),
                              Expanded(flex: 2, child: Text('Qty', style: AppTextStyles.labelLarge.copyWith(fontSize: 13, color: AppColors.textSecondary))),
                              Expanded(flex: 2, child: Text('Unit Price (₹)', style: AppTextStyles.labelLarge.copyWith(fontSize: 13, color: AppColors.textSecondary))),
                              Expanded(flex: 2, child: Text('Total (₹)', style: AppTextStyles.labelLarge.copyWith(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.right)),
                              const SizedBox(width: 44),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Item rows
                        ...List.generate(_items.length, (index) {
                          final item = _items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _itemField(item['desc'] as TextEditingController, 'e.g., MacBook Pro 14"'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  flex: 2,
                                  child: _itemField(item['qty'] as TextEditingController, '1', isNumber: true),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  flex: 2,
                                  child: _itemField(item['price'] as TextEditingController, '0.00', isNumber: true),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '₹${_itemTotal(item).toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  child: IconButton(
                                    icon: Icon(Icons.close_rounded, size: 18, color: _items.length > 1 ? AppColors.error : AppColors.border),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Line Item'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),

                        const Divider(height: AppSpacing.xl, color: AppColors.border),

                        // Totals
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Column(
                              children: [
                                _totalRow('Subtotal', '₹${_totalAmount.toStringAsFixed(2)}'),
                                const SizedBox(height: AppSpacing.sm),
                                _totalRow('Tax (0%)', '₹0.00'),
                                const Divider(color: AppColors.border),
                                _totalRow(
                                  'Total Amount',
                                  '₹${_totalAmount.toStringAsFixed(2)}',
                                  highlight: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Bottom Action Bar ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton.icon(
                                onPressed: _savePO,
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: const Text('Submit'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton(
                                onPressed: () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: _savePO,
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: const Text('Submit'),
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
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textSecondary,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _itemField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      onChanged: (_) => setState(() {}),
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: highlight
              ? AppTextStyles.h3.copyWith(color: AppColors.textPrimary)
              : AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: highlight
              ? AppTextStyles.h3.copyWith(color: AppColors.primary)
              : AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
