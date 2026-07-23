import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/seller_layout.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _companyName = TextEditingController(text: 'adsfdsa');
  final _address1 = TextEditingController(text: 'asd');
  final _address2 = TextEditingController(text: 'asdf');
  final _city = TextEditingController(text: 'sdf');
  final _state = TextEditingController(text: 'ds');
  final _country = TextEditingController(text: 'fsdf');
  final _zip = TextEditingController(text: 'asdfads');
  final _phone = TextEditingController(text: '');
  final _email = TextEditingController(text: '');
  final _website = TextEditingController(text: '');
  final _gstNumber = TextEditingController(text: '');
  final _panNumber = TextEditingController(text: '');

  String? _bannerName;
  String? _logoName;
  String? _gstFileName;
  String? _panFileName;

  @override
  void dispose() {
    _companyName.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _zip.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _gstNumber.dispose();
    _panNumber.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.warmWhite,
      constraints: const BoxConstraints(minHeight: 52),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        borderSide: const BorderSide(color: AppColors.warmBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        borderSide: const BorderSide(color: AppColors.warmBorder),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: 14,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
      ),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: AppTypography.body.copyWith(fontSize: 16, height: 1.35),
          decoration: _decoration(hint),
        ),
      ],
    );
  }

  Widget _grid2(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.s8),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _fullWidth(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: child,
    );
  }

  Widget _filePicker({
    required String label,
    required String? fileName,
    required VoidCallback onPick,
    Widget? preview,
    double previewHeight = 72,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        if (preview != null) ...[
          SizedBox(height: previewHeight, child: preview),
          const SizedBox(height: AppSpacing.s8),
        ],
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload_file, size: 16),
          label: Text(
            fileName ?? 'Choose file',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(40),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          ),
        ),
        if (fileName == null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'No file chosen',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  BoxDecoration _previewBox() {
    return BoxDecoration(
      color: AppColors.sandSurface,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      border: Border.all(color: AppColors.warmBorder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
              ),
              Text(
                'Seller Profile',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('Company'),
                    _fullWidth(
                      _field(
                        label: 'Company name',
                        controller: _companyName,
                        hint: 'Enter company name',
                      ),
                    ),
                    _grid2(
                      _filePicker(
                        label: 'Company logo',
                        fileName: _logoName,
                        onPick: () => setState(() => _logoName = 'logo.png'),
                        preview: Container(
                          decoration: _previewBox(),
                          child: const Center(
                            child: Icon(
                              Icons.apartment,
                              size: 32,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ),
                      _filePicker(
                        label: 'Storefront banner',
                        fileName: _bannerName,
                        onPick: () =>
                            setState(() => _bannerName = 'banner.jpg'),
                        previewHeight: 72,
                        preview: Container(
                          decoration: _previewBox(),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 32,
                              color: AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    _sectionHeader('Contact'),
                    _grid2(
                      _field(
                        label: 'Phone',
                        controller: _phone,
                        hint: 'Enter phone',
                      ),
                      _field(
                        label: 'Email',
                        controller: _email,
                        hint: 'Enter email',
                      ),
                    ),
                    _fullWidth(
                      _field(
                        label: 'Website',
                        controller: _website,
                        hint: 'https://',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    _sectionHeader('Address'),
                    _fullWidth(
                      _field(
                        label: 'Address line 1',
                        controller: _address1,
                        hint: 'Street address, P.O. box',
                      ),
                    ),
                    _fullWidth(
                      _field(
                        label: 'Address line 2',
                        controller: _address2,
                        hint: 'Apartment, suite, unit, building',
                      ),
                    ),
                    _grid2(
                      _field(
                        label: 'City',
                        controller: _city,
                        hint: 'Enter city',
                      ),
                      _field(
                        label: 'State',
                        controller: _state,
                        hint: 'Enter state / province',
                      ),
                    ),
                    _grid2(
                      _field(
                        label: 'Country',
                        controller: _country,
                        hint: 'Enter country',
                      ),
                      _field(
                        label: 'ZIP / Postal code',
                        controller: _zip,
                        hint: 'Enter ZIP',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    _sectionHeader('Tax & documents'),
                    _grid2(
                      _field(
                        label: 'PAN number',
                        controller: _panNumber,
                        hint: 'Enter PAN',
                      ),
                      _field(
                        label: 'GST number',
                        controller: _gstNumber,
                        hint: 'Enter GSTIN',
                      ),
                    ),
                    _grid2(
                      _filePicker(
                        label: 'PAN card file',
                        fileName: _panFileName,
                        onPick: () =>
                            setState(() => _panFileName = 'pan.pdf'),
                      ),
                      _filePicker(
                        label: 'GST certificate',
                        fileName: _gstFileName,
                        onPick: () =>
                            setState(() => _gstFileName = 'gst.pdf'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile saved')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                      ),
                      child: const Text('Save profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
