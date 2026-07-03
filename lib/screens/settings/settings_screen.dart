import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../notifiers/auth_notifier.dart';
import '../../notifiers/business_profile_notifier.dart';
import '../../models/business_profile_model.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/side_navigation.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _activeTab = 0;

  final List<String> _tabs = [
    'Profile',
    'Business Details',
    'Taxes',
  ];

  // Profile controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  // Business Detail controllers
  late final TextEditingController _companyController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;

  // Taxes controllers
  late final TextEditingController _taxIdController;
  late final TextEditingController _taxRateController;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider);
    final businessProfile = ref.read(businessProfileNotifierProvider);
    
    _nameController = TextEditingController(text: 'Demo User');
    _emailController = TextEditingController(text: authState.userEmail ?? '');
    _phoneController = TextEditingController(text: businessProfile.phone);

    _companyController = TextEditingController(text: businessProfile.businessName);
    _addressController = TextEditingController(text: businessProfile.address);
    _websiteController = TextEditingController(text: businessProfile.website);

    _taxIdController = TextEditingController(text: businessProfile.gstNumber);
    _taxRateController = TextEditingController(text: '18%');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) {
    ref.read(authNotifierProvider.notifier).logout();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DashboardAppBar(email: authState.userEmail),
      drawer: !isDesktop
          ? Drawer(
              child: SideNavigation(
                email: authState.userEmail,
                onLogout: () => _logout(context),
                currentRoute: AppRoutes.settings,
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            SideNavigation(
              email: authState.userEmail,
              onLogout: () => _logout(context),
              currentRoute: AppRoutes.settings,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const Icon(Icons.settings_rounded,
                          color: AppColors.primary, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: AppTextStyles.h1,
                          ),
                          Text(
                            'Manage your account settings, business configurations, and taxes.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side tabs
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_tabs.length, (index) {
              final isSelected = _activeTab == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: () => setState(() => _activeTab = index),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Text(
                      _tabs[index],
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
        // Right side content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: _buildActiveTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Horizontal tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = _activeTab == index;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(_tabs[index]),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _activeTab = index),
                  selectedColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: _buildActiveTabContent(),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildBusinessDetailsTab();
      case 2:
        return _buildTaxesTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Profile', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.sm),
        Text('Update your personal details and contact information.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        CustomTextField(
          controller: _nameController,
          hintText: 'Enter your full name',
          labelText: 'Full Name',
          prefixIcon: const Icon(Icons.person_outline_rounded),
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _emailController,
          hintText: 'Enter your email',
          labelText: 'Email Address',
          prefixIcon: const Icon(Icons.email_outlined),
          readOnly: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _phoneController,
          hintText: 'Enter phone number',
          labelText: 'Phone Number',
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 150,
            child: CustomButton(
              label: 'Save Changes',
              onPressed: () {
                final currentProfile = ref.read(businessProfileNotifierProvider);
                final updatedProfile = currentProfile.copyWith(
                  phone: _phoneController.text.trim(),
                );
                ref.read(businessProfileNotifierProvider.notifier).saveProfile(updatedProfile);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business Details', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.sm),
        Text('Configure your company settings for invoices and billing.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        CustomTextField(
          controller: _companyController,
          hintText: 'Enter company name',
          labelText: 'Company Name',
          prefixIcon: const Icon(Icons.business_rounded),
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _addressController,
          hintText: 'Enter company address',
          labelText: 'Address',
          prefixIcon: const Icon(Icons.location_on_outlined),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _websiteController,
          hintText: 'Enter website URL',
          labelText: 'Website',
          prefixIcon: const Icon(Icons.language_rounded),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 150,
            child: CustomButton(
              label: 'Save Details',
              onPressed: () {
                final currentProfile = ref.read(businessProfileNotifierProvider);
                final updatedProfile = currentProfile.copyWith(
                  businessName: _companyController.text.trim(),
                  address: _addressController.text.trim(),
                  website: _websiteController.text.trim(),
                );
                ref.read(businessProfileNotifierProvider.notifier).saveProfile(updatedProfile);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Business details updated successfully!')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taxes & Compliance', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.sm),
        Text('Manage your tax identifiers and standard rates for billing.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        CustomTextField(
          controller: _taxIdController,
          hintText: 'Enter GSTIN / Tax ID',
          labelText: 'Tax Identification Number (GSTIN)',
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomTextField(
          controller: _taxRateController,
          hintText: 'Enter default tax rate',
          labelText: 'Default Tax Rate',
          prefixIcon: const Icon(Icons.percent_rounded),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Align(
          alignment: Alignment.centerRight,
          child: CustomButton(
            label: 'Save Tax Settings',
            onPressed: () {
                final currentProfile = ref.read(businessProfileNotifierProvider);
                final updatedProfile = currentProfile.copyWith(
                  gstNumber: _taxIdController.text.trim(),
                );
                ref.read(businessProfileNotifierProvider.notifier).saveProfile(updatedProfile);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tax settings updated successfully!')),
              );
            },
          ),
        ),
      ],
    );
  }

}
