import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../notifiers/vendor_notifier.dart';
import '../../notifiers/auth_notifier.dart';
import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/loading_placeholder.dart';
import '../../widgets/empty_state_placeholder.dart';
import 'widgets/vendor_form_dialog.dart';

bool _isFirstLoadVen = true;
final asyncVendorProvider = FutureProvider.autoDispose((ref) async {
  ref.onDispose(() => _isFirstLoadVen = true);
  final data = ref.watch(vendorNotifierProvider);
  if (_isFirstLoadVen) {
    await Future.delayed(const Duration(seconds: 1));
    _isFirstLoadVen = false;
  }
  return data;
});

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  void _logout(WidgetRef ref, BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  void _handleExport(BuildContext context, List<dynamic> vendors) {
    final csvContent = [
      'Vendor Code,Name,Email,Phone,Address',
      ...vendors.map((v) => '${v.code},"${v.name}","${v.email}","${v.phone}","${v.address ?? ""}"')
    ].join('\n');

    final waContent = [
      '*Naiyo24 Vendors Export*',
      'Total Vendors: ${vendors.length}',
      ...vendors.map((v) => '- ${v.code} | ${v.name} | ${v.phone}')
    ].join('\n');

    final pdfContent = [
      'Naiyo24 Business Tool - Vendors Directory',
      '==========================================',
      'Code\tName\tEmail\tPhone',
      ...vendors.map((v) => '${v.code}\t${v.name}\t${v.email}\t${v.phone}')
    ].join('\n');

    showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        title: 'Vendors',
        csvContent: csvContent,
        whatsappText: waContent,
        pdfContent: pdfContent,
        filenamePrefix: 'vendors',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final vendors = ref.watch(vendorNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isDesktop
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(ref, context),
                currentRoute: AppRoutes.vendors,
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newVendor),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add vendors', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        children: [
          if (isDesktop)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () => _logout(ref, context),
              currentRoute: AppRoutes.vendors,
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
                          const Icon(Icons.store_rounded,
                              color: AppColors.primary, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Manage Vendors', style: AppTextStyles.h1),
                                const SizedBox(height: 4),
                                Text('Manage your vendor list for purchase orders and expenses.', style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      );
                      final actionButtons = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _handleExport(context, vendors),
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
                            onPressed: () => context.push(AppRoutes.newVendor),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add New Vendor'),
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
                  const SizedBox(height: AppSpacing.xxl),
                  ref.watch(asyncVendorProvider).when(
                    loading: () => const LoadingPlaceholder(message: 'Loading vendors...'),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    data: (vendorsList) {
                      if (vendorsList.isEmpty) {
                        return EmptyStatePlaceholder(
                          icon: Icons.store_outlined,
                          title: 'No vendors added yet',
                          message: 'Add your first vendor to start creating purchase orders.',
                          actionLabel: 'Add New Vendor',
                          onAction: () => context.push(AppRoutes.newVendor),
                        );
                      }
                      
                      return Container(
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
                              DataColumn(label: Text('VENDOR NAME')),
                              DataColumn(label: Text('CONTACT PERSON')),
                              DataColumn(label: Text('EMAIL')),
                              DataColumn(label: Text('PHONE')),
                              DataColumn(label: Text('ACTIONS')),
                            ],
                            rows: vendorsList.map((vendor) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: Text(
                                            vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Text(vendor.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(vendor.contactPerson.isEmpty ? '-' : vendor.contactPerson, style: AppTextStyles.bodyMedium)),
                                  DataCell(Text(vendor.email.isEmpty ? '-' : vendor.email, style: AppTextStyles.bodyMedium)),
                                  DataCell(Text(vendor.phone.isEmpty ? '-' : vendor.phone, style: AppTextStyles.bodyMedium)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => VendorFormDialog(existingVendor: vendor),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                          onPressed: () {
                                            ref.read(vendorNotifierProvider.notifier).deleteVendor(vendor.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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
}
