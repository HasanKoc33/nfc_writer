import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/theme_manager.dart';

/// Ortasında NFC simgesi olan, dışa doğru yayılan halkalarla tarama animasyonu.
class ScanPulse extends StatefulWidget {
  const ScanPulse({super.key, this.size = 220, this.icon = Icons.nfc_rounded});

  final double size;
  final IconData icon;

  @override
  State<ScanPulse> createState() => _ScanPulseState();
}

class _ScanPulseState extends State<ScanPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final core = widget.size * 0.42;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                _ring(color, core, (_controller.value + i / 3) % 1),
              child!,
            ],
          );
        },
        child: Container(
          width: core,
          height: core,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: core * 0.46),
        ),
      ),
    );
  }

  Widget _ring(Color color, double core, double t) {
    final eased = Curves.easeOut.transform(t);
    final diameter = core + (widget.size - core) * eased;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: (1 - t) * 0.45),
          width: 2,
        ),
        color: color.withValues(alpha: (1 - t) * 0.06),
      ),
    );
  }
}

/// Boş, hata veya bilgi durumları için ortalanmış görünüm.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;

  /// Verilirse simge yerine gösterilir (ör. [ScanPulse]).
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = iconColor ?? scheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: color),
                ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 32), action!],
          ],
        ),
      ),
    );
  }
}

/// Kart grupları üstündeki küçük başlık.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Bayt kullanımını gösteren ince ilerleme çubuğu.
class CapacityBar extends StatelessWidget {
  const CapacityBar({
    super.key,
    required this.used,
    required this.total,
    this.warnWhenFull = true,
  });

  final int used;
  final int total;

  /// Kapasite göstergelerinde dolulukla renk turuncu/kırmızıya döner;
  /// oran (pay) gösterirken kapatılır.
  final bool warnWhenFull;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = total <= 0 ? 0.0 : math.min(1.0, used / total);
    final color = !warnWhenFull
        ? scheme.primary
        : ratio > 0.9
        ? scheme.error
        : ratio > 0.7
        ? Colors.orange
        : scheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 10,
        color: color,
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Yuvarlak köşeli renkli simge kutusu.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
