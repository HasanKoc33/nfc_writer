import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:nfc_writer/core/constants/app_assets.dart';
import 'package:nfc_writer/data/model/nfc_data.dart';
import 'package:nfc_writer/data/services/app_ads_service.dart';
import 'package:nfc_writer/ui/widgets/indicator.dart';
import 'package:nfc_writer/ui/widgets/modern_widgets.dart';
import 'package:nfc_writer/util/context_extensions.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wifi_iot/wifi_iot.dart';
import '../../../util/parsers.dart';
import '../../widgets/record_items.dart';
import '../pro_versiyon/pro_versiyon.dart';
import 'reading_screen_mixin.dart';

/// ReadingScreen ekranı
class ReadingScreen extends StatefulWidget {
  /// ReadingScreen ekranı
  const ReadingScreen({super.key, this.onCopyToWrite});

  /// Okunan etiketin kayıtlarını yazma taslağına aktarmak için.
  final ValueChanged<List<NdefRecord>>? onCopyToWrite;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with ReadingScreenMixin, TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  Timer? _rotationTimer;
  bool _showRemoveAdsBack = false;

  /// Her build'de yeniden sorgulanırsa FutureBuilder bekleme durumuna düşüp
  /// ekran göz kırpıyordu; bir kez sorgulanır.
  late final Future<bool> _nfcAvailable = NfcManager.instance.isAvailable();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _startRotationTimer();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startRotationTimer() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        // Sadece banner döner; tüm ekranı yeniden çizmeye gerek yok.
        _showRemoveAdsBack = !_showRemoveAdsBack;
        if (_showRemoveAdsBack) {
          _flipController.forward();
        } else {
          _flipController.reverse();
        }
      }
    });
  }

  void _navigateToProVersion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProVersiyonScreen()),
    );
  }

  Widget _buildTagSummary(Ndef value) {
    final scheme = Theme.of(context).colorScheme;
    final used = value.cachedMessage?.byteLength ?? 0;
    final total = value.maxSize;
    final writable = value.isWritable;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: Icons.nfc_rounded, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'ui.scan.result_title'.tr(),
                    style: context.textTheme.titleLarge,
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    writable ? Icons.edit_rounded : Icons.lock_rounded,
                    size: 16,
                    color: writable ? Colors.green : scheme.error,
                  ),
                  label: Text(
                    writable
                        ? 'nfc.scan.writable'.tr()
                        : 'nfc.scan.not_writable'.tr(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            CapacityBar(used: used, total: total),
            const SizedBox(height: 8),
            Text(
              'ui.scan.memory_used'.tr(
                namedArgs: {'used': '$used', 'total': '$total'},
              ),
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: context.height,
          child: FutureBuilder<bool>(
            future: _nfcAvailable,
            builder: (context, ss) => ss.connectionState != ConnectionState.done
                ? const SizedBox.shrink()
                : ss.data != true
                ? StatusView(
                    icon: Icons.nfc_rounded,
                    iconColor: Theme.of(context).colorScheme.error,
                    title: 'ui.scan.unavailable_title'.tr(),
                    message: 'ui.scan.unavailable_body'.tr(),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: ValueListenableBuilder<Ndef?>(
                        valueListenable: result,
                        builder: (context, value, _) {
                          if (value == null) {
                            return SizedBox(
                              height: context.height * 0.72,
                              child: StatusView(
                                icon: Icons.nfc_rounded,
                                illustration: const ScanPulse(),
                                title: 'ui.scan.title'.tr(),
                                message:
                                    defaultTargetPlatform == TargetPlatform.iOS
                                    ? 'ui.scan.subtitle_ios'.tr()
                                    : 'ui.scan.subtitle_android'.tr(),
                                action:
                                    defaultTargetPlatform == TargetPlatform.iOS
                                    ? SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: tagRead,
                                          icon: const Icon(Icons.nfc_rounded),
                                          label: Text('ui.scan.button'.tr()),
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              _buildTagSummary(value),
                              if (widget.onCopyToWrite != null &&
                                  (value.cachedMessage?.records.isNotEmpty ??
                                      false)) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => widget.onCopyToWrite!(
                                      value.cachedMessage!.records,
                                    ),
                                    icon: const Icon(Icons.copy_all_rounded),
                                    label: Text('ui.scan.copy_to_write'.tr()),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SectionHeader('ui.scan.records'.tr()),
                              if ((value.cachedMessage?.records.length ?? 0) ==
                                  0)
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'ui.scan.empty_tag'.tr(),
                                    style: context.textTheme.bodyLarge,
                                  ),
                                ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    value.cachedMessage?.records.length ?? 0,
                                itemBuilder: (context, index) {
                                  final record =
                                      value.cachedMessage?.records[index]
                                          as NdefRecord?;
                                  if (record == null) return const SizedBox();

                                  if (record.typeNameFormat ==
                                      TypeNameFormat.wellKnown) {
                                    // URL verisi
                                    if (record.type.isEmpty ||
                                        String.fromCharCodes(record.type) ==
                                            'U') {
                                      final url = String.fromCharCodes(
                                        record.payload.sublist(1),
                                      );

                                      // Protokol tespiti
                                      if (url.startsWith('tel:')) {
                                        // Telefon numarası
                                        final phoneNumber = url.substring(4);
                                        return buildPhoneRecord(
                                          context,
                                          phoneNumber,
                                        );
                                      } else if (url.startsWith('mailto:')) {
                                        // E-posta adresi
                                        final email = url.substring(7);
                                        return buildEmailRecord(context, email);
                                      } else if (url.startsWith('geo:')) {
                                        // Konum bilgisi
                                        return buildLocationRecord(
                                          context,
                                          url,
                                        );
                                      } else if (url.startsWith('sms:')) {
                                        // SMS bilgisi
                                        return buildSmsRecord(context, url);
                                      } else {
                                        // Normal web URL'si
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.black
                                                              .withOpacity(0.3)
                                                        : Colors.black
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                    blurRadius:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? 15
                                                        : 10,
                                                    spreadRadius:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? 1
                                                        : 2,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                          horizontal: 16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withOpacity(
                                                            Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? 0.2
                                                                : 0.1,
                                                          ),
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.link,
                                                          color: Colors.blue,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'nfc.scan.url'.tr(),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors
                                                                      .blue
                                                                      .shade300
                                                                : Colors.blue,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16.0,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          url,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          alignment:
                                                              WrapAlignment
                                                                  .start,
                                                          children: [
                                                            ElevatedButton.icon(
                                                              icon: Icon(
                                                                Icons
                                                                    .open_in_browser,
                                                              ),
                                                              label: Text(
                                                                'nfc.scan.open'
                                                                    .tr(),
                                                              ),
                                                              onPressed: () =>
                                                                  launchUrlString(
                                                                    url,
                                                                  ),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.blue,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                            OutlinedButton.icon(
                                                              icon: Icon(
                                                                Icons.copy,
                                                              ),
                                                              label: Text(
                                                                'nfc.scan.copy'
                                                                    .tr(),
                                                              ),
                                                              onPressed: () =>
                                                                  Clipboard.setData(
                                                                    ClipboardData(
                                                                      text: url,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Divider(
                                              color: Theme.of(
                                                context,
                                              ).dividerColor,
                                            ),
                                          ],
                                        );
                                      }
                                    }

                                    // WiFi verisi
                                    if (String.fromCharCodes(record.type) ==
                                        'T') {
                                      String text = '';
                                      try {
                                        int languageCodeLength =
                                            record.payload[0] & 0x3f;
                                        text = String.fromCharCodes(
                                          record.payload.sublist(
                                            1 + languageCodeLength,
                                          ),
                                        );
                                      } catch (e) {
                                        text = String.fromCharCodes(
                                          record.payload,
                                        );
                                      }

                                      // Normal metin verisi
                                      return buildTextRecord(context, text);
                                    }

                                    // Diğer wellKnown formatlar
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          title: Text('nfc.scan.url'.tr()),
                                          subtitle: Text(
                                            String.fromCharCodes(
                                              record.payload.sublist(1),
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.open_in_browser,
                                                ),
                                                onPressed: () {
                                                  final url =
                                                      String.fromCharCodes(
                                                        record.payload.sublist(
                                                          1,
                                                        ),
                                                      );
                                                  launchUrlString(url);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.copy),
                                                onPressed: () {
                                                  final url =
                                                      String.fromCharCodes(
                                                        record.payload.sublist(
                                                          1,
                                                        ),
                                                      );
                                                  Clipboard.setData(
                                                    ClipboardData(text: url),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ],
                                    );
                                  }

                                  if (record.typeNameFormat ==
                                      TypeNameFormat.media) {
                                    // MIME tipi
                                    String mimeType = String.fromCharCodes(
                                      record.type,
                                    );
                                    String content = String.fromCharCodes(
                                      record.payload,
                                    );

                                    if (mimeType == 'application/vnd.wfa.wsc') {
                                      final text = String.fromCharCodes(
                                        record.payload,
                                      );
                                      // WiFi verisi kontrolü
                                      if (text.startsWith('WIFI:')) {
                                        // WiFi bilgilerini ayrıştır
                                        final wifiData = parseWifiData(text);

                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.black
                                                              .withOpacity(0.3)
                                                        : Colors.black
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                    blurRadius:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? 15
                                                        : 10,
                                                    spreadRadius:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? 1
                                                        : 2,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                          horizontal: 16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.teal
                                                          .withOpacity(
                                                            Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? 0.2
                                                                : 0.1,
                                                          ),
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.wifi,
                                                          color: Colors.teal,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'nfc.scan.wifi'.tr(),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors
                                                                      .teal
                                                                      .shade300
                                                                : Colors.teal,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16.0,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ListTile(
                                                          leading: Icon(
                                                            Icons.wifi,
                                                            color: Colors.teal,
                                                          ),
                                                          title: Text(
                                                            'nfc.scan.wifi_name'
                                                                .tr(),
                                                          ),
                                                          subtitle: Text(
                                                            wifiData['S'] ??
                                                                'Unknown',
                                                          ),
                                                          dense: true,
                                                        ),
                                                        ListTile(
                                                          leading: Icon(
                                                            Icons.security,
                                                            color: Colors.teal,
                                                          ),
                                                          title: Text(
                                                            'nfc.scan.wifi_security'
                                                                .tr(),
                                                          ),
                                                          subtitle: Text(
                                                            wifiData['T'] ??
                                                                'Unknown',
                                                          ),
                                                          dense: true,
                                                        ),
                                                        if (wifiData['P'] !=
                                                            null)
                                                          ListTile(
                                                            leading: Icon(
                                                              Icons.password,
                                                              color:
                                                                  Colors.teal,
                                                            ),
                                                            title: Text(
                                                              'nfc.scan.wifi_password'
                                                                  .tr(),
                                                            ),
                                                            subtitle: Text(
                                                              wifiData['P'] ??
                                                                  '',
                                                            ),
                                                            dense: true,
                                                          ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          alignment:
                                                              WrapAlignment
                                                                  .start,
                                                          children: [
                                                            ElevatedButton.icon(
                                                              icon: Icon(
                                                                Icons.wifi,
                                                              ),
                                                              label: Text(
                                                                'nfc.scan.connect_wifi'
                                                                    .tr(),
                                                              ),
                                                              onPressed: () {
                                                                // WiFi bağlantısı için platform-spesifik kod gerekebilir
                                                                connectToWifi(
                                                                  wifiData,
                                                                );
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.teal,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                            OutlinedButton.icon(
                                                              icon: Icon(
                                                                Icons.share,
                                                              ),
                                                              label: Text(
                                                                'nfc.scan.share_wifi'
                                                                    .tr(),
                                                              ),
                                                              onPressed: () =>
                                                                  shareWifiDetails(
                                                                    context,
                                                                    wifiData,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            OutlinedButton.icon(
                                                              icon: Icon(
                                                                Icons.copy,
                                                              ),
                                                              label: Text(
                                                                'nfc.scan.copy'
                                                                    .tr(),
                                                              ),
                                                              onPressed: () =>
                                                                  Clipboard.setData(
                                                                    ClipboardData(
                                                                      text:
                                                                          text,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Divider(
                                              color: Theme.of(
                                                context,
                                              ).dividerColor,
                                            ),
                                          ],
                                        );
                                      }
                                    }
                                    // vCard (kişi) verisi
                                    if (mimeType.contains('text/x-vcard')) {
                                      // vCard verilerini ayrıştır
                                      Map<String, String> contactData =
                                          parseVCardData(content);

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.black
                                                            .withOpacity(0.3)
                                                      : Colors.black
                                                            .withOpacity(0.05),
                                                  blurRadius:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? 15
                                                      : 10,
                                                  spreadRadius:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? 1
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange
                                                        .withOpacity(
                                                          Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? 0.2
                                                              : 0.1,
                                                        ),
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            12,
                                                          ),
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.contact_phone,
                                                        color: Colors.orange,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'nfc.scan.contact'.tr(),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors
                                                                    .orange
                                                                    .shade300
                                                              : Colors.orange,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // İsim
                                                      if (contactData['FN'] !=
                                                          null)
                                                        ListTile(
                                                          leading: Icon(
                                                            Icons.person,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                          title: Text(
                                                            'nfc.scan.contact_name'
                                                                .tr(),
                                                          ),
                                                          subtitle: Text(
                                                            contactData['FN']!,
                                                          ),
                                                          dense: true,
                                                        ),
                                                      // Telefon
                                                      if (contactData['TEL'] !=
                                                          null)
                                                        ListTile(
                                                          leading: Icon(
                                                            Icons.phone,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                          title: Text(
                                                            'nfc.scan.contact_phone'
                                                                .tr(),
                                                          ),
                                                          subtitle: Text(
                                                            contactData['TEL']!,
                                                          ),
                                                          dense: true,
                                                          trailing: IconButton(
                                                            icon: Icon(
                                                              Icons.call,
                                                            ),
                                                            onPressed: () {
                                                              final phoneNumber =
                                                                  contactData['TEL']!;
                                                              launchUrlString(
                                                                'tel:$phoneNumber',
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      // E-posta
                                                      if (contactData['EMAIL'] !=
                                                          null)
                                                        ListTile(
                                                          leading: Icon(
                                                            Icons.email,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                          title: Text(
                                                            'nfc.scan.contact_email'
                                                                .tr(),
                                                          ),
                                                          subtitle: Text(
                                                            contactData['EMAIL']!,
                                                          ),
                                                          dense: true,
                                                          trailing: IconButton(
                                                            icon: Icon(
                                                              Icons.mail,
                                                            ),
                                                            onPressed: () {
                                                              final email =
                                                                  contactData['EMAIL']!;
                                                              launchUrlString(
                                                                'mailto:$email',
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      // Adres
                                                      if (contactData['ADR'] !=
                                                          null)
                                                        ListTile(
                                                          leading: Icon(
                                                            Icons.location_on,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                          title: Text(
                                                            'nfc.scan.contact_address'
                                                                .tr(),
                                                          ),
                                                          subtitle: Text(
                                                            contactData['ADR']!,
                                                          ),
                                                          dense: true,
                                                          trailing: IconButton(
                                                            icon: Icon(
                                                              Icons.map,
                                                            ),
                                                            onPressed: () {
                                                              final address =
                                                                  contactData['ADR']!;
                                                              launchUrlString(
                                                                'https://maps.google.com/?q=$address',
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          ElevatedButton.icon(
                                                            icon: Icon(
                                                              Icons.person_add,
                                                            ),
                                                            label: Text(
                                                              'nfc.scan.add_contact'
                                                                  .tr(),
                                                            ),
                                                            onPressed: () {
                                                              // Kişi ekleme işlemi platform-spesifik kod gerektirir
                                                              // Şimdilik sadece vCard'ı kopyalayalım
                                                              Clipboard.setData(
                                                                ClipboardData(
                                                                  text: content,
                                                                ),
                                                              );
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.orange,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          OutlinedButton.icon(
                                                            icon: Icon(
                                                              Icons.copy,
                                                            ),
                                                            label: Text(
                                                              'nfc.scan.copy'
                                                                  .tr(),
                                                            ),
                                                            onPressed: () =>
                                                                Clipboard.setData(
                                                                  ClipboardData(
                                                                    text:
                                                                        content,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Divider(
                                            color: Theme.of(
                                              context,
                                            ).dividerColor,
                                          ),
                                        ],
                                      );
                                    }

                                    // Diğer MIME tipleri için genel görünüm
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.black.withOpacity(
                                                        0.3,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.05,
                                                      ),
                                                blurRadius:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? 15
                                                    : 10,
                                                spreadRadius:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? 1
                                                    : 2,
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.deepPurple
                                                      .withOpacity(
                                                        Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? 0.2
                                                            : 0.1,
                                                      ),
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          12,
                                                        ),
                                                      ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.data_object,
                                                      color: Colors.deepPurple,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        mimeType,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors
                                                                    .deepPurple
                                                                    .shade300
                                                              : Colors
                                                                    .deepPurple,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      content,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                      ),
                                                      maxLines: 10,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        OutlinedButton.icon(
                                                          icon: Icon(
                                                            Icons.copy,
                                                          ),
                                                          label: Text(
                                                            'nfc.scan.copy'
                                                                .tr(),
                                                          ),
                                                          onPressed: () =>
                                                              Clipboard.setData(
                                                                ClipboardData(
                                                                  text: content,
                                                                ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ],
                                    );
                                  }
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: Text(
                                          String.fromCharCodes(record.type),
                                        ),
                                        subtitle: Text(
                                          String.fromCharCodes(
                                            record.payload.sublist(1),
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ),
      ),
      floatingActionButton: defaultTargetPlatform == TargetPlatform.iOS
          ? ValueListenableBuilder<Ndef?>(
              valueListenable: result,
              builder: (context, value, _) => value == null
                  ? const SizedBox.shrink()
                  : FloatingActionButton.extended(
                      onPressed: tagRead,
                      label: Text('nfc.scan.repeat'.tr()),
                      icon: const Icon(Icons.nfc_rounded),
                    ),
            )
          : null,
      bottomNavigationBar: AppAdsService.instance.homebannerAd == null
          ? SizedBox()
          : StreamBuilder<bool>(
              stream: AppAdsService.instance.bannerIsLoaded,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return const SizedBox();
                }
                if (snapshot.data == false) {
                  return const SizedBox();
                }
                return SizedBox(
                  width: context.width,
                  height: 50,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final isShowingFront = _flipAnimation.value < 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_flipAnimation.value * 3.14159),
                        child: isShowingFront
                            ? AdWidget(ad: AppAdsService.instance.homebannerAd!)
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(3.14159),
                                child: GestureDetector(
                                  onTap: _navigateToProVersion,
                                  child: Container(
                                    width: context.width,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.shade600,
                                          Colors.blue.shade600,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'pro_version.feature.remove_ads.title'
                                              .tr(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
