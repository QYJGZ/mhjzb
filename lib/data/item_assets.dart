import '../models/app_state.dart';

/// 梦幻图片资源：物品图标路径与显示名（文件名去掉扩展名）
/// 若 gemType 非空则为宝石，收益页展示 1/2/3 级三个图标
class ItemAsset {
  const ItemAsset({
    required this.assetPath,
    required this.displayName,
    this.gemType,
  });
  final String assetPath;
  final String displayName;

  /// 若为宝石，则非空；收益页展示 1/2/3 级
  final GemType? gemType;

  bool get isGem => gemType != null;
}

/// 来自 assets/items/ 的物品列表（顺序：宝石 → 环装 → 五宝 → 其他）
const List<ItemAsset> kItemAssets = [
  // 宝石系列（1级价格在设置页，2级=1级×2，3级=2级×2）
  ItemAsset(
    assetPath: 'assets/items/光芒石.jpg',
    displayName: '光芒石',
    gemType: GemType.lightGem,
  ),
  ItemAsset(
    assetPath: 'assets/items/太阳石.jpg',
    displayName: '太阳石',
    gemType: GemType.sunGem,
  ),
  ItemAsset(
    assetPath: 'assets/items/月亮石.jpg',
    displayName: '月亮石',
    gemType: GemType.moonGem,
  ),
  ItemAsset(
    assetPath: 'assets/items/红玛瑙.jpg',
    displayName: '红玛瑙',
    gemType: GemType.redAgate,
  ),
  ItemAsset(
    assetPath: 'assets/items/翡翠石.jpg',
    displayName: '翡翠石',
    gemType: GemType.jadeite,
  ),
  ItemAsset(
    assetPath: 'assets/items/舍利子.jpg',
    displayName: '舍利子',
    gemType: GemType.sarira,
  ),
  ItemAsset(
    assetPath: 'assets/items/黑宝石.jpg',
    displayName: '黑宝石',
    gemType: GemType.blackGem,
  ),
  ItemAsset(
    assetPath: 'assets/items/吸收宝石.jpg',
    displayName: '吸收宝石',
    gemType: GemType.absorbGem,
  ),
  ItemAsset(
    assetPath: 'assets/items/神秘石.jpg',
    displayName: '神秘石',
    gemType: GemType.mysteryGem,
  ),
  ItemAsset(
    assetPath: 'assets/items/星辉石.png',
    displayName: '星辉石',
    gemType: GemType.starGem,
  ),
  // 环装
  ItemAsset(assetPath: 'assets/items/60武器.jpg', displayName: '60武器'),
  ItemAsset(assetPath: 'assets/items/60装备.jpg', displayName: '60装备'),
  ItemAsset(assetPath: 'assets/items/70武器.jpg', displayName: '70武器'),
  ItemAsset(assetPath: 'assets/items/70装备.jpg', displayName: '70装备'),
  ItemAsset(assetPath: 'assets/items/80武器.jpg', displayName: '80武器'),
  ItemAsset(assetPath: 'assets/items/80装备.jpg', displayName: '80装备'),
  // 五宝
  ItemAsset(assetPath: 'assets/items/定魂珠.png', displayName: '定魂珠'),
  ItemAsset(assetPath: 'assets/items/金刚石.png', displayName: '金刚石'),
  ItemAsset(assetPath: 'assets/items/夜光珠.png', displayName: '夜光珠'),
  ItemAsset(assetPath: 'assets/items/避水珠.png', displayName: '避水珠'),
  ItemAsset(assetPath: 'assets/items/龙鳞.png', displayName: '龙鳞'),
  // 其他
  ItemAsset(assetPath: 'assets/items/60元灵精石.png', displayName: '60元灵精石'),
  ItemAsset(assetPath: 'assets/items/80元灵精石.png', displayName: '80元灵精石'),
  ItemAsset(assetPath: 'assets/items/100元灵精石.png', displayName: '100元灵精石'),
  ItemAsset(assetPath: 'assets/items/兽决.png', displayName: '兽决'),
  ItemAsset(assetPath: 'assets/items/孩子用品.jpg', displayName: '孩子用品'),
  ItemAsset(assetPath: 'assets/items/灵饰_60前排.png', displayName: '灵饰_60前排'),
  ItemAsset(assetPath: 'assets/items/灵饰_60后排.png', displayName: '灵饰_60后排'),
  ItemAsset(assetPath: 'assets/items/灵饰_80前排.png', displayName: '灵饰_80前排'),
  ItemAsset(assetPath: 'assets/items/灵饰_80后排.png', displayName: '灵饰_80后排'),
  ItemAsset(assetPath: 'assets/items/灵饰_100前排.png', displayName: '灵饰_100前排'),
  ItemAsset(assetPath: 'assets/items/灵饰_100后排.png', displayName: '灵饰_100后排'),
  ItemAsset(assetPath: 'assets/items/盒子.jpg', displayName: '盒子'),
  ItemAsset(assetPath: 'assets/items/藏宝图.png', displayName: '藏宝图'),
  ItemAsset(assetPath: 'assets/items/超级金柳露.jpg', displayName: '超级金柳露'),
  ItemAsset(assetPath: 'assets/items/金柳露.jpg', displayName: '金柳露'),
  ItemAsset(assetPath: 'assets/items/符石.png', displayName: '符石'),
  ItemAsset(assetPath: 'assets/items/符石卷轴.png', displayName: '符石卷轴'),
  ItemAsset(assetPath: 'assets/items/朱雀石.png', displayName: '朱雀石'),
  ItemAsset(assetPath: 'assets/items/玄武石.png', displayName: '玄武石'),
  ItemAsset(assetPath: 'assets/items/白虎石.png', displayName: '白虎石'),
  ItemAsset(assetPath: 'assets/items/青龙石.png', displayName: '青龙石'),
  ItemAsset(assetPath: 'assets/items/百炼精铁_50.jpeg', displayName: '百炼精铁_50'),
  ItemAsset(assetPath: 'assets/items/百炼精铁_60.jpeg', displayName: '百炼精铁_60'),
  ItemAsset(assetPath: 'assets/items/百炼精铁_70.jpeg', displayName: '百炼精铁_70'),
  ItemAsset(assetPath: 'assets/items/净瓶玉露.webp', displayName: '净瓶玉露'),
  ItemAsset(assetPath: 'assets/items/超级净瓶玉露.webp', displayName: '超级净瓶玉露'),
  ItemAsset(assetPath: 'assets/items/摇钱树.png', displayName: '摇钱树'),
  ItemAsset(assetPath: 'assets/items/书_60武器.png', displayName: '书_60武器'),
  ItemAsset(assetPath: 'assets/items/书_60装备.png', displayName: '书_60装备'),
  ItemAsset(assetPath: 'assets/items/书_70武器.png', displayName: '书_70武器'),
  ItemAsset(assetPath: 'assets/items/书_70装备.png', displayName: '书_70装备'),
  ItemAsset(assetPath: 'assets/items/附魔宝珠.png', displayName: '附魔宝珠'),
  ItemAsset(assetPath: 'assets/items/附魔80.png', displayName: '附魔80'),
  ItemAsset(assetPath: 'assets/items/附魔100.png', displayName: '附魔100'),
  ItemAsset(assetPath: 'assets/items/附魔110.png', displayName: '附魔110'),
  ItemAsset(assetPath: 'assets/items/附魔120.png', displayName: '附魔120'),
  ItemAsset(assetPath: 'assets/items/附魔130.png', displayName: '附魔130'),
  ItemAsset(assetPath: 'assets/items/灵石_伤速.png', displayName: '灵石_伤速'),
  ItemAsset(assetPath: 'assets/items/灵石_血防.png', displayName: '灵石_血防'),
  ItemAsset(assetPath: 'assets/items/珍珠50-70.png', displayName: '珍珠50-70'),
  ItemAsset(assetPath: 'assets/items/珍珠80-90.png', displayName: '珍珠80-90'),
  ItemAsset(assetPath: 'assets/items/珍珠100-110.png', displayName: '珍珠100-110'),
  ItemAsset(assetPath: 'assets/items/珍珠120.png', displayName: '珍珠120'),
  ItemAsset(assetPath: 'assets/items/彩果.png', displayName: '彩果'),
  ItemAsset(assetPath: 'assets/items/海马.png', displayName: '海马'),
  ItemAsset(assetPath: 'assets/items/魔石红.png', displayName: '魔石红'),
  ItemAsset(assetPath: 'assets/items/魔石黄.png', displayName: '魔石黄'),
  ItemAsset(assetPath: 'assets/items/魔石绿.png', displayName: '魔石绿'),
  ItemAsset(assetPath: 'assets/items/魔石紫.png', displayName: '魔石紫'),
  ItemAsset(assetPath: 'assets/items/105图册.jpg', displayName: '105图册'),
  ItemAsset(assetPath: 'assets/items/115图册.jpg', displayName: '115图册'),
  ItemAsset(assetPath: 'assets/items/125图册.jpg', displayName: '125图册'),
  ItemAsset(assetPath: 'assets/items/135图册.jpg', displayName: '135图册'),
  ItemAsset(assetPath: 'assets/items/105练妖石.jpg', displayName: '105练妖石'),
  ItemAsset(assetPath: 'assets/items/115练妖石.jpg', displayName: '115练妖石'),
  ItemAsset(assetPath: 'assets/items/125练妖石.jpg', displayName: '125练妖石'),
  ItemAsset(assetPath: 'assets/items/135练妖石.jpg', displayName: '135练妖石'),
  ItemAsset(assetPath: 'assets/items/145练妖石.jpg', displayName: '145练妖石'),
  ItemAsset(assetPath: 'assets/items/2级种子.png', displayName: '2级种子'),
  ItemAsset(assetPath: 'assets/items/3级种子.png', displayName: '3级种子'),
  ItemAsset(assetPath: 'assets/items/4级种子.png', displayName: '4级种子'),
];
