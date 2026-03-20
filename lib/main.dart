import 'package:flutter/material.dart';
import 'app_state_holder.dart';
import 'app_scope.dart';
import 'screens/home_screen.dart';
import 'screens/earnings_screen.dart';

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
            actions: _index == 1
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: '清空录入数据',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('清空所有录入数据？'),
                            content:
                                const Text('此操作会删除所有已录入的每日收入记录，确定要清空吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await holder.clearAllDailyIncomes();
                        }
                      },
                    ),
                  ]
                : null,
          ),
          body: IndexedStack(
            index: _index,
            children: [
              HomeScreen(holder: holder),
              EarningsScreen(holder: holder),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '首页',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: '录入',
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
        return '首页';
      case 1:
        return '录入';
      default:
        return '首页';
    }
  }
}
