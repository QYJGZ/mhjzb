import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_state.dart';
import '../app_state_holder.dart';
import '../data/item_assets.dart';

/// 设置页：进入时显示上次保存的价格，修改后点「保存」写入本地，下次进入 app 仍是已保存的值。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.holder});

  final AppStateHolder holder;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// 本地草稿，进入设置页时从 holder（已从本地加载）同步，保存时写入 holder 并持久化
  late PriceSettings _draft;

  @override
  void initState() {
    super.initState();
    _syncDraftFromHolder();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holder != widget.holder) _syncDraftFromHolder();
  }

  void _syncDraftFromHolder() {
    final s = widget.holder.settings;
    _draft = PriceSettings(
      pointPrice: s.pointPrice,
      ring60Price: s.ring60Price,
      ring70Price: s.ring70Price,
      ring80Price: s.ring80Price,
      gemBasePrices: Map<GemType, int>.from(s.gemBasePrices),
      otherItemPrices: Map<String, int>.from(s.otherItemPrices),
    );
  }

  int _priceForItem(ItemAsset item) {
    if (item.gemType != null) {
      return _draft.gemBasePrices[item.gemType!] ?? 0;
    }
    return _draft.otherItemPrices[item.displayName] ?? 0;
  }

  void _setPriceForItem(ItemAsset item, int v) {
    if (item.gemType != null) {
      final m = Map<GemType, int>.from(_draft.gemBasePrices);
      m[item.gemType!] = v;
      _updateDraft(_draft.copyWith(gemBasePrices: m));
    } else {
      final m = Map<String, int>.from(_draft.otherItemPrices);
      m[item.displayName] = v;
      _updateDraft(_draft.copyWith(otherItemPrices: m));
    }
  }

  void _updateDraft(PriceSettings newDraft) {
    setState(() => _draft = newDraft);
    widget.holder.setSettings(newDraft); // 即时同步到 holder，收益页价格立即更新
  }

  Future<void> _saveDraft() async {
    await widget.holder.saveSettings(_draft);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已保存到本地，下次打开 app 将使用当前价格')));
    }
  }

  /// 导出当前价格为默认值代码，复制到剪贴板
  void _exportAsDefaults() {
    final gemLines = _draft.gemBasePrices.entries
        .map((e) => "    '${e.key.name}': ${e.value}")
        .join(',\n');
    final otherLines = _draft.otherItemPrices.entries
        .map((e) => "    '${e.key.replaceAll("'", "\\'")}': ${e.value}")
        .join(',\n');
    final code =
        '''const Map<String, dynamic> kDefaultSettingsJson = {
  'pointPrice': ${_draft.pointPrice},
  'ring60Price': ${_draft.ring60Price},
  'ring70Price': ${_draft.ring70Price},
  'ring80Price': ${_draft.ring80Price},
  'gemBasePrices': {
$gemLines
  },
  'otherItemPrices': {${otherLines.isNotEmpty ? '\n$otherLines\n  ' : ''}},
};''';
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '已复制到剪贴板，请粘贴到 lib/data/default_price_settings.dart 替换 kDefaultSettingsJson',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '价格设置',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点卡：每小时 6 点，按秒计费。下方单价为每点梦幻币价格。修改后点击「保存」即可，下次进入 app 会使用已保存的价格。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _NumberTile(
                label: '点卡单价（梦幻币/点）',
                value: _draft.pointPrice,
                onChanged: (v) => _updateDraft(_draft.copyWith(pointPrice: v)),
              ),
              const SizedBox(height: 24),
              Text(
                '物品单价（图标来自梦幻图片，收益页点击图标即按此价格计入）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...kItemAssets.map(
                (item) => _ItemPriceTile(
                  assetPath: item.assetPath,
                  displayName: item.isGem
                      ? '${item.displayName}（1级单价）'
                      : item.displayName,
                  price: _priceForItem(item),
                  onPriceChanged: (v) => _setPriceForItem(item, v),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveDraft,
                      icon: const Icon(Icons.save),
                      label: const Text('保存'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportAsDefaults,
                      icon: const Icon(Icons.code),
                      label: const Text('导出为默认值'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置页：单个物品行（图标 + 名称 + 单价）
class _ItemPriceTile extends StatefulWidget {
  const _ItemPriceTile({
    required this.assetPath,
    required this.displayName,
    required this.price,
    required this.onPriceChanged,
  });

  final String assetPath;
  final String displayName;
  final int price;
  final ValueChanged<int> onPriceChanged;

  @override
  State<_ItemPriceTile> createState() => _ItemPriceTileState();
}

class _ItemPriceTileState extends State<_ItemPriceTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.price.toString());
  }

  @override
  void didUpdateWidget(covariant _ItemPriceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price &&
        _controller.text != widget.price.toString()) {
      _controller.text = widget.price.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.assetPath,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.displayName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '单价',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (s) => widget.onPriceChanged(
                  int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text('梦幻币', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _NumberTile extends StatefulWidget {
  const _NumberTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<_NumberTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _NumberTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static int _parse(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (s) => widget.onChanged(_parse(s)),
      ),
    );
  }
}
