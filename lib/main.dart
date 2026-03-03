import 'package:flutter/material.dart';
import 'app_state_holder.dart';
import 'app_scope.dart';
import 'screens/home_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MhjzbApp());
}

class MhjzbApp extends StatelessWidget {
  const MhjzbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '梦幻西游 收益计算',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: const _SplashThenHome(),
    );
  }
}

class _SplashThenHome extends StatefulWidget {
  const _SplashThenHome();

  @override
  State<_SplashThenHome> createState() => _SplashThenHomeState();
}

class _SplashThenHomeState extends State<_SplashThenHome> {
  AppStateHolder? _holder;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppStateHolder.init()
        .then((h) {
          if (mounted) setState(() => _holder = h);
        })
        .catchError((e, st) {
          if (mounted) setState(() => _error = e.toString());
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('加载失败: $_error'),
          ),
        ),
      );
    }
    if (_holder == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppStateScope(holder: _holder!, child: const _MainScaffold());
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold();

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final holder = AppStateScope.of(context)!;
    return ListenableBuilder(
      listenable: holder,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_title(holder)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: IndexedStack(
            index: _index,
            children: [
              HomeScreen(holder: holder),
              EarningsScreen(holder: holder),
              SettingsScreen(holder: holder),
              HistoryScreen(holder: holder),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: '首页',
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings),
                label: '收益',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '设置',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: '历史',
              ),
            ],
          ),
        );
      },
    );
  }

  String _title(AppStateHolder holder) {
    switch (_index) {
      case 0:
        return '梦幻西游 收益计算';
      case 1:
        return '收益录入';
      case 2:
        return '价格设置';
      case 3:
        return '历史记录';
      default:
        return '梦幻西游 收益计算';
    }
  }
}
