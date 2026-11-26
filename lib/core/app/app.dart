import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nfc_writer/ui/screens/home/home_screen.dart';
import '../constants/app_theme.dart';

/// App ekranı
class App extends StatefulWidget {
  static final StreamController<PurchaseDetails> purchaseStreamController =
      StreamController<PurchaseDetails>.broadcast();

  /// App ekranı
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App>{
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app.title'.tr(),
      theme: AppTheme.ligth,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: HomeScreen(),
    );
  }
}