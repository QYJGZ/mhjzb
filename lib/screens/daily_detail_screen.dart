import 'package:flutter/material.dart';
import '../app_state_holder.dart';
import '../models/daily_income.dart';

class DailyDetailScreen extends StatelessWidget {
  const DailyDetailScreen({
    super.key,
    required this.title,
    required this.holder,
    required this.filter,
  });

  final String title;
  final AppStateHolder holder;
  final bool Function(DailyIncome) filter;

  String _formatYi(int coins) {
    if (coins == 0) return '0 亿';
    final v = coins / 100000000.0;
    var s = v.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$s 亿';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListenableBuilder(
        listenable: holder,
        builder: (context, _) {
          final sorted = holder.dailyIncomes
              .where(filter)
              .toList()
            ..sort((a, b) {
              final cmp = b.date.compareTo(a.date);
              if (cmp != 0) return cmp;
              return b.id.compareTo(a.id);
            });

          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final item = sorted[index];
              final dateStr =
                  '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
              final cashText =
                  item.cashIncome > 0 ? ' · 现金 ${item.cashIncome} 元' : '';
              return ListTile(
                title: Text(dateStr),
                subtitle:
                    Text('梦幻币：${_formatYi(item.coinIncome)}$cashText'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除本次录入',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('删除该条录入？'),
                        content: const Text('删除后无法恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('确定删除'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    await holder.deleteDailyIncome(item.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已删除')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

