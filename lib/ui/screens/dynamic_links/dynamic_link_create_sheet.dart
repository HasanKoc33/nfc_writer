import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/dynamic_link_repository.dart';
import '../../../data/services/dynamic_link/dynamic_link_models.dart';
import '../../../data/services/dynamic_link/dynamic_link_service.dart';

/// API hatasını kullanıcıya gösterilecek metne çevirir.
String dynamicLinkErrorText(Object error) {
  if (error is DynamicLinkException) {
    switch (error.code) {
      case 'not_configured':
        return 'ui.dynamic.not_configured'.tr();
      case 'network':
        return 'ui.dynamic.error_network'.tr();
      case 'validation_error':
        return 'ui.dynamic.invalid_url'.tr();
    }
    return 'ui.dynamic.error_generic'.tr(namedArgs: {'message': error.message});
  }
  return 'ui.dynamic.error_generic'.tr(namedArgs: {'message': '$error'});
}

/// Boş değer geçerlidir (isteğe bağlı alanlar için). Şema yoksa https eklenir;
/// API de aynı kuralı uyguladığı için sonuç sunucudakiyle aynı olur.
String? normalizeTargetUrl(String input) {
  final value = input.trim();
  if (value.isEmpty) return '';
  if (value.contains(' ')) return null;
  final withScheme = value.contains('://') ? value : 'https://$value';
  final uri = Uri.tryParse(withScheme);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty ||
      withScheme.length > 2000) {
    return null;
  }
  return withScheme;
}

/// Hedef alanları için ortak form; oluşturma ve düzenlemede kullanılır.
class DynamicTargetFields extends StatefulWidget {
  const DynamicTargetFields({
    super.key,
    required this.target,
    required this.targetIos,
    required this.targetAndroid,
  });

  final TextEditingController target;
  final TextEditingController targetIos;
  final TextEditingController targetAndroid;

  @override
  State<DynamicTargetFields> createState() => _DynamicTargetFieldsState();
}

class _DynamicTargetFieldsState extends State<DynamicTargetFields> {
  late bool _expanded =
      widget.targetIos.text.isNotEmpty || widget.targetAndroid.text.isNotEmpty;

  String? _validate(String? value, {required bool required}) {
    final normalized = normalizeTargetUrl(value ?? '');
    if (normalized == null) return 'ui.dynamic.invalid_url'.tr();
    if (required && normalized.isEmpty) return 'ui.dynamic.invalid_url'.tr();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.target,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'ui.dynamic.target'.tr(),
            hintText: 'https://example.com',
            prefixIcon: const Icon(Icons.link_rounded),
          ),
          validator: (v) => _validate(v, required: true),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            label: Text('ui.dynamic.advanced'.tr()),
          ),
        ),
        if (_expanded) ...[
          TextFormField(
            controller: widget.targetIos,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'ui.dynamic.target_ios'.tr(),
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
            ),
            validator: (v) => _validate(v, required: false),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.targetAndroid,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'ui.dynamic.target_android'.tr(),
              prefixIcon: const Icon(Icons.android_rounded),
            ),
            validator: (v) => _validate(v, required: false),
          ),
        ],
      ],
    );
  }
}

/// Yeni dinamik link oluşturur; başarıda oluşan linki döndürerek kapanır.
class DynamicLinkCreateSheet extends StatefulWidget {
  const DynamicLinkCreateSheet({super.key});

  static Future<DynamicLink?> show(BuildContext context) {
    return showModalBottomSheet<DynamicLink>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DynamicLinkCreateSheet(),
    );
  }

  @override
  State<DynamicLinkCreateSheet> createState() => _DynamicLinkCreateSheetState();
}

class _DynamicLinkCreateSheetState extends State<DynamicLinkCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _targetIos = TextEditingController();
  final _targetAndroid = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _targetIos.dispose();
    _targetAndroid.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final link = await DynamicLinkRepository.instance.create(
        title: _title.text.trim(),
        target: normalizeTargetUrl(_target.text)!,
        targetIos: normalizeTargetUrl(_targetIos.text) ?? '',
        targetAndroid: normalizeTargetUrl(_targetAndroid.text) ?? '',
      );
      if (mounted) Navigator.pop(context, link);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = dynamicLinkErrorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ui.dynamic.create_title'.tr(),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'ui.dynamic.create_body'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _title,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: 'ui.dynamic.name'.tr(),
                    hintText: 'ui.dynamic.name_hint'.tr(),
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                DynamicTargetFields(
                  target: _target,
                  targetIos: _targetIos,
                  targetAndroid: _targetAndroid,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text('ui.dynamic.create'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
