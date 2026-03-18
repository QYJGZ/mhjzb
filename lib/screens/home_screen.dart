import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../app_state_holder.dart';

String _formatMoney(int n) => n.toString().replaceAllMapped(
  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.holder});

  final AppStateHolder holder;

  @override
  Widget build(BuildContext context) {
    final accountCount = holder.accountCount;
    final totalRunning = holder.isTotalRunning;
    final totalStart = holder.totalStartTime;
    final currentTotalAccountCount = holder.currentTotalAccountCount;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                '梦幻西游 收益计时',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildAccountSelector(context, accountCount),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '总计时',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (totalRunning && totalStart != null) ...[
                        _TimerDisplay(
                          startTime: totalStart,
                          accountCount: accountCount,
                          accountCountGetter: () => holder.currentTotalAccountCount,
                          pointsGetter: () => holder.totalPointsConsumed(),
                        ),
                        const SizedBox(height: 12),
                        _AccountAdjustRow(
                          currentAccountCount: currentTotalAccountCount,
                          onAdd: () async {
                            final n = await _askChangeCount(
                              context,
                              title: '总计时上线几个号',
                              hint: '输入上线数量（1-10）',
                            );
                            if (n == null || n <= 0) return;
                            holder.adjustTotalAccountCount(n);
                          },
                          onRemove: () async {
                            final n = await _askChangeCount(
                              context,
                              title: '总计时下线几个号',
                              hint: '输入下线数量（1-10）',
                            );
                            if (n == null || n <= 0) return;
                            holder.adjustTotalAccountCount(-n);
                            if (holder.currentTotalAccountCount == 0) {
                              holder.endTotalSession();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => holder.endTotalSession(),
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('结束总计时'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () => holder.startTotalSession(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('开始总计时'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '从开始到结束期间，挖图/封妖/副本的收益会汇总为一条总记录。',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...[
                ActivityType.digMap,
                ActivityType.sealDemon,
                ActivityType.dungeon,
                ActivityType.bell,
                ActivityType.sundayEvent,
                ActivityType.cixin,
              ].map((t) => _SessionCard(type: t, holder: holder)),
              const SizedBox(height: 16),
              if (holder.anyRunning)
                Text(
                  '可在「收益」页按活动类型添加物品与金钱，结束后自动计算该活动收益并保存到历史',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector(BuildContext context, int accountCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('默认在线账号数', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '用于新开始计时；计时中请用下方「上线/下线」调整。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (i) {
                final n = i + 1;
                final selected = accountCount == n;
                return ChoiceChip(
                  label: Text('$n'),
                  selected: selected,
                  onSelected: (_) => holder.setAccountCount(n),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.type,
    required this.holder,
  });

  final ActivityType type;
  final AppStateHolder holder;

  @override
  Widget build(BuildContext context) {
    final isRunning = holder.isRunningFor(type);
    final startTime = holder.startTimeFor(type);
    final accountCount = holder.accountCountFor(type);
    final currentAccountCount = holder.currentAccountCountFor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  type.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '计时中',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isRunning && startTime != null) ...[
              _TimerDisplay(
                startTime: startTime,
                accountCount: accountCount,
                accountCountGetter: () => holder.currentAccountCountFor(type),
                pointsGetter: () => holder.pointsConsumedFor(type),
              ),
              const SizedBox(height: 12),
              _AccountAdjustRow(
                currentAccountCount: currentAccountCount,
                onAdd: () async {
                  final n = await _askChangeCount(context, title: '上线几个号', hint: '输入上线数量（1-10）');
                  if (n == null || n <= 0) return;
                  holder.adjustRunningAccountCount(type, n);
                },
                onRemove: () async {
                  final n = await _askChangeCount(context, title: '下线几个号', hint: '输入下线数量（1-10）');
                  if (n == null || n <= 0) return;
                  final before = holder.currentAccountCountFor(type);
                  holder.adjustRunningAccountCount(type, -n);
                  final after = holder.currentAccountCountFor(type);
                  if (before > 0 && after == 0) {
                    final record = await holder.endSession(type);
                    if (!context.mounted) return;
                    if (record != null) {
                      final profit = record.profit(holder.settings);
                      final msg = profit >= 0
                          ? '${type.displayName} 已结束并保存 · 本次收益 +${_formatMoney(profit)}'
                          : '${type.displayName} 已结束并保存 · 本次收益 ${_formatMoney(profit)}';
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final record = await holder.endSession(type);
                  if (!context.mounted) return;
                  if (record != null) {
                    final profit = record.profit(holder.settings);
                    final msg = profit >= 0
                        ? '${type.displayName} 已保存 · 本次收益 +${_formatMoney(profit)}'
                        : '${type.displayName} 已保存 · 本次收益 ${_formatMoney(profit)}';
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
                icon: const Icon(Icons.stop_rounded),
                label: const Text('结束并结算'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => holder.startSession(type),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('开始计时'),
              ),
              const SizedBox(height: 8),
              Text(
                '开始时将按当前在线账号数：$accountCount 个号',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountAdjustRow extends StatelessWidget {
  const _AccountAdjustRow({
    required this.currentAccountCount,
    required this.onAdd,
    required this.onRemove,
  });

  final int currentAccountCount;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '当前在线：$currentAccountCount 个号',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('下线'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.login_rounded),
              label: const Text('上线'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<int?> _askChangeCount(
  BuildContext context, {
  required String title,
  required String hint,
}) async {
  final controller = TextEditingController(text: '1');
  final n = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final raw = controller.text.replaceAll(RegExp(r'[^\d]'), '');
            final v = int.tryParse(raw) ?? 0;
            Navigator.pop(ctx, v);
          },
          child: const Text('确定'),
        ),
      ],
    ),
  );
  controller.dispose();
  return n;
}

class _TimerDisplay extends StatefulWidget {
  const _TimerDisplay({
    required this.startTime,
    required this.accountCount,
    this.accountCountGetter,
    this.pointsGetter,
  });

  final DateTime startTime;
  final int accountCount;
  final int Function()? accountCountGetter;
  final double Function()? pointsGetter;

  @override
  State<_TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<_TimerDisplay> {
  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startTime);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;
    final str =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final displayCount = widget.accountCountGetter?.call() ?? widget.accountCount;
    final points = widget.pointsGetter?.call() ??
        (elapsed.inSeconds / 3600.0 * kPointsPerHour * widget.accountCount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              str,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '已消耗约 ${points.toStringAsFixed(1)} 点（$displayCount 个号）',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
