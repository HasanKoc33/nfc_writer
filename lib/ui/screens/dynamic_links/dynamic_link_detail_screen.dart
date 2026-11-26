import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/repositories/dynamic_link_repository.dart';
import '../../../data/services/dynamic_link/dynamic_link_models.dart';
import '../../widgets/modern_widgets.dart';
import 'dynamic_link_create_sheet.dart';

/// Tek bir dinamik linkin istatistikleri ve ayarları.
class DynamicLinkDetailScreen extends StatefulWidget {
  const DynamicLinkDetailScreen({
    super.key,
    required this.link,
    this.onAddToWrite,
  });

  final DynamicLink link;
  final ValueChanged<DynamicLink>? onAddToWrite;

  @override
  State<DynamicLinkDetailScreen> createState() =>
      _DynamicLinkDetailScreenState();
}

class _DynamicLinkDetailScreenState extends State<DynamicLinkDetailScreen> {
  final _repository = DynamicLinkRepository.instance;
  late DynamicLink _link = widget.link;
  LinkStats? _stats;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _repository.stats(_link.code);
      if (mounted)
        setState(() {
          _stats = stats;
          _error = null;
        });
    } catch (e) {
      if (mounted) setState(() => _error = dynamicLinkErrorText(e));
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setActive(bool value) async {
    setState(() => _busy = true);
    try {
      final updated = await _repository.update(_link.code, active: value);
      if (mounted) setState(() => _link = updated);
    } catch (e) {
      if (mounted) _showMessage(dynamicLinkErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editTargets() async {
    final updated = await showModalBottomSheet<DynamicLink>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditTargetsSheet(link: _link),
    );
    if (updated != null && mounted) {
      setState(() => _link = updated);
      _showMessage('ui.dynamic.saved'.tr());
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ui.dynamic.delete_confirm_title'.tr()),
        content: Text('ui.dynamic.delete_confirm_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('ui.dynamic.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('ui.dynamic.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.delete(_link.code);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _showMessage(dynamicLinkErrorText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totals = _stats?.totals;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _link.title.isNotEmpty ? _link.title : _link.code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'ui.dynamic.delete'.tr(),
            onPressed: _busy ? null : _delete,
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ShortLinkCard(
              link: _link,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: _link.shortUrl));
                _showMessage('ui.dynamic.copied'.tr());
              },
              onAddToWrite: widget.onAddToWrite == null
                  ? null
                  : () {
                      widget.onAddToWrite!(_link);
                      Navigator.pop(context);
                    },
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Sabit yükseklik: oran kullanınca dar ekranlarda taşıyordu.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 116,
              ),
              children: [
                _StatTile(
                  label: 'ui.dynamic.total_clicks'.tr(),
                  value: totals?.hits ?? _link.hits,
                  icon: Icons.ads_click_rounded,
                ),
                _StatTile(
                  label: 'ui.dynamic.unique'.tr(),
                  value: totals?.uniqueVisitors ?? _link.uniqueVisitors,
                  icon: Icons.person_outline_rounded,
                ),
                _StatTile(
                  label: 'ui.dynamic.today'.tr(),
                  value: totals?.today,
                  icon: Icons.today_rounded,
                ),
                _StatTile(
                  label: 'ui.dynamic.week'.tr(),
                  value: totals?.last7Days,
                  icon: Icons.date_range_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionHeader('ui.dynamic.daily'.tr()),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                child: SizedBox(
                  height: 160,
                  child: _stats == null
                      ? const Center(child: CircularProgressIndicator())
                      : _DailyChart(daily: _stats!.daily),
                ),
              ),
            ),
            if (_stats != null) ...[
              _BreakdownSection(
                title: 'ui.dynamic.devices'.tr(),
                buckets: _stats!.devices,
              ),
              _BreakdownSection(
                title: 'ui.dynamic.os'.tr(),
                buckets: _stats!.os,
              ),
              _BreakdownSection(
                title: 'ui.dynamic.browsers'.tr(),
                buckets: _stats!.browsers,
              ),
              _BreakdownSection(
                title: 'ui.dynamic.referers'.tr(),
                buckets: _stats!.referers,
              ),
            ],
            const SizedBox(height: 20),
            SectionHeader('ui.dynamic.target_section'.tr()),
            Card(
              child: Column(
                children: [
                  _TargetRow(
                    icon: Icons.public_rounded,
                    label: 'ui.dynamic.other_devices'.tr(),
                    value: _link.target,
                  ),
                  if (_link.targetIos.isNotEmpty)
                    _TargetRow(
                      icon: Icons.phone_iphone_rounded,
                      label: 'iOS',
                      value: _link.targetIos,
                    ),
                  if (_link.targetAndroid.isNotEmpty)
                    _TargetRow(
                      icon: Icons.android_rounded,
                      label: 'Android',
                      value: _link.targetAndroid,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : _editTargets,
                        icon: const Icon(Icons.edit_rounded),
                        label: Text('ui.dynamic.edit_target'.tr()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                value: _link.active,
                onChanged: _busy ? null : _setActive,
                title: Text('ui.dynamic.active'.tr()),
                subtitle: Text('ui.dynamic.active_hint'.tr()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortLinkCard extends StatelessWidget {
  const _ShortLinkCard({
    required this.link,
    required this.onCopy,
    this.onAddToWrite,
  });

  final DynamicLink link;
  final VoidCallback onCopy;
  final VoidCallback? onAddToWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.14),
            theme.colorScheme.tertiary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ui.dynamic.short_url'.tr(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            link.shortUrl,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: Text('nfc.scan.copy'.tr()),
                ),
              ),
              if (onAddToWrite != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAddToWrite,
                    icon: const Icon(Icons.nfc_rounded),
                    label: Text(
                      'home.tabs.write'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            Text(
              value == null ? '–' : NumberFormat.decimalPattern().format(value),
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.daily});

  final List<LinkStatsBucket> daily;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (daily.isEmpty) {
      return Center(child: Text('ui.dynamic.no_data'.tr()));
    }
    final maxCount = daily.map((d) => d.count).fold<int>(0, math.max);
    // Eksen etiketleri tam sayı olsun diye aralık yukarı yuvarlanır.
    final interval = math.max(1, (maxCount * 1.25 / 4).ceil()).toDouble();
    final maxY = interval * 4;
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceBetween,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${daily[group.x].key}\n${rod.toY.toInt()}',
              TextStyle(color: scheme.onInverseSurface, fontSize: 12),
            ),
            getTooltipColor: (_) => scheme.inverseSurface,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // İlk, orta ve son günün tarihini göster.
                if (index != 0 &&
                    index != daily.length - 1 &&
                    index != daily.length ~/ 2) {
                  return const SizedBox.shrink();
                }
                final date = daily[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    date.length >= 10 ? date.substring(5) : date,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < daily.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: daily[i].count.toDouble(),
                  width: math.max(3, 200 / daily.length),
                  borderRadius: BorderRadius.circular(3),
                  color: scheme.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.title, required this.buckets});

  final String title;
  final List<LinkStatsBucket> buckets;

  /// API sabit Türkçe etiketler döndürür; bilinenler çevrilir.
  static String _label(String key) {
    switch (key) {
      case 'Mobil':
        return 'ui.dynamic.label_mobile'.tr();
      case 'Masaüstü':
        return 'ui.dynamic.label_desktop'.tr();
      case 'Tablet':
        return 'ui.dynamic.label_tablet'.tr();
      case 'Diğer':
        return 'ui.dynamic.label_other'.tr();
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final total = buckets.fold<int>(0, (sum, b) => sum + b.count);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                children: [
                  for (final bucket in buckets.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _label(bucket.key),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${bucket.count}  ·  ${total == 0 ? 0 : (bucket.count * 100 / total).round()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          CapacityBar(
                            used: bucket.count,
                            total: total,
                            warnWhenFull: false,
                          ),
                        ],
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
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EditTargetsSheet extends StatefulWidget {
  const _EditTargetsSheet({required this.link});

  final DynamicLink link;

  @override
  State<_EditTargetsSheet> createState() => _EditTargetsSheetState();
}

class _EditTargetsSheetState extends State<_EditTargetsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _target = TextEditingController(text: widget.link.target);
  late final _targetIos = TextEditingController(text: widget.link.targetIos);
  late final _targetAndroid = TextEditingController(
    text: widget.link.targetAndroid,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _target.dispose();
    _targetIos.dispose();
    _targetAndroid.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await DynamicLinkRepository.instance.update(
        widget.link.code,
        target: normalizeTargetUrl(_target.text)!,
        targetIos: normalizeTargetUrl(_targetIos.text) ?? '',
        targetAndroid: normalizeTargetUrl(_targetAndroid.text) ?? '',
      );
      if (mounted) Navigator.pop(context, updated);
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
                  'ui.dynamic.edit_target'.tr(),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
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
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('ui.dynamic.save'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
