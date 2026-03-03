import 'package:flutter/material.dart';
import 'app_state_holder.dart';

class AppStateScope extends InheritedWidget {
  const AppStateScope({
    super.key,
    required this.holder,
    required super.child,
  });

  final AppStateHolder holder;

  static AppStateHolder? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateScope>()?.holder;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) =>
      oldWidget.holder != holder;
}
