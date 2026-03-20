import 'package:flutter/material.dart';
import '../app_state_holder.dart';
import '../models/daily_income.dart';
import 'daily_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.holder});

  final AppStateHolder holder;

  String _formatYi(int coins) {
    if (coins == 0) return '0 亿';
    final v = coins / 100000000.0;
    var s = v.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$s 亿';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfWeek =
        today.subtract(Duration(days: today.weekday - 1)); // 周一
    final startOfMonth = DateTime(today.year, today.month, 1);
    final startOfYear = DateTime(today.year, 1, 1);

    final weekCoins = holder.coinIncomeForRange(startOfWeek, today);
    final monthCoins = holder.coinIncomeForRange(startOfMonth, today);
    final yearCoins = holder.coinIncomeForRange(startOfYear, today);

    final brickDays = holder.recordedDays;
    final brickCash = holder.totalCashIncomeAllDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '梦幻币收入统计',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '周 / 月 / 年 梦幻币收入',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        label: '本周',
                        value: _formatYi(weekCoins),
                        onTap: () {
                          _openDetail(
                            context,
                            title: '本周每日收入',
                            filter: (d) =>
                                !d.date.isBefore(startOfWeek) &&
                                !d.date.isAfter(today),
                          );
                        },
                      ),
                      const Divider(),
                      _StatRow(
                        label: '本月',
                        value: _formatYi(monthCoins),
                        onTap: () {
                          _openDetail(
                            context,
                            title: '本月每日收入',
                            filter: (d) =>
                                !d.date.isBefore(startOfMonth) &&
                                !d.date.isAfter(today),
                          );
                        },
                      ),
                      const Divider(),
                      _StatRow(
                        label: '本年',
                        value: _formatYi(yearCoins),
                        onTap: () {
                          _openDetail(
                            context,
                            title: '本年每日收入',
                            filter: (d) =>
                                !d.date.isBefore(startOfYear) &&
                                !d.date.isAfter(today),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '提示：统计页面的梦幻币统一按「亿」为单位展示。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '搬砖（$brickDays 天）',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '收入（现金）$brickCash 元',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context, {
    required String title,
    required bool Function(DailyIncome) filter,
  }) {
    final list = holder.dailyIncomes.where(filter).toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无对应时间段的录入数据')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyDetailScreen(
          title: title,
          holder: holder,
          filter: filter,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
