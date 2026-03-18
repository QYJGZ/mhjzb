import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../app_state_holder.dart';
import '../data/item_assets.dart';

/// 收益页网格项：非宝石 1 个，宝石 3 个（1/2/3 级）
class _GridItem {
  const _GridItem({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });
  final String assetPath;
  final String label;
  final VoidCallback onTap;
}

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key, required this.holder});

  final AppStateHolder holder;

  static String _formatMoney(int n) {
    final sign = n < 0 ? '-' : '';
    final v = (n.abs() / 10000.0);
    var s = v.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$sign$s万';
  }

  @override
  Widget build(BuildContext context) {
    final activity = holder.selectedActivity;
    final sessionItems = holder.sessionItems;
    final cashIncome = holder.cashIncome;
    final settings = holder.settings;
    final canEdit = holder.isRunning;
    final itemsValue = sessionItems.fold<int>(
      0,
      (sum, i) => sum + i.value(settings),
    );

    final startTime = holder.startTime;
    final pointsConsumed = (canEdit && startTime != null)
        ? holder.pointsConsumedFor(activity)
        : 0.0;
    final pointCost = (pointsConsumed * settings.pointPrice).round();
    final grossIncome = cashIncome + itemsValue;
    final digMapCount = holder.digMapCount;
    final treasureMapPrice = settings.otherItemPrices['藏宝图'] ?? 0;
    final digMapCost =
        activity == ActivityType.digMap ? digMapCount * treasureMapPrice : 0;
    final netProfit = grossIncome - pointCost - digMapCost;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：物品图标列表，点击即获取一次
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '活动类型',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      ...ActivityType.values
                          .map(
                            (t) => ChoiceChip(
                              label: Text(t.displayName),
                              selected: activity == t,
                              onSelected: (_) => holder.setSelectedActivity(t),
                            ),
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    '点击图标记录获取',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (!canEdit)
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('「${activity.displayName}」未开始计时，请先在首页开始该活动。'),
                    ),
                  )
                else
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final gridItems = <_GridItem>[];
                        for (final item in kItemAssets) {
                          if (item.isGem && item.gemType != null) {
                            for (var level = 1; level <= 3; level++) {
                              gridItems.add(
                                _GridItem(
                                  assetPath: item.assetPath,
                                  label: '${item.displayName}$level级',
                                  onTap: () =>
                                      holder.addGem(item.gemType!, level, 1),
                                ),
                              );
                            }
                          } else {
                            gridItems.add(
                              _GridItem(
                                assetPath: item.assetPath,
                                label: item.displayName,
                                onTap: () =>
                                    holder.addOther(item.displayName, 1),
                              ),
                            );
                          }
                        }
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 3,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: gridItems.length,
                          itemBuilder: (context, index) {
                            final gi = gridItems[index];
                            return _ItemIconTile(
                              assetPath: gi.assetPath,
                              displayName: gi.label,
                              onTap: gi.onTap,
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 右侧：金钱、已获取列表、合计
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activity == ActivityType.digMap)
                    Card(
                      child: ListTile(
                        title: const Text('挖图数量'),
                        subtitle: Text(
                          '藏宝图单价: ${_formatMoney(treasureMapPrice)} · 成本: ${_formatMoney(digMapCost)}',
                        ),
                        trailing: SizedBox(
                          width: 140,
                          child: _DigMapCountField(
                            enabled: canEdit,
                            value: digMapCount,
                            onChanged: holder.setDigMapCount,
                          ),
                        ),
                      ),
                    ),
                  _CashTile(
                    value: cashIncome,
                    onChanged: (v) => holder.setCashIncome(v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '已获取（${activity.displayName} · ${sessionItems.length}）',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (sessionItems.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            '暂无物品，点击左侧图标添加',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    ...sessionItems.asMap().entries.map((e) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(_itemSummary(e.value)),
                          subtitle: Text(
                            '价值: ${_formatMoney(e.value.value(settings))}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => holder.removeItemAt(e.key),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '金钱收入',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _formatMoney(cashIncome),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '物品收入',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _formatMoney(itemsValue),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '点卡消耗',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _formatMoney(pointCost),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          if (activity == ActivityType.digMap) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '挖图成本',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  _formatMoney(digMapCost),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '合计收入',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatMoney(grossIncome),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '预计收益（扣点卡）',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatMoney(netProfit),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _itemSummary(HarvestItem i) {
    if (i.ringLevel != null) {
      final lv = switch (i.ringLevel!) {
        RingLevel.ring60 => '60',
        RingLevel.ring70 => '70',
        RingLevel.ring80 => '80',
      };
      return '环装 $lv 级 x${i.ringCount}';
    }
    if (i.gemType != null) {
      return '${i.gemType!.displayName} ${i.gemLevel}级 x${i.gemCount}';
    }
    return '${i.otherName} x${i.otherCount}';
  }
}

class _ItemIconTile extends StatelessWidget {
  const _ItemIconTile({
    required this.assetPath,
    required this.displayName,
    required this.onTap,
  });

  final String assetPath;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashTile extends StatelessWidget {
  const _CashTile({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static int _parseSignedInt(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return 0;
    final m = RegExp(r'^-?\d+').firstMatch(trimmed);
    if (m != null) return int.tryParse(m.group(0)!) ?? 0;
    // 兼容用户输入中夹杂逗号/空格等情况：保留前导 '-'，其余只取数字
    final isNegative = trimmed.startsWith('-');
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse('${isNegative ? '-' : ''}$digits') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('收获金钱（梦幻币）'),
        subtitle: Text('当前: $value'),
        trailing: SizedBox(
          width: 140,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: false,
            ),
            decoration: const InputDecoration(
              labelText: '金额',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (s) {
              onChanged(_parseSignedInt(s));
            },
            onChanged: (s) {
              onChanged(_parseSignedInt(s));
            },
          ),
        ),
      ),
    );
  }
}

class _DigMapCountField extends StatefulWidget {
  const _DigMapCountField({
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_DigMapCountField> createState() => _DigMapCountFieldState();
}

class _DigMapCountFieldState extends State<_DigMapCountField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _DigMapCountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = widget.value.toString();
      if (_controller.text != newText) {
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.enabled,
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '数量',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (s) {
        final n = int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        widget.onChanged(n);
      },
    );
  }
}
