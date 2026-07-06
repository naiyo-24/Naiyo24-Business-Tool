import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../notifiers/auth_notifier.dart';
import '../../notifiers/customer_notifier.dart';
import '../../models/customer_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/dashboard_app_bar.dart';
import 'widgets/customer_form_dialog.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/loading_placeholder.dart';

bool _isFirstLoadCus = true;
final asyncCustomersProvider = FutureProvider.autoDispose((ref) async {
  ref.onDispose(() => _isFirstLoadCus = true);
  final data = ref.watch(customerNotifierProvider);
  if (_isFirstLoadCus) {
    await Future.delayed(const Duration(seconds: 1));
    _isFirstLoadCus = false;
  }
  return data;
});

/// Customer / Client management screen.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key, this.showAddDialog = false});

  final bool showAddDialog;

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    if (widget.showAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCustomerDialog();
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleExport(BuildContext context, List<CustomerModel> customers) {
    final csvContent = [
      'Client Code,Name,Mobile,GST No,Credit Limit,Opening Balance,Status',
      ...customers.map((c) => '${c.code},"${c.name}","${c.mobile}","${c.gstNumber ?? ""}",${c.creditLimit},${c.openingBalance},${c.status.name}')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Clients Export*',
      'Total Clients: ${customers.length}',
      ...customers.map((c) => '- ${c.code} | ${c.name} | ${c.mobile}')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Clients Directory',
      '==========================================',
      'Code\tName\tMobile\tGST No\tCredit Limit',
      ...customers.map((c) => '${c.code}\t${c.name}\t${c.mobile}\t${c.gstNumber ?? "-"}\t₹${c.creditLimit}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Clients',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'clients',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final asyncCustomers = ref.watch(asyncCustomersProvider);
    final query = _searchCtrl.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                currentRoute: AppRoutes.clients,
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newClient),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add new client', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () =>
                  ref.read(authNotifierProvider.notifier).logout(),
              currentRoute: AppRoutes.clients,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page Header ────────────────────────────────────────────
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
                          const Icon(Icons.people_rounded,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text('Clients', style: AppTextStyles.h1),
                          ),
                        ],
                      );
                      final actionButtons = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              final currentCustomers = ref.read(customerNotifierProvider);
                              _handleExport(context, currentCustomers);
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
                          FilledButton.icon(
                            onPressed: () => context.push(AppRoutes.newClient),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.md),
                              ),
                            ),
                            icon: const Icon(Icons.add,
                                size: 18, color: Colors.white),
                            label: Text('Add New Client',
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
                  const SizedBox(height: AppSpacing.lg),

                  // ── Search ─────────────────────────────────────────────────
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          'Search by name, mobile or customer code...',
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Table ──────────────────────────────────────────────────
                  Expanded(
                    child: asyncCustomers.when(
                      loading: () => const LoadingPlaceholder(
                          message: 'Loading clients...'),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (allCustomers) {
                        final customers = query.isEmpty
                            ? allCustomers
                            : ref.read(customerNotifierProvider.notifier).search(query);

                        if (customers.isEmpty) {
                          return EmptyStatePlaceholder(
                            icon: Icons.people_outline,
                            title: 'No clients found',
                            message: query.isEmpty
                                ? 'No clients yet.\nTap "Add New Client" to add your first customer.'
                                : 'No clients matched "$query".',
                            actionLabel: 'Add New Client',
                            onAction: () => context.push(AppRoutes.newClient),
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: _CustomerDataTable(
                                customers: customers,
                                onEdit: (c) => _showCustomerDialog(existing: c),
                                onDelete: (c) => _confirmDelete(c),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                'Total Customers: ${customers.length}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDialog({CustomerModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => CustomerFormDialog(existing: existing),
    );
  }

  void _confirmDelete(CustomerModel c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Delete "${c.name}"? All associated invoice data will remain but the client will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              ref
                  .read(customerNotifierProvider.notifier)
                  .deleteCustomer(c.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Data Table ───────────────────────────────────────────────────────────────

class _CustomerDataTable extends StatelessWidget {
  const _CustomerDataTable({
    required this.customers,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CustomerModel> customers;
  final void Function(CustomerModel) onEdit;
  final void Function(CustomerModel) onDelete;

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
            headingRowColor:
                WidgetStateProperty.all(AppColors.surfaceVariant),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            columnSpacing: 24,
            headingTextStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            columns: const [
              DataColumn(label: Text('CODE')),
              DataColumn(label: Text('CUSTOMER NAME')),
              DataColumn(label: Text('MOBILE')),
              DataColumn(label: Text('GST NO.')),
              DataColumn(label: Text('CREDIT LIMIT'), numeric: true),
              DataColumn(label: Text('OPENING BAL.'), numeric: true),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: customers.map((c) {
              return DataRow(cells: [
                DataCell(Text(c.code,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600))),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    if (c.address != null)
                      Text(c.address!,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                  ],
                )),
                DataCell(Text(c.mobile,
                    style: AppTextStyles.bodyMedium)),
                DataCell(Text(c.gstNumber ?? '—',
                    style: AppTextStyles.caption)),
                DataCell(Text('₹${c.creditLimit.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600))),
                DataCell(Text('₹${c.openingBalance.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyMedium)),
                DataCell(_StatusChip(
                    active: c.status == CustomerStatus.active)),
                DataCell(Row(children: [
                  _ActionIcon(
                      icon: Icons.edit_rounded,
                      color: AppColors.primary,
                      tooltip: 'Edit',
                      onTap: () => onEdit(c)),
                  const SizedBox(width: 8),
                  _ActionIcon(
                      icon: Icons.delete_rounded,
                      color: AppColors.error,
                      tooltip: 'Delete',
                      onTap: () => onDelete(c)),
                ])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Shared mini-widgets ──────────────────────────────────────────────────────

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


