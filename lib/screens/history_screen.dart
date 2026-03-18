import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../app_state_holder.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.holder});

  final AppStateHolder holder;

  @override
  Widget build(BuildContext context) {
    final records = holder.records;
    final settings = holder.settings;
    final now = DateTime.now();
    final startOfWeek = now
        .subtract(Duration(days: now.weekday - 1))
        .copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    int sumProfit(Iterable<SessionRecord> list) =>
        list.fold(0, (s, r) => s + r.profit(settings));

    final weekRecords = records.where(
      (r) =>
          r.endTime.isAfter(startOfWeek) ||
          r.endTime.isAtSameMomentAs(startOfWeek),
    );
    final monthRecords = records.where(
      (r) =>
          r.endTime.isAfter(startOfMonth) ||
          r.endTime.isAtSameMomentAs(startOfMonth),
    );
    final yearRecords = records.where(
      (r) =>
          r.endTime.isAfter(startOfYear) ||
          r.endTime.isAtSameMomentAs(startOfYear),
    );

    final weekProfit = sumProfit(weekRecords);
    final monthProfit = sumProfit(monthRecords);
    final yearProfit = sumProfit(yearRecords);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '历史记录',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: '本周收益',
                      profit: weekProfit,
                      count: weekRecords.length,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: '本月收益',
                      profit: monthProfit,
                      count: monthRecords.length,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: '今年收益',
                      profit: yearProfit,
                      count: yearRecords.length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (records.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        '暂无记录，结束一次计时后会自动保存',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...records.map(
                  (r) => _RecordCard(
                    record: r,
                    settings: settings,
                    holder: holder,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.profit,
    required this.count,
  });

  final String label;
  final int profit;
  final int count;

  static String _formatMoney(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final isPositive = profit >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${profit >= 0 ? '+' : ''}${_formatMoney(profit)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            if (count > 0)
              Text(
                '$count 笔',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.settings,
    required this.holder,
  });

  final SessionRecord record;
  final PriceSettings settings;
  final AppStateHolder holder;

  @override
  Widget build(BuildContext context) {
    final profit = record.profit(settings);
    final pointCost = record.pointCost();
    final itemsVal = record.itemsValue(settings);
    final duration = record.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final activityLabel = record.activityType.displayName;
    final extraCost = record.extraCost(settings);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(record.endTime),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: profit >= 0
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${profit >= 0 ? '+' : ''}${_formatMoney(profit)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: profit >= 0
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('删除记录'),
                            content: const Text('确定删除这条历史记录？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await holder.deleteRecord(record.id);
                        }
                      },
                      tooltip: '删除',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$activityLabel · ${record.accountCount} 个号 · $hours时$minutes分 · 点卡消耗 ${_formatMoney(pointCost)}'
              '${extraCost > 0 ? ' · 额外消耗 ${_formatMoney(extraCost)}' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '物品 ${_formatMoney(itemsVal)} + 金钱 ${_formatMoney(record.cashIncome)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '今天 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatMoney(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}
