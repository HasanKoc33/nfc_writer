import 'package:flutter/material.dart';import 'package:go_router/go_router.dart';import 'package:nfc_writer/ui/screens/home/home_screen.dart';class AppRouter {  static final GoRouter router = GoRouter(    debugLogDiagnostics: false,    initialLocation: AppRoute.home.path,    routes: <RouteBase>[      GoRoute(        path: AppRoute.home.path,        builder: (BuildContext context, GoRouterState state) {          debugPrint(state.name.toString());          return const HomeScreen();        },      ),    ],  );}enum AppRoute {  home('/', '/')  ;  final String route;  final String path;  const AppRoute(this.path, this.route);}