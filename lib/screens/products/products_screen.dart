import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../notifiers/auth_notifier.dart';
import '../../notifiers/product_notifier.dart';
import '../../notifiers/service_notifier.dart';
import '../../models/product_model.dart';
import '../../models/service_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/dashboard_app_bar.dart';
import 'widgets/product_form_dialog.dart';
import 'widgets/service_form_dialog.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/loading_placeholder.dart';

bool _isFirstLoadProd = true;
final asyncProductsProvider = FutureProvider.autoDispose((ref) async {
  ref.onDispose(() => _isFirstLoadProd = true);
  final data = ref.watch(productNotifierProvider);
  if (_isFirstLoadProd) {
    await Future.delayed(const Duration(seconds: 1));
    _isFirstLoadProd = false;
  }
  return data;
});

bool _isFirstLoadServ = true;
final asyncServicesProvider = FutureProvider.autoDispose((ref) async {
  ref.onDispose(() => _isFirstLoadServ = true);
  final data = ref.watch(serviceNotifierProvider);
  if (_isFirstLoadServ) {
    await Future.delayed(const Duration(seconds: 1));
    _isFirstLoadServ = false;
  }
  return data;
});

/// Products & Services management screen.
/// Uses a [TabBar] to switch between the Product list and Service list.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _productSearch = TextEditingController();
  final _serviceSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productSearch.dispose();
    _serviceSearch.dispose();
    super.dispose();
  }

  void _handleExportProducts(BuildContext context, List<ProductModel> products) {
    final csvContent = [
      'Product Code,Name,Unit,Sale Price,Purchase Price,Opening Stock,Status',
      ...products.map((p) => '${p.code},"${p.name}","${p.unit}",${p.sellingPrice},${p.purchasePrice},${p.stockQty},${p.status.name}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Products Export*',
      'Total Products: ${products.length}',
      ...products.map((p) => '- ${p.code} | ${p.name} | Sale: ₹${p.sellingPrice} | Stock: ${p.stockQty}')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Products Directory',
      '==========================================',
      'Code\tName\tUnit\tSale Price\tStock',
      ...products.map((p) => '${p.code}\t${p.name}\t${p.unit}\t₹${p.sellingPrice}\t${p.stockQty}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Products',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'products',
      ),
    );
  }

  void _handleExportServices(BuildContext context, List<ServiceModel> services) {
    final csvContent = [
      'Service Code,Name,Sales Price,GST Percent,Status',
      ...services.map((s) => '${s.code},"${s.name}",${s.sellingPrice},${s.gstPercent},${s.status.name}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Services Export*',
      'Total Services: ${services.length}',
      ...services.map((s) => '- ${s.code} | ${s.name} | Price: ₹${s.sellingPrice}')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Services Directory',
      '==========================================',
      'Code\tName\tPrice\tGST %',
      ...services.map((s) => '${s.code}\t${s.name}\t₹${s.sellingPrice}\t${s.gstPercent}%')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Services',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'services',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final products = ref.watch(productNotifierProvider);
    final services = ref.watch(serviceNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () {
                  ref.read(authNotifierProvider.notifier).logout();
                },
                currentRoute: AppRoutes.products,
              ),
            )
          : null,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.newProduct),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add new product', style: TextStyle(color: Colors.white)),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showServiceDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add new service', style: TextStyle(color: Colors.white)),
            ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () =>
                  ref.read(authNotifierProvider.notifier).logout(),
              currentRoute: AppRoutes.products,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page Header ──────────────────────────────────────────────
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg,
                    AppSpacing.xl, 0,
                  ),
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
                              const Icon(Icons.inventory_2_rounded,
                                  color: AppColors.primary, size: 28),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text('Inventory', style: AppTextStyles.h1),
                              ),
                            ],
                          );
                          final actionButtons = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (_tabController.index == 0) {
                                    _handleExportProducts(context, products);
                                  } else {
                                    _handleExportServices(context, services);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
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
                              _tabController.index == 0
                                  ? _AddButton(
                                      label: 'Add New Product',
                                      onTap: () => context.push(AppRoutes.newProduct),
                                    )
                                  : _AddButton(
                                      label: 'Add New Service',
                                      onTap: () => _showServiceDialog(),
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
                      const SizedBox(height: AppSpacing.lg),
                      TabBar(
                        controller: _tabController,
                        labelStyle: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                        unselectedLabelStyle: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.textSecondary),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        dividerColor: AppColors.border,
                        tabs: const [
                          Tab(text: 'Products'),
                          Tab(text: 'Services'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Tab Content ───────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ProductTab(
                        searchController: _productSearch,
                        onEdit: _showProductDialog,
                      ),
                      _ServiceTab(
                        searchController: _serviceSearch,
                        onEdit: _showServiceDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({ProductModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(existing: existing),
    );
  }

  void _showServiceDialog({ServiceModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => ServiceFormDialog(existing: existing),
    );
  }
}

// ─── Product Tab ──────────────────────────────────────────────────────────────

class _ProductTab extends ConsumerStatefulWidget {
  const _ProductTab({
    required this.searchController,
    required this.onEdit,
  });

  final TextEditingController searchController;
  final void Function({ProductModel? existing}) onEdit;

  @override
  ConsumerState<_ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends ConsumerState<_ProductTab> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(asyncProductsProvider);
    final query = widget.searchController.text;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: widget.searchController,
            decoration: const InputDecoration(
              hintText: 'Search by product name or code...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Table
          Expanded(
            child: asyncProducts.when(
              loading: () => const LoadingPlaceholder(
                  message: 'Loading products...'),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (all) {
                final products = query.isEmpty
                    ? all
                    : ref.read(productNotifierProvider.notifier).search(query);

                if (products.isEmpty) {
                  return EmptyStatePlaceholder(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    message: query.isEmpty
                        ? 'No products yet.\nTap "Add New Product" to get started.'
                        : 'No products matched "$query".',
                    actionLabel: 'Add New Product',
                    onAction: () => context.push(AppRoutes.newProduct),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: _ProductDataTable(
                        products: products,
                        onEdit: (p) => widget.onEdit(existing: p),
                        onDelete: (p) => _confirmDelete(
                          context,
                          name: p.name,
                          onConfirm: () => ref
                              .read(productNotifierProvider.notifier)
                              .deleteProduct(p.id),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Products: ${products.length}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),


        ],
      ),
    );
  }
}

// ─── Service Tab ──────────────────────────────────────────────────────────────

class _ServiceTab extends ConsumerStatefulWidget {
  const _ServiceTab({
    required this.searchController,
    required this.onEdit,
  });

  final TextEditingController searchController;
  final void Function({ServiceModel? existing}) onEdit;

  @override
  ConsumerState<_ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends ConsumerState<_ServiceTab> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final asyncServices = ref.watch(asyncServicesProvider);
    final query = widget.searchController.text;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          TextField(
            controller: widget.searchController,
            decoration: const InputDecoration(
              hintText: 'Search by service name or code...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: asyncServices.when(
              loading: () => const LoadingPlaceholder(
                  message: 'Loading services...'),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (all) {
                final services = query.isEmpty
                    ? all
                    : ref.read(serviceNotifierProvider.notifier).search(query);

                if (services.isEmpty) {
                  return EmptyStatePlaceholder(
                    icon: Icons.miscellaneous_services_outlined,
                    title: 'No services found',
                    message: query.isEmpty
                        ? 'No services yet.\nTap "Add New Service" to get started.'
                        : 'No services matched "$query".',
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: _ServiceDataTable(
                        services: services,
                        onEdit: (s) => widget.onEdit(existing: s),
                        onDelete: (s) => _confirmDelete(
                          context,
                          name: s.name,
                          onConfirm: () => ref
                              .read(serviceNotifierProvider.notifier)
                              .deleteService(s.id),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Services: ${services.length}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product Data Table ───────────────────────────────────────────────────────

class _ProductDataTable extends StatelessWidget {
  const _ProductDataTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProductModel> products;
  final void Function(ProductModel) onEdit;
  final void Function(ProductModel) onDelete;

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
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 52,
            columnSpacing: 24,
            headingTextStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            columns: const [
              DataColumn(label: Text('CODE')),
              DataColumn(label: Text('PRODUCT NAME')),
              DataColumn(label: Text('CATEGORY')),
              DataColumn(label: Text('UNIT')),
              DataColumn(label: Text('SALE PRICE'), numeric: true),
              DataColumn(label: Text('STOCK'), numeric: true),
              DataColumn(label: Text('GST %'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: products
                .map(
                  (p) => DataRow(cells: [
                    DataCell(Text(p.code,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600))),
                    DataCell(Text(p.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w500))),
                    DataCell(Text(p.category,
                        style: AppTextStyles.caption)),
                    DataCell(Text(p.unit,
                        style: AppTextStyles.caption)),
                    DataCell(Text('₹${p.sellingPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600))),
                    DataCell(_StockBadge(stock: p.stockQty)),
                    DataCell(Text('${p.gstPercent.toStringAsFixed(0)}%',
                        style: AppTextStyles.caption)),
                    DataCell(_StatusChip(
                        active: p.status == ProductStatus.active)),
                    DataCell(Row(children: [
                      _ActionIcon(
                          icon: Icons.edit_rounded,
                          color: AppColors.primary,
                          tooltip: 'Edit',
                          onTap: () => onEdit(p)),
                      const SizedBox(width: 8),
                      _ActionIcon(
                          icon: Icons.delete_rounded,
                          color: AppColors.error,
                          tooltip: 'Delete',
                          onTap: () => onDelete(p)),
                    ])),
                  ]),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Service Data Table ───────────────────────────────────────────────────────

class _ServiceDataTable extends StatelessWidget {
  const _ServiceDataTable({
    required this.services,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ServiceModel> services;
  final void Function(ServiceModel) onEdit;
  final void Function(ServiceModel) onDelete;

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
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 52,
            columnSpacing: 24,
            headingTextStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            columns: const [
              DataColumn(label: Text('CODE')),
              DataColumn(label: Text('SERVICE NAME')),
              DataColumn(label: Text('CATEGORY')),
              DataColumn(label: Text('PRICE'), numeric: true),
              DataColumn(label: Text('GST %'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: services
                .map(
                  (s) => DataRow(cells: [
                    DataCell(Text(s.code,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600))),
                    DataCell(Text(s.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w500))),
                    DataCell(Text(s.category,
                        style: AppTextStyles.caption)),
                    DataCell(Text('₹${s.sellingPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600))),
                    DataCell(Text('${s.gstPercent.toStringAsFixed(0)}%',
                        style: AppTextStyles.caption)),
                    DataCell(_StatusChip(
                        active: s.status == ServiceStatus.active)),
                    DataCell(Row(children: [
                      _ActionIcon(
                          icon: Icons.edit_rounded,
                          color: AppColors.primary,
                          tooltip: 'Edit',
                          onTap: () => onEdit(s)),
                      const SizedBox(width: 8),
                      _ActionIcon(
                          icon: Icons.delete_rounded,
                          color: AppColors.error,
                          tooltip: 'Delete',
                          onTap: () => onDelete(s)),
                    ])),
                  ]),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: Text(label,
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final isLow = stock < 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Text(
        stock.toString(),
        style: AppTextStyles.caption.copyWith(
          color: isLow ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.textHint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.caption.copyWith(
          color: active ? AppColors.success : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}


// ─── Shared delete confirmation ───────────────────────────────────────────────

void _confirmDelete(
  BuildContext context, {
  required String name,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Delete "$name"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            onConfirm();
            Navigator.pop(ctx);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
