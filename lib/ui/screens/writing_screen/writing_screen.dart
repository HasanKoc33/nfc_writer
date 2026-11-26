import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_writer/data/services/app_ads_service.dart';
import 'package:nfc_writer/util/context_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../util/parsers.dart';
import '../../../core/theme/theme_manager.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/modern_widgets.dart';
import '../../widgets/record_items.dart';
import '../pro_versiyon/pro_versiyon.dart';
import 'writing_screen_mixin.dart';

/// WritingScreen ekranı
class WritingScreen extends StatefulWidget {
  /// WritingScreen ekranı
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen>
    with WritingScreenMixin, TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<bool>(
              future: _nfcAvailable,
              builder: (context, ss) => ss.data != true && !kDebugMode
                  ? _buildNfcNotAvailable()
                  : _buildMainContent(),
            ),
            if (isWriting)
              LoadingWidget(
                message: 'nfc.write.writing_in_progress'.tr(),
                progress: null,
              ),
          ],
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<NdefMessage>(
        valueListenable: result,
        builder: (context, value, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.records.isNotEmpty) _buildActionBar(),
            _buildAdBanner(),
          ],
        ),
      ),
    );
  }

  // NFC kullanılamadığında gösterilecek içerik
  Widget _buildNfcNotAvailable() {
    return StatusView(
      icon: Icons.nfc_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'ui.scan.unavailable_title'.tr(),
      message: 'ui.scan.unavailable_body'.tr(),
    );
  }

  // Ana içerik
  Widget _buildMainContent() {
    return ValueListenableBuilder<NdefMessage>(
      valueListenable: result,
      builder: (context, value, _) {
        if (value.records.isEmpty) return _buildEmptyState();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDataSizeSection(value),
              const SizedBox(height: 20),
              _buildRecordsList(value),
            ],
          ),
        );
      },
    );
  }

  // Boş durum görünümü
  Widget _buildEmptyState() {
    return StatusView(
      icon: Icons.edit_note_rounded,
      title: 'ui.write.empty_title'.tr(),
      message: 'ui.write.empty_body'.tr(),
      action: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: showDataTypeBottomSheet,
          icon: const Icon(Icons.add_rounded),
          label: Text('nfc.write.add_record'.tr()),
        ),
      ),
    );
  }

  /// NTAG213 kullanıcı belleği; en yaygın etiket olduğu için referans alınır.
  static const int _referenceCapacity = 144;

  // Veri boyutu özeti
  Widget _buildDataSizeSection(NdefMessage value) {
    final scheme = Theme.of(context).colorScheme;
    final size = value.byteLength;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  icon: Icons.data_usage_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'ui.write.payload'.tr(
                      namedArgs: {
                        'size': '$size',
                        'count': '${value.records.length}',
                      },
                    ),
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CapacityBar(used: size, total: _referenceCapacity),
            const SizedBox(height: 8),
            Text(
              'ui.write.capacity_hint'.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Alt sabit işlem çubuğu
  Widget _buildActionBar() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: showDataTypeBottomSheet,
              icon: const Icon(Icons.add_rounded),
              label: Text('ui.write.add_button'.tr()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                onPressed: writeTag,
                icon: const Icon(Icons.nfc_rounded),
                label: Text('ui.write.write_button'.tr()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kayıt listesi
  Widget _buildRecordsList(NdefMessage value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'nfc.write.records_list'.tr(),
          trailing: TextButton(
            onPressed: clearRecords,
            child: Text('ui.write.clear'.tr()),
          ),
        ),
        // Kayıt listesi
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value.records.length,
          //  final record = value.records[index];
          //               final size = record.payload.lengthInBytes;
          itemBuilder: (context, index) {
            final record = value.records[index];
            final size = record.payload.lengthInBytes;
            if (record == null) return const SizedBox();
            if (record.typeNameFormat == TypeNameFormat.wellKnown) {
              // URL verisi
              if (record.type.isEmpty ||
                  String.fromCharCodes(record.type) == 'U') {
                final url = String.fromCharCodes(record.payload.sublist(1));

                // Protokol tespiti
                if (url.startsWith('tel:')) {
                  // Telefon numarası
                  final phoneNumber = url.substring(4);
                  return buildPhoneRecord(
                    context,
                    phoneNumber,
                    () => setState(() {
                      result.value.records.removeAt(index);
                    }),
                  );
                } else if (url.startsWith('mailto:')) {
                  // E-posta adresi
                  final email = url.substring(7);
                  return buildEmailRecord(
                    context,
                    email,
                    () => setState(() {
                      result.value.records.removeAt(index);
                    }),
                  );
                } else if (url.startsWith('geo:')) {
                  // Konum bilgisi
                  return buildLocationRecord(
                    context,
                    url,
                    () => setState(() {
                      result.value.records.removeAt(index);
                    }),
                  );
                } else if (url.startsWith('sms:')) {
                  // SMS bilgisi
                  return buildSmsRecord(
                    context,
                    url,
                    () => setState(() {
                      result.value.records.removeAt(index);
                    }),
                  );
                } else {
                  return buildUrlRecord(
                    context,
                    url,
                    () => setState(() {
                      result.value.records.removeAt(index);
                    }),
                  );
                  // Normal web URL'si
                }
              }

              // WiFi verisi
              if (String.fromCharCodes(record.type) == 'T') {
                String text = '';
                try {
                  int languageCodeLength = record.payload[0] & 0x3f;
                  text = String.fromCharCodes(
                    record.payload.sublist(1 + languageCodeLength),
                  );
                } catch (e) {
                  text = String.fromCharCodes(record.payload);
                }

                // Normal metin verisi
                return buildTextRecord(
                  context,
                  text,
                  () => setState(() {
                    result.value.records.removeAt(index);
                  }),
                );
              }

              // Diğer wellKnown formatlar
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('nfc.scan.url'.tr()),
                    subtitle: Text(
                      String.fromCharCodes(record.payload.sublist(1)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.open_in_browser),
                          onPressed: () {
                            final url = String.fromCharCodes(
                              record.payload.sublist(1),
                            );
                            launchUrlString(url);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            final url = String.fromCharCodes(
                              record.payload.sublist(1),
                            );
                            Clipboard.setData(ClipboardData(text: url));
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Theme.of(context).dividerColor),
                ],
              );
            }

            if (record.typeNameFormat == TypeNameFormat.media) {
              // MIME tipi
              String mimeType = String.fromCharCodes(record.type);
              String content = String.fromCharCodes(record.payload);

              if (mimeType == 'application/vnd.wfa.wsc') {
                final text = String.fromCharCodes(record.payload);
                // WiFi verisi kontrolü
                if (text.startsWith('WIFI:')) {
                  return buildWifiRecord(
                    context,
                    content,

                    () => setState(() {
                      result.value.records.removeAt(index);
                    }),
                  );
                }
              }
              // vCard (kişi) verisi
              if (mimeType.contains('text/x-vcard')) {
                return buildVcardRecord(
                  context,
                  content,
                  () => setState(() {
                    result.value.records.removeAt(index);
                  }),
                );
              }

              // Diğer MIME tipleri için genel görünüm
              return buildOtherRecord(
                context,
                content,
                mimeType,
                () => setState(() {
                  result.value.records.removeAt(index);
                }),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(String.fromCharCodes(record.type)),
                  subtitle: Text(
                    String.fromCharCodes(record.payload.sublist(1)),
                  ),
                ),
                Divider(color: Theme.of(context).dividerColor),
              ],
            );
          },
        ),
      ],
    );
  }

  // Reklam banner'ı
  Widget _buildAdBanner() {
    if (AppAdsService.instance.homebannerAd == null) {
      return const SizedBox();
    }
    return StreamBuilder<bool>(
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'pro_version.feature.remove_ads.title'.tr(),
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
    );
  }
}
