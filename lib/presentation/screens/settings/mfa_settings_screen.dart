import 'package:achievia/core/utils/mfa_helpers.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/data/data_source/auth/mfa_repository.dart';
import 'package:achievia/presentation/provider/auth/mfa_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _MfaStage { loading, off, enrolling, on, loadError }

/// Turn two-factor authentication (authenticator app) on or off.
class MfaSettingsScreen extends ConsumerStatefulWidget {
  const MfaSettingsScreen({super.key});

  @override
  ConsumerState<MfaSettingsScreen> createState() => _MfaSettingsScreenState();
}

class _MfaSettingsScreenState extends ConsumerState<MfaSettingsScreen> {
  final _code = TextEditingController();
  _MfaStage _stage = _MfaStage.loading;
  MfaEnrollment? _enrollment;
  String? _factorId;
  String? _error;
  bool _busy = false;

  MfaRepository get _repo => ref.read(mfaRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _stage = _MfaStage.loading);
    try {
      final id = await _repo.verifiedFactorId();
      if (!mounted) return;
      setState(() {
        _factorId = id;
        _stage = id == null ? _MfaStage.off : _MfaStage.on;
      });
    } catch (_) {
      if (mounted) setState(() => _stage = _MfaStage.loadError);
    }
  }

  Future<void> _begin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final enrollment = await _repo.beginEnrollment();
      if (!mounted) return;
      _code.clear();
      setState(() {
        _enrollment = enrollment;
        _stage = _MfaStage.enrolling;
        _busy = false;
      });
    } on MfaException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mfaFailureMessage(error.failure);
      });
    }
  }

  Future<void> _confirm() async {
    final enrollment = _enrollment;
    if (enrollment == null || _busy) return;
    if (!isValidTotpCode(_code.text)) {
      setState(() => _error = 'Enter the 6-digit code from your app.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.confirmEnrollment(
        factorId: enrollment.factorId,
        code: _code.text,
      );
      if (!mounted) return;
      setState(() {
        _factorId = enrollment.factorId;
        _enrollment = null;
        _stage = _MfaStage.on;
        _busy = false;
      });
      AppToast.showSuccess(context, 'Two-factor authentication is on.');
    } on MfaException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mfaFailureMessage(error.failure);
      });
    }
  }

  Future<void> _cancelEnrollment() async {
    final enrollment = _enrollment;
    if (enrollment != null) {
      await _repo.cancelEnrollment(enrollment.factorId);
    }
    if (!mounted) return;
    setState(() {
      _enrollment = null;
      _error = null;
      _stage = _MfaStage.off;
    });
  }

  Future<void> _disable() async {
    final factorId = _factorId;
    if (factorId == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn off two-factor authentication?'),
        content: const Text(
          'Your account will be protected by your password only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('mfa-confirm-disable'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.disable(factorId);
      if (!mounted) return;
      setState(() {
        _factorId = null;
        _stage = _MfaStage.off;
        _busy = false;
      });
      AppToast.showInfo(context, 'Two-factor authentication is off.');
    } on MfaException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mfaFailureMessage(error.failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Two-factor authentication',
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [_body(context)],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    switch (_stage) {
      case _MfaStage.loading:
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: CircularProgressIndicator(key: ValueKey('mfa-loading')),
          ),
        );
      case _MfaStage.loadError:
        return Column(
          key: const ValueKey('mfa-load-error'),
          children: [
            const Text('We could not check your two-factor settings.'),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        );
      case _MfaStage.off:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Off',
              key: const ValueKey('mfa-status-off'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a second step to your login. After your password, '
              'you will enter a 6-digit code from an authenticator app such '
              'as Google Authenticator, Microsoft Authenticator or Authy.',
            ),
            const SizedBox(height: 16),
            if (_error != null) _ErrorText(_error!),
            FilledButton(
              key: const ValueKey('mfa-enable'),
              onPressed: _busy ? null : _begin,
              child: Text(_busy ? 'Please wait...' : 'Turn on'),
            ),
          ],
        );
      case _MfaStage.enrolling:
        final enrollment = _enrollment!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Scan this code', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (enrollment.qrSvg != null)
              Center(
                child: Container(
                  key: const ValueKey('mfa-qr'),
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.string(
                    enrollment.qrSvg!,
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text('Cannot scan? Enter this key in your app instead:'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    formatTotpSecret(enrollment.secret),
                    key: const ValueKey('mfa-secret'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy key',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: enrollment.secret),
                    );
                    if (context.mounted) {
                      AppToast.showInfo(context, 'Key copied.');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '2. Enter the 6-digit code',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('mfa-enroll-code'),
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 7,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                errorText: _error,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _cancelEnrollment,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('mfa-confirm'),
                    onPressed: _busy ? null : _confirm,
                    child: Text(_busy ? 'Checking...' : 'Confirm'),
                  ),
                ),
              ],
            ),
          ],
        );
      case _MfaStage.on:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'On',
                  key: const ValueKey('mfa-status-on'),
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'You will be asked for a code from your authenticator app each '
              'time you log in.',
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Keep your authenticator app. If you lose access to it you '
                  'cannot log in, and support will need to reset your '
                  'two-factor authentication.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) _ErrorText(_error!),
            OutlinedButton(
              key: const ValueKey('mfa-disable'),
              onPressed: _busy ? null : _disable,
              child: Text(_busy ? 'Please wait...' : 'Turn off'),
            ),
          ],
        );
    }
  }
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message,
        key: const ValueKey('mfa-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
