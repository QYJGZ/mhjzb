import 'package:flutter/material.dart';
import '../app_state_holder.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key, required this.holder});

  final AppStateHolder holder;

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late final TextEditingController _coinController;
  late final TextEditingController _cashController;

  @override
  void initState() {
    super.initState();
    _coinController = TextEditingController();
    _cashController = TextEditingController();
  }

  @override
  void dispose() {
    _coinController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  int _parseInt(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return 0;
    final digits = trimmed.replaceAll(RegExp(r'[^\d-]'), '');
    if (digits.isEmpty || digits == '-' || digits == '+') return 0;
    return int.tryParse(digits) ?? 0;
  }

  String _formatYi(int coins) {
    if (coins == 0) return '0 亿';
    final v = coins / 100000000.0;
    var s = v.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$s 亿';
  }

  String _estimateCash(int coins) {
    final settings = widget.holder.settings;
    if (coins == 0) return '约 0 元';
    final rmbPer3000w = settings.rmbPer3000w;
    if (rmbPer3000w <= 0) return '';
    final ratio = coins / 30000000.0;
    final rmb = ratio * rmbPer3000w;
    return '约 ${rmb.toStringAsFixed(2)} 元';
  }

  @override
  Widget build(BuildContext context) {
    final holder = widget.holder;
    final today = DateTime.now();

    final coins = _parseInt(_coinController.text);
    final d = DateTime(today.year, today.month, today.day);
    final todayIncomes = holder.dailyIncomes
        .where((e) =>
            e.date.year == d.year && e.date.month == d.month && e.date.day == d.day)
        .toList()
      ..sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '今日收入录入',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _coinController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: false),
                decoration: InputDecoration(
                  labelText: '本次梦幻币收入',
                  hintText: '请输入本次梦幻币收入',
                  border: const OutlineInputBorder(),
                  helperText:
                      coins == 0 ? '统计页面将按「亿」为单位展示' : '${_formatYi(coins)} · ${_estimateCash(coins)}',
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cashController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: false),
                decoration: const InputDecoration(
                  labelText: '本次现金收入（元）',
                  hintText: '可选：请输入本次实际到账现金',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    final coinIncome = _parseInt(_coinController.text);
                    final cashIncome = _parseInt(_cashController.text);
                    await holder.addDailyIncome(
                      date: today,
                      coinIncome: coinIncome,
                      cashIncome: cashIncome,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('今日收入已保存')),
                    );
                    setState(() {
                      _coinController.clear();
                      _cashController.clear();
                    });
                  },
                  child: const Text('确定录入'),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                '今日已录入（可删除）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (todayIncomes.isEmpty)
                Text(
                  '暂无录入记录，点击上方“确定录入”即可添加。',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayIncomes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = todayIncomes[index];
                    final coinText = _formatYi(item.coinIncome);
                    final cashText =
                        item.cashIncome > 0 ? ' · 现金 ${item.cashIncome} 元' : '';
                    return ListTile(
                      title: Text('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'),
                      subtitle: Text('梦幻币：$coinText$cashText'),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
