import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/business_profile_model.dart';
import '../../../notifiers/business_profile_notifier.dart';
import '../../../theme/theme.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';

class StepOneForm extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const StepOneForm({super.key, required this.onContinue});

  @override
  ConsumerState<StepOneForm> createState() => _StepOneFormState();
}

class _StepOneFormState extends ConsumerState<StepOneForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();


  bool _showBrandName = false;
  bool _hasGst = true;
  String? _selectedTeamSize;
  String? _selectedUseCase;
  String? _selectedBusinessType;
  String _selectedCountry = 'India';
  String _selectedCurrency = 'Indian Rupee (INR, ₹)';
  String _selectedPhoneCode = '+91';

  static const List<String> _teamSizes = [
    'Just me',
    '2-10',
    '11-50',
    '51-200',
    '200+'
  ];

  static const List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    // Add a few for demo purposes
  ];

  static const List<String> _currencies = [
    'Indian Rupee (INR, ₹)',
    'US Dollar (USD, \$)',
    'Euro (EUR, €)',
    'British Pound (GBP, £)'
  ];

  static const List<Map<String, String>> _phoneCodes = [
    {'label': '🇮🇳 +91', 'value': '+91'},
    {'label': '🇺🇸 +1', 'value': '+1'},
    {'label': '🇬🇧 +44', 'value': '+44'},
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _brandNameController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      final profile = BusinessProfileModel(
        businessName: _businessNameController.text.trim(),
        brandName: _showBrandName ? _brandNameController.text.trim() : '',
        website: _websiteController.text.trim(),
        phone: '$_selectedPhoneCode ${_phoneController.text.trim()}',
        country: _selectedCountry,
        currency: _selectedCurrency,
        gstNumber: _hasGst ? _gstController.text.trim() : '',
      );
      ref.read(businessProfileNotifierProvider.notifier).saveProfile(profile);
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Business Name
          _buildLabel('1. Business Name*'),
          Text(
            'Official Name used across Accounting documents and reports.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomTextField(
            controller: _businessNameController,
            hintText: 'If you\'re a freelancer, add your personal name',
            validator: (v) => v == null || v.isEmpty ? 'Business name is required' : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          
          if (!_showBrandName)
            GestureDetector(
              onTap: () => setState(() => _showBrandName = true),
              child: Row(
                children: [
                  const Icon(Icons.add_box_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Add Brand or Display name',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: AppSpacing.md),
            CustomTextField(
              controller: _brandNameController,
              hintText: 'Brand or Display name',
            ),
          ],
          
          const SizedBox(height: AppSpacing.lg),

          // Row: Team Size and Website
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('2. Team Size*'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedTeamSize,
                      hint: const Text('Select Team Size'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (v) => v == null ? 'Required' : null,
                      items: _teamSizes.map((size) {
                        return DropdownMenuItem(value: size, child: Text(size));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedTeamSize = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('3. Website'),
                    const SizedBox(height: AppSpacing.sm),
                    CustomTextField(
                      controller: _websiteController,
                      hintText: 'Your Work Website',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Phone Number
          _buildLabel('4. Phone Number*'),
          Text(
            'Contact phone number associated with your business',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  value: _selectedPhoneCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  ),
                  items: _phoneCodes.map((c) {
                    return DropdownMenuItem(value: c['value'], child: Text(c['label']!));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedPhoneCode = v ?? '+91'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CustomTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Row: Country and Currency
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('5. Country*'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _countries.map((c) {
                        return DropdownMenuItem(value: c['name'], child: Text(c['name']!));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCountry = v ?? 'India'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('6. Currency*'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _currencies.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v ?? 'Indian Rupee (INR, ₹)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 7. Have GST Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(_hasGst ? '7. Have GST Number?*' : '7. Have GST Number?'),
                    Text(
                      'Add your GSTIN to unlock smart AI and GST workflows.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _hasGst,
                onChanged: (v) => setState(() => _hasGst = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_hasGst) ...[
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: _gstController,
              hintText: 'Enter Your GST Number',
              validator: (v) => v == null || v.isEmpty ? 'GST number is required' : null,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // 8. Use Case
          _buildLabel('8. What do you want to use Naiyo Business Tool for?'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _selectedUseCase,
            hint: const Text('Select...'),
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: [
              // ── ACCOUNTING ─────────────────────────────────────────────
              DropdownMenuItem<String>(
                enabled: false,
                child: Text('ACCOUNTING',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
              ),
              _useCaseItem('End-to-end accounting'),
              _useCaseItem('Accounting services'),
              _useCaseItem('GST Compliance'),
              _useCaseItem('E-invoices & E-way Bills'),
              _useCaseItem('Only Invoicing & Billing'),
              _useCaseItem('Automate Invoicing (APIs/Shopify)'),
              // ── INVENTORY MANAGEMENT ───────────────────────────────────
              DropdownMenuItem<String>(
                enabled: false,
                child: Text('INVENTORY MANAGEMENT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
              ),
              _useCaseItem('Manage stock'),
              _useCaseItem('Manage stock locations/warehouses'),
              _useCaseItem('Batch-wise tracking with expiry'),
              // ── SALES CRM ──────────────────────────────────────────────
              DropdownMenuItem<String>(
                enabled: false,
                child: Text('SALES CRM',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6)),
              ),
              _useCaseItem('End-to-end Sales Management'),
              _useCaseItem('Lead Generation Forms'),
              _useCaseItem('Automate Lead Capture (IndiaMART, Meta, etc.)'),
            ],
            onChanged: (v) => setState(() => _selectedUseCase = v),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 9. Business Type
          _buildLabel('9. What best describes your business?'),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _selectedBusinessType,
            hint: const Text('Select...'),
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'Manufacturer', child: Text('Manufacturer')),
              DropdownMenuItem(value: 'Trading', child: Text('Trading')),
              DropdownMenuItem(value: 'Retail', child: Text('Retail')),
              DropdownMenuItem(value: 'Online', child: Text('Online')),
              DropdownMenuItem(value: 'Professional Services', child: Text('Professional Services')),
              DropdownMenuItem(value: 'Contractor', child: Text('Contractor')),
              DropdownMenuItem(value: 'Software', child: Text('Software')),
              DropdownMenuItem(value: 'Something else', child: Text('Something else')),
            ],
            onChanged: (v) => setState(() => _selectedBusinessType = v),
          ),

          const SizedBox(height: AppSpacing.xxl),
          
          CustomButton(
            label: 'Continue \u2192',
            onPressed: _handleContinue,
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _useCaseItem(String label) {
    return DropdownMenuItem<String>(
      value: label,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
