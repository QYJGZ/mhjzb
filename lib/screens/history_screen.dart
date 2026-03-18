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
              else ...[
                ..._buildGroupedRecords(context, records, settings, holder),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildGroupedRecords(
  BuildContext context,
  List<SessionRecord> records,
  PriceSettings settings,
  AppStateHolder holder,
) {
  final Map<String, List<SessionRecord>> grouped = {};
  final List<SessionRecord> ungrouped = [];
  for (final r in records) {
    final gid = r.groupId;
    if (gid == null || gid.isEmpty) {
      ungrouped.add(r);
    } else {
      grouped.putIfAbsent(gid, () => []).add(r);
    }
  }

  final List<Widget> widgets = [];

  // 总计时分组：按组内最后一条记录时间倒序
  final groupedEntries = grouped.entries.toList()
    ..sort((a, b) {
      final aEnd =
          a.value.map((r) => r.endTime).reduce((x, y) => x.isAfter(y) ? x : y);
      final bEnd =
          b.value.map((r) => r.endTime).reduce((x, y) => x.isAfter(y) ? x : y);
      return bEnd.compareTo(aEnd);
    });

  for (final entry in groupedEntries) {
    final groupRecords = entry.value;
    final totalProfit =
        groupRecords.fold<int>(0, (s, r) => s + r.profit(settings));
    final totalPointCost =
        groupRecords.fold<int>(0, (s, r) => s + r.pointCost());
    final totalExtra =
        groupRecords.fold<int>(0, (s, r) => s + r.extraCost(settings));
    final start = groupRecords
        .map((r) => r.startTime)
        .reduce((x, y) => x.isBefore(y) ? x : y);
    final end = groupRecords
        .map((r) => r.endTime)
        .reduce((x, y) => x.isAfter(y) ? x : y);
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    widgets.add(
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _showGroupBreakdownSheet(
                  context: context,
                  groupRecords: groupRecords,
                  settings: settings,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '总计时 ${start.month}月${start.day}日',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.pie_chart_outline,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ],
                      ),
                      Text(
                        '${totalProfit >= 0 ? '+' : ''}${_SummaryCard.formatMoney(totalProfit)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: totalProfit >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '共 ${groupRecords.length} 场 · 总时长 ${hours}时${minutes}分 · 点卡 ${_RecordCard.formatMoney(totalPointCost)}'
                '${totalExtra > 0 ? ' · 额外消耗 ${_RecordCard.formatMoney(totalExtra)}' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ...groupRecords.map(
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

  // 未归入总计时的普通记录
  widgets.addAll(
    ungrouped.map(
      (r) => _RecordCard(
        record: r,
        settings: settings,
        holder: holder,
      ),
    ),
  );

  return widgets;
}

Future<void> _showGroupBreakdownSheet({
  required BuildContext context,
  required List<SessionRecord> groupRecords,
  required PriceSettings settings,
}) async {
  final byType = <ActivityType, int>{};
  for (final r in groupRecords) {
    byType[r.activityType] = (byType[r.activityType] ?? 0) + r.profit(settings);
  }

  // 只展示具体活动分类
  final types = [
    ActivityType.digMap,
    ActivityType.sealDemon,
    ActivityType.dungeon,
    ActivityType.bell,
    ActivityType.sundayEvent,
    ActivityType.cixin,
  ];

  final entries = types
      .map((t) => MapEntry(t, byType[t] ?? 0))
      .where((e) => e.value != 0)
      .toList()
    ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

  final total = groupRecords.fold<int>(0, (s, r) => s + r.profit(settings));
  final denom = total.abs() == 0 ? 1 : total.abs();

  Color colorFor(ActivityType t) => switch (t) {
        ActivityType.digMap => Colors.orange,
        ActivityType.sealDemon => Colors.blue,
        ActivityType.dungeon => Colors.purple,
        ActivityType.bell => Colors.teal,
        ActivityType.sundayEvent => Colors.indigo,
        ActivityType.cixin => Colors.green,
        _ => Colors.grey,
      };

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '总收益分类占比',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '总收益：${total >= 0 ? '+' : ''}${_SummaryCard.formatMoney(total)}',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '本次总计时暂无可统计的分类收益。',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _PiePainter(
                      entries: entries,
                      totalAbs: denom.toDouble(),
                      colorFor: colorFor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...entries.map((e) {
                  final pct = (e.value.abs() / denom) * 100.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: colorFor(e.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    e.key.displayName,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                              Text(
                                '${e.value >= 0 ? '+' : ''}${_SummaryCard.formatMoney(e.value)}  (${pct.toStringAsFixed(1)}%)',
                                style: Theme.of(ctx).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (e.value.abs() / denom).clamp(0.0, 1.0),
                            color: colorFor(e.key),
                            backgroundColor: Theme.of(ctx)
                                .colorScheme
                                .surfaceContainerHighest,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.entries,
    required this.totalAbs,
    required this.colorFor,
  });

  final List<MapEntry<ActivityType, int>> entries;
  final double totalAbs;
  final Color Function(ActivityType) colorFor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    var startAngle = -1.57079632679; // -pi/2
    for (final e in entries) {
      final sweep = (e.value.abs() / totalAbs) * 6.28318530718; // 2*pi
      paint.color = colorFor(e.key);
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    // 中间挖空做成圆环
    final holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.001); // 透明洞
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.entries != entries || oldDelegate.totalAbs != totalAbs;
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

  static String formatMoney(int n) => _globalFormatMoney(n);

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
              '${profit >= 0 ? '+' : ''}${formatMoney(profit)}',
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

  static String formatMoney(int n) => _globalFormatMoney(n);

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

  String _formatMoney(int n) => _globalFormatMoney(n);
}

String _globalFormatMoney(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
