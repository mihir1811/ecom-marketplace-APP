import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/seller_layout.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  ConsumerState<SellerProfileScreen> createState() =>
      _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  final _companyName = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();
  final _zip = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _gstNumber = TextEditingController();
  final _panNumber = TextEditingController();

  _PickedFile? _bannerFile;
  _PickedFile? _logoFile;
  _PickedFile? _gstFile;
  _PickedFile? _panFile;
  bool _seededFromAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromAuth());
  }

  void _seedFromAuth() {
    if (_seededFromAuth || !mounted) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _seededFromAuth = true;
    _email.text = user.email;
    _phone.text = user.phone?.trim() ?? '';
  }

  Future<void> _pickFile({
    required bool imageOnly,
    required ValueChanged<_PickedFile> onSelected,
  }) async {
    try {
      final typeGroup = XTypeGroup(
        label: imageOnly ? 'images' : 'documents',
        extensions: imageOnly
            ? const ['jpg', 'jpeg', 'png', 'webp']
            : const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final maxBytes = imageOnly ? 5 * 1024 * 1024 : 10 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageOnly
                  ? 'Image must be smaller than 5 MB'
                  : 'Document must be smaller than 10 MB',
            ),
          ),
        );
        return;
      }
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected file')),
        );
        return;
      }
      setState(
        () => onSelected(
          _PickedFile(name: file.name, bytes: bytes, size: bytes.length),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select file. Please retry.')),
      );
    }
  }

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
    required _PickedFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required String helperText,
    bool imagePreview = false,
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
        if (file != null && imagePreview) ...[
          SizedBox(
            height: previewHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.r8),
              child: Image.memory(
                file.bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: _previewBox(),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        Container(
          decoration: _previewBox(),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onPick,
                  icon: Icon(
                    imagePreview
                        ? Icons.add_photo_alternate_outlined
                        : Icons.upload_file_outlined,
                    size: 18,
                  ),
                  label: Text(
                    file?.name ?? 'Choose file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                    ),
                  ),
                ),
              ),
              if (file != null)
                IconButton(
                  tooltip: 'Remove file',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            file == null ? helperText : _fileSizeLabel(file.size),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  String _fileSizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    final user = ref.watch(authProvider.select((s) => s.user));

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
                'Profile',
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
              if (user != null) ...[
                _SellerAccountCard(user: user),
                const SizedBox(height: AppSpacing.s16),
              ],
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
                        file: _logoFile,
                        imagePreview: true,
                        helperText: 'JPG, PNG or WebP · max 5 MB',
                        onPick: () => _pickFile(
                          imageOnly: true,
                          onSelected: (file) => _logoFile = file,
                        ),
                        onRemove: () => setState(() => _logoFile = null),
                      ),
                      _filePicker(
                        label: 'Storefront banner',
                        file: _bannerFile,
                        imagePreview: true,
                        helperText: 'JPG, PNG or WebP · max 5 MB',
                        onPick: () => _pickFile(
                          imageOnly: true,
                          onSelected: (file) => _bannerFile = file,
                        ),
                        onRemove: () => setState(() => _bannerFile = null),
                        previewHeight: 72,
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
                        label: 'PAN card',
                        file: _panFile,
                        helperText: 'PDF, JPG or PNG · max 10 MB',
                        onPick: () => _pickFile(
                          imageOnly: false,
                          onSelected: (file) => _panFile = file,
                        ),
                        onRemove: () => setState(() => _panFile = null),
                      ),
                      _filePicker(
                        label: 'GST certificate',
                        file: _gstFile,
                        helperText: 'PDF, JPG or PNG · max 10 MB',
                        onPick: () => _pickFile(
                          imageOnly: false,
                          onSelected: (file) => _gstFile = file,
                        ),
                        onRemove: () => setState(() => _gstFile = null),
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

class _SellerAccountCard extends StatelessWidget {
  const _SellerAccountCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final picture = user.profilePicture.trim();
    final hasPicture = picture.isNotEmpty;
    final name = user.fullName.trim().isNotEmpty
        ? user.fullName
        : (user.username.trim().isNotEmpty ? user.username : 'Seller');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.sandSurface,
            backgroundImage:
                hasPicture ? CachedNetworkImageProvider(picture) : null,
            child: hasPicture
                ? null
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email.trim().isEmpty ? '@${user.username}' : user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  user.isVerified
                      ? 'Verified seller account'
                      : 'Seller account · pending verification',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickedFile {
  const _PickedFile({
    required this.name,
    required this.bytes,
    required this.size,
  });

  final String name;
  final Uint8List bytes;
  final int size;
}
