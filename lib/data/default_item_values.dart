import '../models/app_state.dart';

/// 物品价值初始值（新安装或未保存过设置时使用）
/// 修改本文件中的数值即可改变 app 的默认单价。
/// 也可在设置页修改并保存，或使用「导出为默认值」后粘贴到 default_price_settings.dart。

/// 点卡：梦幻币/点
const int kDefaultPointPrice = 15000;

/// RMB 兑换比例：每 3000W（3000万梦幻币）= 多少 RMB
const int kDefaultRmbPer3000w = 216;

/// 环装单价（60/70/80 武器与装备共用）
const int kDefaultRing60Price = 0;
const int kDefaultRing70Price = 0;
const int kDefaultRing80Price = 0;

/// 各宝石 1 级单价（2 级 = 1级×2，3 级 = 2级×2）
const Map<GemType, int> kDefaultGemBasePrices = {
  GemType.blackGem: 160000,
  GemType.sunGem: 70000,
  GemType.starGem: 150000,
  GemType.lightGem: 40000,
  GemType.moonGem: 40000,
  GemType.redAgate: 80000,
  GemType.sarira: 100000,
  GemType.jadeite: 10000,
  GemType.absorbGem: 5000,
  GemType.mysteryGem: 5000,
};

/// 其他物品（环装、五宝、元灵精石、兽决等）显示名 → 单价
/// 可按需修改初始价值，未出现在此处的物品首次在设置页填写后会保存到本地
const Map<String, int> kDefaultOtherItemPrices = {
  '60武器': 240000,
  '60装备': 240000,
  '70武器': 100000,
  '70装备': 80000,
  '80武器': 780000,
  '80装备': 750000,
  '定魂珠': 1250000,
  '金刚石': 1250000,
  '夜光珠': 900000,
  '避水珠': 60000,
  '龙鳞': 320000,
  '元灵精石': 3850000,
  '60元灵精石': 800000,
  '80元灵精石': 1200000,
  '100元灵精石': 3000000,
  '兽决': 870000,
  '孩子用品': 50000,
  '灵饰指南书': 390000,
  '灵饰_60前排': 1000000,
  '灵饰_60后排': 100000,
  '灵饰_80前排': 2000000,
  '灵饰_80后排': 200000,
  '灵饰_100前排': 5000000,
  '灵饰_100后排': 500000,
  '盒子': 25000,
  '藏宝图': 25000,
  '超级金柳露': 270000,
  '金柳露': 30000,
  '符石': 120000,
  '符石卷轴': 30000,
  '朱雀石': 93000,
  '玄武石': 93000,
  '白虎石': 93000,
  '青龙石': 93000,
  '百炼精铁_50': 12000,
  '百炼精铁_60': 50000,
  '百炼精铁_70': 100000,
  '净瓶玉露': 90000,
  '超级净瓶玉露': 380000,
  '摇钱树': 410000,
  '书_60武器': 60000,
  '书_60装备': 60000,
  '书_70武器': 100000,
  '书_70装备': 100000,
  '附魔80': 12000000,
  '附魔100': 13000000,
  '附魔110': 14000000,
  '附魔120': 15000000,
  '附魔130': 16000000,
  '灵石_伤速': 70000,
  '灵石_血防': 40000,
  '珍珠50-70': 80000,
  '珍珠80-90': 150000,
  '珍珠100-110': 200000,
  '珍珠120': 320000,
  '彩果': 360000,
  '海马': 200000,
  '魔石红': 2000000,
  '魔石黄': 2000000,
  '魔石绿': 2000000,
  '魔石紫': 2000000,
  '105图册': 100000,
  '115图册': 150000,
  '125图册': 200000,
  '135图册': 250000,
  '105练妖石': 10000,
  '115练妖石': 30000,
  '125练妖石': 50000,
  '135练妖石': 80000,
  '145练妖石': 120000,
  '2级种子': 30000,
  '3级种子': 30000,
  '4级种子': 60000,
};

/// 汇总为 PriceSettings 所用的 JSON 结构（供 default_price_settings 与存储使用）
Map<String, dynamic> get defaultItemValuesJson => {
  'pointPrice': kDefaultPointPrice,
  'rmbPer3000w': kDefaultRmbPer3000w,
  'ring60Price': kDefaultRing60Price,
  'ring70Price': kDefaultRing70Price,
  'ring80Price': kDefaultRing80Price,
  'gemBasePrices': {
    for (final e in kDefaultGemBasePrices.entries) e.key.name: e.value,
  },
  'otherItemPrices': Map<String, int>.from(kDefaultOtherItemPrices),
};
