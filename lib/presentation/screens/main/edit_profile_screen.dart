import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/data/data_source/profile/profile_remote_datasource.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lets a student edit their own name, username, university, age and bio.
/// Email, role, course and the exam date are not edited here.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static final _usernamePattern = RegExp(r'^[A-Za-z0-9_.]{3,30}$');

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _university = TextEditingController();
  final _age = TextEditingController();
  final _bio = TextEditingController();

  ProfileEntity? _original;
  bool _filled = false;
  bool _saving = false;
  String? _usernameError;

  // The picture is saved as soon as it is chosen, separately from the Save
  // button, so these track what the avatar shows right now.
  String? _imageUrl;
  Uint8List? _imagePreview;
  bool _photoBusy = false;

  /// The picture was changed or removed on this screen.
  bool _photoChanged = false;

  /// Save is offered only once something differs from the loaded profile.
  bool get _hasChanges => _photoChanged || _changes().isNotEmpty;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _username,
      _university,
      _age,
      _bio,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fill(ProfileEntity profile) {
    if (_filled) return;
    _filled = true;
    _original = profile;
    _imageUrl = profile.profileImage;
    _firstName.text = profile.firstName ?? '';
    _middleName.text = profile.middleName ?? '';
    _lastName.text = profile.lastName ?? '';
    _username.text = profile.username ?? '';
    _university.text = profile.university ?? '';
    _age.text = profile.age?.toString() ?? '';
    _bio.text = profile.bio ?? '';
  }

  /// Only the fields the student actually changed are sent.
  Map<String, Object?> _changes() {
    final original = _original;
    final fields = <String, Object?>{};
    void text(String column, String? before, TextEditingController c) {
      final value = c.text.trim();
      if (value != (before ?? '').trim()) fields[column] = value;
    }

    text('first_name', original?.firstName, _firstName);
    text('middle_name', original?.middleName, _middleName);
    text('last_name', original?.lastName, _lastName);
    text('username', original?.username, _username);
    text('university', original?.university, _university);
    text('bio', original?.bio, _bio);

    final age = int.tryParse(_age.text.trim());
    if (age != original?.age) fields['age'] = age;
    return fields;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _usernameError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fields = _changes();
    if (fields.isEmpty) {
      context.pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(profileUseCaseProvider).updateDetails(fields);
      _refreshSharedProfileViews();
      if (!mounted) return;
      AppToast.showSuccess(context, 'Profile updated');
      context.pop();
    } catch (error) {
      if (!mounted) return;
      if (error is PostgrestException && error.code == '23505') {
        setState(() => _usernameError = 'That username is already taken.');
        _formKey.currentState?.validate();
      } else {
        AppToast.showError(
          context,
          'Unable to save your profile. ${userFacingError(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const _maxImageBytes = 2 * 1024 * 1024;

  /// Screens that show this student's name or picture to others. The Home
  /// screen stays alive in its tab, so its rankings must be refreshed here.
  void _refreshSharedProfileViews() {
    ref.invalidate(profileProvider);
    ref.invalidate(chatConversationsProvider);
    ref.invalidate(topMockboardAchieviansProvider);
    ref.invalidate(topStudyTimeAchieviansProvider);
  }

  Future<void> _changePhoto() async {
    if (_photoBusy || _saving) return;
    final hasPhoto = (_imageUrl ?? '').isNotEmpty || _imagePreview != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () => Navigator.of(context).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    setState(() => _photoBusy = true);
    try {
      if (choice == 'remove') {
        await ref.read(profileUseCaseProvider).removeProfileImage();
        if (!mounted) return;
        setState(() {
          _imageUrl = null;
          _imagePreview = null;
          _photoChanged = true;
        });
      } else {
        final picked = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        if (bytes.length > _maxImageBytes) {
          if (mounted) {
            AppToast.showError(
              context,
              'That picture is too large (max 2 MB).',
            );
          }
          return;
        }
        final url = await ref
            .read(profileUseCaseProvider)
            .uploadProfileImage(bytes);
        if (!mounted) return;
        setState(() {
          _imageUrl = url;
          _imagePreview = bytes;
          _photoChanged = true;
        });
      }
      _refreshSharedProfileViews();
      if (mounted) AppToast.showSuccess(context, 'Profile picture updated');
    } catch (error) {
      if (mounted) {
        AppToast.showError(context, profileImageErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Widget _avatar(BuildContext context) {
    final theme = Theme.of(context);
    final url = _imageUrl;
    final ImageProvider? image = _imagePreview != null
        ? MemoryImage(_imagePreview!)
        : (url != null && url.isNotEmpty ? NetworkImage(url) : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: GestureDetector(
          key: const ValueKey('edit-profile-photo'),
          onTap: _changePhoto,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: image,
                onBackgroundImageError: image == null ? null : (_, _) {},
                child: image == null
                    ? Icon(
                        Icons.person,
                        size: 52,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: _photoBusy
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving || !_filled || !_hasChanges ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('We could not load your profile.'),
              TextButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          _fill(profile);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _avatar(context),
                    _field(
                      _firstName,
                      'First name',
                      validator: (v) => _required(v, 'First name'),
                    ),
                    _field(_middleName, 'Middle name'),
                    _field(
                      _lastName,
                      'Last name',
                      validator: (v) => _required(v, 'Last name'),
                    ),
                    _field(
                      _username,
                      'Username',
                      validator: (v) {
                        if (_usernameError != null) return _usernameError;
                        final value = (v ?? '').trim();
                        if (!_usernamePattern.hasMatch(value)) {
                          return '3-30 letters, numbers, "_" or "."';
                        }
                        return null;
                      },
                    ),
                    _field(_university, 'University'),
                    _field(
                      _age,
                      'Age',
                      keyboardType: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return null;
                        final age = int.tryParse(value);
                        if (age == null || age < 10 || age > 120) {
                          return 'Enter a valid age';
                        }
                        return null;
                      },
                    ),
                    _field(_bio, 'Bio', maxLines: 3, maxLength: 200),
                    const SizedBox(height: 8),
                    Text(
                      'Your email, course and exam date are not changed here.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLines: maxLines,
        maxLength: maxLength,
        // Rebuilds so Save turns on (or off again) as the text changes.
        onChanged: (_) => setState(() {
          if (label == 'Username') _usernameError = null;
        }),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
