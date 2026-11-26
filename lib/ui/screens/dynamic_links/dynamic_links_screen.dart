import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/dynamic_link_repository.dart';
import '../../../data/services/dynamic_link/dynamic_link_models.dart';
import '../../../data/services/dynamic_link/dynamic_link_service.dart';
import '../../../data/services/in_app_purchase/in_app_purchase_helper.dart';
import '../../widgets/modern_widgets.dart';
import '../pro_versiyon/pro_versiyon.dart';
import 'dynamic_link_create_sheet.dart';
import 'dynamic_link_detail_screen.dart';

/// Bu cihazda oluşturulan dinamik linklerin listesi (PRO).
class DynamicLinksScreen extends StatefulWidget {
  const DynamicLinksScreen({super.key, this.onAddToWrite});

  /// Kısa linki yazma taslağına ekleyip Yaz sekmesine geçmek için.
  final ValueChanged<DynamicLink>? onAddToWrite;

  @override
  State<DynamicLinksScreen> createState() => _DynamicLinksScreenState();
}

class _DynamicLinksScreenState extends State<DynamicLinksScreen> {
  final _repository = DynamicLinkRepository.instance;
  bool? _isPremium;
  List<DynamicLink> _links = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository.revision.addListener(_reloadCache);
    _init();
  }

  @override
  void dispose() {
    _repository.revision.removeListener(_reloadCache);
    super.dispose();
  }

  Future<void> _init() async {
    final isPremium = await InAppPurchaseHelper().getSubscription();
    final cached = await _repository.cachedLinks();
    if (!mounted) return;
    setState(() {
      _isPremium = isPremium;
      _links = cached;
    });
    if (isPremium) await _refresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reloadCache() async {
    final cached = await _repository.cachedLinks();
    if (mounted) setState(() => _links = cached);
  }

  Future<void> _refresh() async {
    if (!DynamicLinkService.isConfigured) return;
    try {
      final links = await _repository.refresh();
      if (mounted)
        setState(() {
          _links = links;
          _error = null;
        });
    } catch (e) {
      if (mounted) setState(() => _error = dynamicLinkErrorText(e));
    }
  }

  Future<void> _openPro() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProVersiyonScreen()),
    );
    _init();
  }

  Future<void> _create() async {
    final link = await DynamicLinkCreateSheet.show(context);
    if (link != null && mounted) _openDetail(link);
  }

  void _openDetail(DynamicLink link) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicLinkDetailScreen(
          link: link,
          onAddToWrite: widget.onAddToWrite,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_isPremium == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isPremium == false) {
      return StatusView(
        icon: Icons.alt_route_rounded,
        iconColor: scheme.tertiary,
        title: 'ui.dynamic.pro_title'.tr(),
        message: 'ui.dynamic.pro_body'.tr(),
        action: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openPro,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text('ui.dynamic.go_pro'.tr()),
          ),
        ),
      );
    }
    if (!DynamicLinkService.isConfigured) {
      return StatusView(
        icon: Icons.cloud_off_rounded,
        iconColor: scheme.error,
        title: 'ui.dynamic.not_configured'.tr(),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text('ui.dynamic.type_label'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _links.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : StatusView(
                            icon: Icons.alt_route_rounded,
                            title: 'ui.dynamic.empty_title'.tr(),
                            message: _error ?? 'ui.dynamic.empty_body'.tr(),
                          ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: _links.length + (_error != null ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (_error != null && index == 0) {
                    return Text(_error!, style: TextStyle(color: scheme.error));
                  }
                  final link = _links[index - (_error != null ? 1 : 0)];
                  return _LinkTile(link: link, onTap: () => _openDetail(link));
                },
              ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link, required this.onTap});

  final DynamicLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconBadge(
                icon: Icons.alt_route_rounded,
                color: link.active ? Colors.indigo : scheme.outline,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title.isNotEmpty ? link.title : link.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.shortUrl.replaceFirst(RegExp(r'^https?://'), ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '→ ${link.target}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${link.hits}', style: theme.textTheme.titleLarge),
                  Text(
                    link.active
                        ? 'ui.dynamic.total_clicks'.tr()
                        : 'ui.dynamic.inactive'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: link.active
                          ? scheme.onSurfaceVariant
                          : scheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
