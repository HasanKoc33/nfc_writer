import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:nfc_writer/data/services/app_ads_service.dart';
import 'package:nfc_writer/data/services/nfc_service/nfc_service.dart';
import 'package:nfc_writer/util/bildiriler.dart';
import 'package:nfc_writer/util/ndef_record_codec.dart';

import '../../../core/services/review_service.dart';
import '../../../core/theme/theme_manager.dart';
import '../../widgets/modern_widgets.dart';
import '../dynamic_links/dynamic_link_create_sheet.dart';

import '../../../data/services/in_app_purchase/in_app_purchase_helper.dart';
import '../../../ui/widgets/premium_bottom_sheet.dart';
import 'writing_screen.dart';

/// WritingScreen mixin sınıfı
mixin WritingScreenMixin on State<WritingScreen> {
  /// Taslak ekrandan bağımsız tutulur; sekme değişince kayıtlar kaybolmaz.
  ValueNotifier<NdefMessage> get result => WriteDraft.message;
  int touchedIndex = -1;
  bool isWriting = false;

  @override
  void initState() {
    super.initState();
    AppAdsService.instance.loadHomeBannerAd();
    AppAdsService.instance.loadInterstitialAd();
  }

  Future<bool> _isPremiumUser() async {
    return await InAppPurchaseHelper().getSubscription();
  }

  /// Ücretsiz sürümde kullanılabilen veri tipleri: 1 (URL), 3 (Kişi).
  static const Set<int> _freeDataTypes = {1, 3};

  Future<bool> _checkPremiumAccess(int dataType) async {
    if (_freeDataTypes.contains(dataType)) return true;

    final isPremium = await _isPremiumUser();
    if (!isPremium) {
      final result = await PremiumBottomSheet.show(context);
      return result == true;
    }
    return true;
  }

  void addRecord(NdefRecord record) => WriteDraft.add(record);

  void clearRecords() {
    result.value = NdefMessage(records: []);
  }

  void removeRecord(int index) {
    final message = result.value;
    message.records.removeAt(index);
    result.value = message;
    result.notifyListeners();
  }

  void writeTag() {
    setState(() {
      isWriting = true;
    });
    NfcService.instance.startSession(
      alertMessageIos: 'nfc.write.ios_alert_write'.tr(),
      onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          setState(() {
            isWriting = false;
          });
          bildiri(
            context,
            'nfc.write.tag_not_writable'.tr(),
            type: BildiriType.warning,
          );
          Future.delayed(
            const Duration(seconds: 2),
            () => NfcService.instance.stopSession(
              errorMessageIos: 'nfc.write.tag_not_writable'.tr(),
            ),
          );
          return;
        }
        try {
          await ndef.write(message: result.value);
          NdefRecordCodec.saveToHistory(result.value.records, isWrite: true);
          // Başarılı yazma, değerlendirme istemek için en iyi an.
          Future.delayed(
            const Duration(seconds: 3),
            ReviewService.instance.request,
          );
          Future.delayed(
            const Duration(seconds: 2),
            () => NfcService.instance.stopSession(
              alertMessageIos: 'nfc.write.write_success'.tr(),
            ),
          );
          setState(() {
            isWriting = false;
          });
          await bildiri(
            context,
            'nfc.write.write_success'.tr(),
            type: BildiriType.success,
          );
        } catch (e) {
          Future.delayed(
            const Duration(seconds: 2),
            () => NfcService.instance.stopSession(
              errorMessageIos: 'nfc.write.write_error'.tr(),
            ),
          );
          setState(() {
            isWriting = false;
          });
          bildiri(
            context,
            'nfc.write.write_error'.tr(),
            type: BildiriType.error,
          );
        }
      },
    );
  }

  Future<void> showDataTypeBottomSheet() async {
    final isPremium = await _isPremiumUser();
    if (!mounted) return;
    final options = <(int, IconData, String, Color)>[
      (1, Icons.link_rounded, 'nfc.write.url'.tr(), Colors.blue),
      (8, Icons.alt_route_rounded, 'ui.dynamic.type_label'.tr(), Colors.indigo),
      (3, Icons.contact_page_rounded, 'nfc.write.contact'.tr(), Colors.orange),
      (6, Icons.wifi_rounded, 'nfc.write.wifi'.tr(), Colors.teal),
      (2, Icons.text_fields_rounded, 'nfc.write.text'.tr(), Colors.green),
      (4, Icons.call_rounded, 'nfc.scan.phone'.tr(), Colors.purple),
      (5, Icons.alternate_email_rounded, 'nfc.scan.email'.tr(), Colors.red),
      (7, Icons.code_rounded, 'nfc.write.custom_data'.tr(), Colors.deepPurple),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  'ui.write.choose_type'.tr(),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'ui.write.choose_type_body'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Sabit yükseklik: oran kullanınca dar ekranlarda taşıyordu.
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 100,
                  ),
                  children: [
                    for (final (type, icon, label, color) in options)
                      _buildDataTypeCard(
                        icon: icon,
                        label: label,
                        color: color,
                        showProBadge:
                            !_freeDataTypes.contains(type) &&
                            (!isPremium || kDebugMode),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          if (await _checkPremiumAccess(type)) {
                            addRecordDialog(type);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTypeCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool showProBadge,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconBadge(icon: icon, color: color, size: 36),
                  const Spacer(),
                  if (showProBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addRecordDialog(int type) {
    switch (type) {
      case 1:
        _showUrlDialog();
        break;
      case 2:
        _showTextDialog();
        break;
      case 3:
        _showContactDialog();
        break;
      case 4:
        _showPhoneDialog();
        break;
      case 7:
        _showCustomDataDialog();
        break;
      case 5:
        _showEmailDialog();
        break;
      case 6:
        _showWifiDialog();
        break;
      case 8:
        _showDynamicLinkSheet();
        break;
      default:
        _showUrlDialog();
    }
  }

  /// Dinamik link (PRO): API'de kısa link oluşturur ve kısa linki etikete
  /// yazılacak URL kaydı olarak ekler. Hedef sonradan değiştirilebilir.
  Future<void> _showDynamicLinkSheet() async {
    final link = await DynamicLinkCreateSheet.show(context);
    if (link == null || !mounted) return;
    addRecord(NfcService.instance.createUriRecord(uri: link.shortUrl));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ui.dynamic.created'.tr())));
  }

  /// Açılır listedeki önekler; en uzun önce, eşleşme bu sırayla aranır.
  static const List<String> _urlPrefixes = [
    'https://www.',
    'http://www.',
    'https://',
    'http://',
  ];

  /// Kullanıcı tarayıcıdan tam link yapıştırdığında baştaki öneki ayırır.
  /// Arka arkaya tekrar eden önekleri de temizler
  /// (ör. "https://https://www.site.com"). Önek yoksa null döner.
  static (String prefix, String rest)? _splitUrlPrefix(String input) {
    var rest = input.trim();
    String? scheme;
    var hasWww = false;
    while (true) {
      final lower = rest.toLowerCase();
      final match = _urlPrefixes.where(lower.startsWith).firstOrNull;
      if (match == null) break;
      // En dıştaki şema (http/https) korunur; tekrarlar sadece silinir.
      scheme ??= match.startsWith('https') ? 'https://' : 'http://';
      hasWww = hasWww || match.endsWith('www.');
      rest = rest.substring(match.length);
    }
    if (scheme == null) return null;
    while (rest.toLowerCase().startsWith('www.')) {
      hasWww = true;
      rest = rest.substring(4);
    }
    return ('$scheme${hasWww ? 'www.' : ''}', rest);
  }

  /// Seçili önek ile girilen metni birleştirir; metin zaten tam bir link
  /// (başka bir şema dahil) ise önek eklenmez, "www." iki kez yazılmaz.
  static String _buildUrl(String selectedPrefix, String input) {
    final text = input.trim();
    final split = _splitUrlPrefix(text);
    if (split != null) return split.$1 + split.$2;
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(text)) return text;
    if (selectedPrefix.endsWith('www.') &&
        text.toLowerCase().startsWith('www.')) {
      return selectedPrefix + text.substring(4);
    }
    return selectedPrefix + text;
  }

  void _showUrlDialog() {
    String selectedPrefix = 'https://www.';

    showDialog(
      context: context,
      builder: (context) => _DialogControllers(
        count: 1,
        builder: (context, controllers) {
          final payloadController = controllers[0];
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('nfc.write.add_url'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    // Önek yapıştırmayla değişince alanın yenilenmesi için.
                    key: ValueKey(selectedPrefix),
                    decoration: InputDecoration(
                      labelText: 'nfc.write.url_prefix'.tr(),
                    ),
                    initialValue: selectedPrefix,
                    items: const [
                      DropdownMenuItem(
                        value: 'https://www.',
                        child: Text('https://www.'),
                      ),
                      DropdownMenuItem(
                        value: 'http://www.',
                        child: Text('http://www.'),
                      ),
                      DropdownMenuItem(
                        value: 'https://',
                        child: Text('https://'),
                      ),
                      DropdownMenuItem(
                        value: 'http://',
                        child: Text('http://'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => selectedPrefix = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: payloadController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'nfc.write.url'.tr(),
                      hintText: 'example.com',
                    ),
                    onChanged: (value) {
                      final split = _splitUrlPrefix(value);
                      if (split == null) return;
                      setDialogState(() => selectedPrefix = split.$1);
                      payloadController.value = TextEditingValue(
                        text: split.$2,
                        selection: TextSelection.collapsed(
                          offset: split.$2.length,
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('nfc.scan.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (payloadController.text.trim().isNotEmpty) {
                      final fullUrl = _buildUrl(
                        selectedPrefix,
                        payloadController.text,
                      );
                      final record = NfcService.instance.createUriRecord(
                        uri: fullUrl,
                      );
                      addRecord(record);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('nfc.write.add_record'.tr()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTextDialog() {
    showDialog(
      context: context,
      builder: (context) => _DialogControllers(
        count: 1,
        builder: (context, controllers) {
          final textController = controllers[0];
          return AlertDialog(
            title: Text('nfc.write.text'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: 'nfc.write.text'.tr(),
                    hintText: 'nfc.write.enter_text_hint'.tr(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('nfc.scan.cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    final locale = context.locale.languageCode;
                    final record = NfcService.instance.createTextRecord(
                      text: textController.text,
                      languageCode: locale,
                    );
                    addRecord(record);
                    Navigator.pop(context);
                  }
                },
                child: Text('nfc.write.add_record'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  /// iOS, NDEF vCard (MIME) kayıtlarını okumadığı için kişi bilgileri
  /// vCard dosyası üreten bir web linki olarak yazılır. Link hem iOS hem
  /// Android'de açılır ve kişi doğrudan rehbere eklenebilir.
  static const String _vCardBaseHost = 'firesoftyazilim.com';
  static const String _vCardBasePath = '/vcard.php';

  String _buildVCardUrl({
    required String name,
    String phone = '',
    String email = '',
    String company = '',
    String website = '',
  }) {
    String site = website.trim();
    if (site.isNotEmpty && !site.contains('://')) {
      site = 'https://$site';
    }
    final params = <String, String>{
      'n': name.trim(),
      if (phone.trim().isNotEmpty)
        'p': phone.replaceAll(RegExp(r'[\s\-()]'), ''),
      if (email.trim().isNotEmpty) 'e': email.trim(),
      if (company.trim().isNotEmpty) 'c': company.trim(),
      if (site.isNotEmpty) 'w': site,
    };
    return Uri.https(_vCardBaseHost, _vCardBasePath, params).toString();
  }

  /// NTAG213'ün NDEF için kullanılabilir alanı (en yaygın etiket).
  static const int _smallTagNdefCapacity = 137;

  /// Kişi iki kayıt olarak yazılır:
  /// 1) vCard: Android etiketi okuyunca ilk kayda bakar, rehbere ekler.
  /// 2) vCard linki: iOS arka planda ilk URI kaydını kullanır, linki açar.
  /// Sıra önemlidir; link önce olursa Android tarayıcıyı açar.
  /// İkisi küçük etikete sığmıyorsa kullanıcıya sadece link seçeneği sunulur.
  Future<void> _showContactDialog() async {
    final contact = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _ContactDialog(),
    );
    if (contact == null || !mounted) return;

    final name = contact['name'] ?? '';
    final phone = contact['phone'] ?? '';
    final email = contact['email'] ?? '';
    final company = contact['company'] ?? '';
    final website = contact['website'] ?? '';

    final linkRecord = NfcService.instance.createUriRecord(
      uri: _buildVCardUrl(
        name: name,
        phone: phone,
        email: email,
        company: company,
        website: website,
      ),
    );
    final vCardRecord = NfcService.instance.createMimeRecord(
      mimeType: 'text/x-vcard',
      data: Uint8List.fromList(
        utf8.encode(
          NdefRecordCodec.buildVCard(
            name: name,
            phone: phone,
            email: email,
            company: company,
            website: website,
          ),
        ),
      ),
    );

    // Taslaktaki diğer kayıtlar da aynı etikete yazılacağı için toplam bakılır.
    final existing = result.value.records;
    final bothSize = NdefMessage(
      records: [...existing, vCardRecord, linkRecord],
    ).byteLength;
    final linkOnlySize = NdefMessage(
      records: [...existing, linkRecord],
    ).byteLength;

    var writeBoth = true;
    if (bothSize > _smallTagNdefCapacity) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('ui.contact.size_title'.tr()),
          content: Text(
            'ui.contact.size_body'.tr(
              namedArgs: {
                'size': '$bothSize',
                'capacity': '$_smallTagNdefCapacity',
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'ui.contact.link_only'.tr(namedArgs: {'size': '$linkOnlySize'}),
                textAlign: TextAlign.end,
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('ui.contact.both'.tr()),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      writeBoth = choice;
    }

    if (writeBoth) addRecord(vCardRecord);
    addRecord(linkRecord);
  }

  void _showPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => _DialogControllers(
        count: 1,
        builder: (context, controllers) {
          final phoneController = controllers[0];
          return AlertDialog(
            title: Text('nfc.scan.phone'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'nfc.scan.phone'.tr(),
                    hintText: '+90 555 123 4567',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('nfc.scan.cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  if (phoneController.text.isNotEmpty) {
                    final record = NfcService.instance.createUriRecord(
                      uri: 'tel:${phoneController.text}',
                    );
                    addRecord(record);
                    Navigator.pop(context);
                  }
                },
                child: Text('nfc.write.add_record'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => _DialogControllers(
        count: 3,
        builder: (context, controllers) {
          final emailController = controllers[0];
          final subjectController = controllers[1];
          final bodyController = controllers[2];
          return AlertDialog(
            title: Text('nfc.scan.email'.tr()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'nfc.scan.email'.tr(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'nfc.scan.text'.tr(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bodyController,
                    decoration: InputDecoration(
                      labelText: 'nfc.scan.message_content'.tr(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('nfc.scan.cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  if (emailController.text.isNotEmpty) {
                    String mailtoUrl = 'mailto:${emailController.text}';
                    if (subjectController.text.isNotEmpty) {
                      mailtoUrl +=
                          '?subject=${Uri.encodeComponent(subjectController.text)}';
                    }
                    if (bodyController.text.isNotEmpty) {
                      mailtoUrl += mailtoUrl.contains('?') ? '&' : '?';
                      mailtoUrl +=
                          'body=${Uri.encodeComponent(bodyController.text)}';
                    }
                    final record = NfcService.instance.createUriRecord(
                      uri: mailtoUrl,
                    );
                    addRecord(record);
                    Navigator.pop(context);
                  }
                },
                child: Text('nfc.write.add_record'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWifiDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String networkType = 'WPA';
        bool hidden = false;

        return _DialogControllers(
          count: 2,
          builder: (context, controllers) {
            final ssidController = controllers[0];
            final passwordController = controllers[1];
            return StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: Text('nfc.write.wifi'.tr()),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: ssidController,
                        decoration: InputDecoration(
                          labelText: 'nfc.scan.wifi_name'.tr(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'nfc.scan.wifi_password'.tr(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'nfc.scan.wifi_security'.tr(),
                        ),
                        value: networkType,
                        items: [
                          const DropdownMenuItem(
                            value: 'WPA',
                            child: Text('WPA/WPA2'),
                          ),
                          const DropdownMenuItem(
                            value: 'WEP',
                            child: Text('WEP'),
                          ),
                          DropdownMenuItem(
                            value: 'nopass',
                            child: Text('nfc.write.no_password'.tr()),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => networkType = value!),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text('nfc.write.hidden_ssid'.tr()),
                        value: hidden,
                        onChanged: (value) =>
                            setDialogState(() => hidden = value!),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('nfc.scan.cancel'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (ssidController.text.isNotEmpty) {
                        String wifiConfig = 'WIFI:S:${ssidController.text};';
                        if (networkType != 'nopass' &&
                            passwordController.text.isNotEmpty) {
                          wifiConfig +=
                              'T:$networkType;P:${passwordController.text};';
                        } else {
                          wifiConfig += 'T:$networkType;;';
                        }
                        wifiConfig += 'H:${hidden ? 'true' : 'false'};';

                        final record = NfcService.instance.createMimeRecord(
                          mimeType: 'application/vnd.wfa.wsc',
                          data: Uint8List.fromList(wifiConfig.codeUnits),
                        );
                        addRecord(record);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('nfc.write.add_record'.tr()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color getColorFromSize(int size) {
    if (size < 50) return Colors.green;
    if (size < 100) return Colors.orange;
    return Colors.red;
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(result.value.records.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      final size = result.value.records[i].payload.lengthInBytes;

      return PieChartSectionData(
        color: getColorFromSize(size),
        value: size.toDouble(),
        title: '$size',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  void _showCustomDataDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String dataFormat = 'text';

        return _DialogControllers(
          count: 2,
          builder: (context, controllers) {
            final mimeTypeController = controllers[0];
            final dataController = controllers[1];
            return StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: Row(
                  children: [
                    Hero(
                      tag: 'custom-card',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.code, color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('nfc.write.custom_data'.tr()),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: mimeTypeController,
                        decoration: InputDecoration(
                          labelText: 'nfc.write.mime'.tr(),
                          hintText: 'application/json, text/plain',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('nfc.write.data_format'.tr()),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'text',
                            groupValue: dataFormat,
                            onChanged: (value) =>
                                setDialogState(() => dataFormat = value!),
                          ),
                          Text('nfc.write.text'.tr()),
                          const SizedBox(width: 16),
                          Radio<String>(
                            value: 'hex',
                            groupValue: dataFormat,
                            onChanged: (value) =>
                                setDialogState(() => dataFormat = value!),
                          ),
                          const Text('Hex'),
                        ],
                      ),
                      TextField(
                        controller: dataController,
                        decoration: InputDecoration(
                          labelText: 'nfc.write.custom_data'.tr(),
                          hintText: dataFormat == 'text'
                              ? 'nfc.write.enter_text_hint'.tr()
                              : 'nfc.write.enter_hex_hint'.tr(),
                        ),
                        maxLines: 5,
                      ),
                      if (dataFormat == 'hex')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Text(
                            'nfc.write.hex_warning'.tr(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('nfc.scan.cancel'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (mimeTypeController.text.isNotEmpty &&
                          dataController.text.isNotEmpty) {
                        Uint8List data;
                        if (dataFormat == 'hex') {
                          try {
                            final String hexString = dataController.text
                                .replaceAll(' ', '');
                            data = Uint8List(hexString.length ~/ 2);
                            for (int i = 0; i < hexString.length; i += 2) {
                              data[i ~/ 2] = int.parse(
                                hexString.substring(i, i + 2),
                                radix: 16,
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('nfc.write.invalid_hex'.tr()),
                              ),
                            );
                            return;
                          }
                        } else {
                          data = Uint8List.fromList(
                            dataController.text.codeUnits,
                          );
                        }

                        final record = NfcService.instance.createMimeRecord(
                          mimeType: mimeTypeController.text,
                          data: data,
                        );
                        addRecord(record);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('nfc.write.add_record'.tr()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void ndefWriteLock() {
    NfcService.instance.startSession(
      alertMessageIos: 'nfc.write.ios_alert_write'.tr(),
      onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null) {
          NfcService.instance.stopSession(
            errorMessageIos: 'nfc.write.write_error'.tr(),
          );
          return;
        }
        try {
          await ndef.writeLock();
          NfcService.instance.stopSession();
        } catch (e) {
          NfcService.instance.stopSession(
            errorMessageIos: 'nfc.write.write_error'.tr(),
          );
        }
      },
    );
  }
}

/// Controller'ları kendi yaşam döngüsünde yöneten kişi formu.
/// Dialog içindeki TextEditingController'ları sahiplenir ve dialog
/// kapanış animasyonu bittikten sonra (widget ağaçtan çıkınca) dispose eder.
/// `showDialog(...).then(dispose)` animasyon sürerken dispose ettiği için
/// "TextEditingController was used after being disposed" hatası veriyordu.
class _DialogControllers extends StatefulWidget {
  const _DialogControllers({required this.count, required this.builder});

  final int count;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> controllers,
  )
  builder;

  @override
  State<_DialogControllers> createState() => _DialogControllersState();
}

class _DialogControllersState extends State<_DialogControllers> {
  late final List<TextEditingController> _controllers = List.generate(
    widget.count,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controllers);
}

/// Controller'lar dialog kapanış animasyonu bittikten sonra dispose edilir.
class _ContactDialog extends StatefulWidget {
  const _ContactDialog();

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('nfc.scan.add_contact'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'nfc.scan.contact_name'.tr(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'nfc.scan.contact_phone'.tr(),
                hintText: '+90 555 123 4567',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'nfc.scan.contact_email'.tr(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                labelText: 'nfc.scan.contact_company'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: 'nfc.scan.contact_website'.tr(),
                hintText: 'https://',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('nfc.scan.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            FocusScope.of(context).unfocus();
            Navigator.pop(context, {
              'name': _nameController.text,
              'phone': _phoneController.text,
              'email': _emailController.text,
              'company': _companyController.text,
              'website': _websiteController.text,
            });
          },
          child: Text('nfc.write.add_record'.tr()),
        ),
      ],
    );
  }
}
