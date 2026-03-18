/// 梦幻西游点卡：每小时 6 点，每 10 分钟 1 点，精确到秒
const double kPointsPerHour = 6.0;

/// 在线账号数变化：用于计时过程中“上线/下线”分段计费。
class AccountCountChange {
  final DateTime at;
  final int accountCount;

  const AccountCountChange({required this.at, required this.accountCount});

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'accountCount': accountCount,
      };

  static AccountCountChange fromJson(Map<String, dynamic> json) {
    return AccountCountChange(
      at: DateTime.parse(json['at'] as String),
      accountCount: (json['accountCount'] as num).toInt(),
    );
  }
}

/// 活动类型：用于区分计时与收益统计
enum ActivityType {
  unknown,
  digMap, // 挖图
  sealDemon, // 封妖
  dungeon, // 副本
  bell, // 铃铛
  sundayEvent, // 周日活动
  cixin, // 慈心
}

extension ActivityTypeX on ActivityType {
  String get displayName {
    const names = {
      ActivityType.unknown: '总计时',
      ActivityType.digMap: '挖图',
      ActivityType.sealDemon: '封妖',
      ActivityType.dungeon: '副本',
      ActivityType.bell: '铃铛',
      ActivityType.sundayEvent: '周日活动',
      ActivityType.cixin: '慈心',
    };
    return names[this]!;
  }
}

/// 环装等级
enum RingLevel { ring60, ring70, ring80 }

/// 宝石类型（用于设置页与收益页）
enum GemType {
  blackGem,    // 黑宝石
  sunGem,      // 太阳石
  starGem,     // 星辉石
  lightGem,    // 光芒石
  moonGem,     // 月亮石
  redAgate,    // 红玛瑙
  sarira,      // 舍利子
  jadeite,     // 翡翠石
  absorbGem,   // 吸收宝石
  mysteryGem,  // 神秘石
}

extension GemTypeX on GemType {
  String get displayName {
    const names = {
      GemType.blackGem: '黑宝石',
      GemType.sunGem: '太阳石',
      GemType.starGem: '星辉石',
      GemType.lightGem: '光芒石',
      GemType.moonGem: '月亮石',
      GemType.redAgate: '红玛瑙',
      GemType.sarira: '舍利子',
      GemType.jadeite: '翡翠石',
      GemType.absorbGem: '吸收宝石',
      GemType.mysteryGem: '神秘石',
    };
    return names[this]!;
  }
}

/// 价格设置（持久化）
class PriceSettings {
  /// 点卡单价：梦幻币/点，默认 15000
  int pointPrice;
  /// RMB 兑换比例：每 3000W（3000万梦幻币）= 多少 RMB，默认 216
  int rmbPer3000w;
  /// 环装 60/70/80 单价
  int ring60Price;
  int ring70Price;
  int ring80Price;
  /// 各宝石 1 级单价（n 级 = base * 2^(n-1)）
  Map<GemType, int> gemBasePrices;
  /// 其他物品：名称 -> 单价
  Map<String, int> otherItemPrices;

  PriceSettings({
    this.pointPrice = 15000,
    this.rmbPer3000w = 216,
    this.ring60Price = 0,
    this.ring70Price = 0,
    this.ring80Price = 0,
    Map<GemType, int>? gemBasePrices,
    Map<String, int>? otherItemPrices,
  })  : gemBasePrices = gemBasePrices ?? _defaultGemPrices(),
        otherItemPrices = otherItemPrices ?? {};

  static Map<GemType, int> _defaultGemPrices() {
    return {
      for (final g in GemType.values) g: 0,
    };
  }

  int gemPrice(GemType type, int level) {
    final base = gemBasePrices[type] ?? 0;
    if (level < 1) return 0;
    return base * (1 << (level - 1)); // 2^(level-1)
  }

  PriceSettings copyWith({
    int? pointPrice,
    int? rmbPer3000w,
    int? ring60Price,
    int? ring70Price,
    int? ring80Price,
    Map<GemType, int>? gemBasePrices,
    Map<String, int>? otherItemPrices,
  }) {
    return PriceSettings(
      pointPrice: pointPrice ?? this.pointPrice,
      rmbPer3000w: rmbPer3000w ?? this.rmbPer3000w,
      ring60Price: ring60Price ?? this.ring60Price,
      ring70Price: ring70Price ?? this.ring70Price,
      ring80Price: ring80Price ?? this.ring80Price,
      gemBasePrices: gemBasePrices ?? Map<GemType, int>.from(this.gemBasePrices),
      otherItemPrices: otherItemPrices ?? Map<String, int>.from(this.otherItemPrices),
    );
  }

  Map<String, dynamic> toJson() => {
        'pointPrice': pointPrice,
        'rmbPer3000w': rmbPer3000w,
        'ring60Price': ring60Price,
        'ring70Price': ring70Price,
        'ring80Price': ring80Price,
        'gemBasePrices': gemBasePrices.map((k, v) => MapEntry(k.name, v)),
        'otherItemPrices': otherItemPrices,
      };

  static PriceSettings fromJson(Map<String, dynamic> json) {
    final gemRaw = json['gemBasePrices'];
    final gem = gemRaw is Map ? Map<String, dynamic>.from(gemRaw) : <String, dynamic>{};
    final defaultGems = _defaultGemPrices();
    for (final e in gem.entries) {
      try {
        defaultGems[GemType.values.byName(e.key)] = (e.value as num).toInt();
      } catch (_) {}
    }
    final otherRaw = json['otherItemPrices'];
    final other = otherRaw is Map
        ? Map<String, int>.from(
            otherRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())))
        : <String, int>{};
    return PriceSettings(
      pointPrice: (json['pointPrice'] as num?)?.toInt() ?? 15000,
      rmbPer3000w: (json['rmbPer3000w'] as num?)?.toInt() ?? 216,
      ring60Price: (json['ring60Price'] as num?)?.toInt() ?? 0,
      ring70Price: (json['ring70Price'] as num?)?.toInt() ?? 0,
      ring80Price: (json['ring80Price'] as num?)?.toInt() ?? 0,
      gemBasePrices: defaultGems,
      otherItemPrices: other,
    );
  }
}

/// 单次收益记录中的物品收获
class HarvestItem {
  /// 环装：用 ring60/70/80 + count
  RingLevel? ringLevel;
  int ringCount;

  /// 宝石：类型 + 等级 + 数量
  GemType? gemType;
  int gemLevel;
  int gemCount;

  /// 其他：名称 + 数量
  String? otherName;
  int otherCount;

  HarvestItem.ring(this.ringLevel, this.ringCount)
      : gemType = null,
        gemLevel = 0,
        gemCount = 0,
        otherName = null,
        otherCount = 0;

  HarvestItem.gem(this.gemType, this.gemLevel, this.gemCount)
      : ringLevel = null,
        ringCount = 0,
        otherName = null,
        otherCount = 0;

  HarvestItem.other(this.otherName, this.otherCount)
      : ringLevel = null,
        ringCount = 0,
        gemType = null,
        gemLevel = 0,
        gemCount = 0;

  int value(PriceSettings settings) {
    if (ringLevel != null) {
      final p = switch (ringLevel!) {
        RingLevel.ring60 => settings.ring60Price,
        RingLevel.ring70 => settings.ring70Price,
        RingLevel.ring80 => settings.ring80Price,
      };
      return p * ringCount;
    }
    if (gemType != null) {
      return settings.gemPrice(gemType!, gemLevel) * gemCount;
    }
    if (otherName != null) {
      return (settings.otherItemPrices[otherName!] ?? 0) * otherCount;
    }
    return 0;
  }
}

/// 单次会话（从开始到结束）的完整记录
class SessionRecord {
  String id;
  ActivityType activityType;
  DateTime startTime;
  DateTime endTime;
  int accountCount;
  List<AccountCountChange> accountTimeline;
  int pointPricePerPoint;
  int cashIncome; // 收获的金钱（梦幻币）
  int digMapCount; // 挖图次数（仅挖图用）
  String? groupId; // 所属总计时分组 ID（总计时开始/结束生成）
  List<HarvestItem> items;
  DateTime createdAt;

  SessionRecord({
    required this.id,
    this.activityType = ActivityType.unknown,
    required this.startTime,
    required this.endTime,
    required this.accountCount,
    List<AccountCountChange>? accountTimeline,
    required this.pointPricePerPoint,
    this.cashIncome = 0,
    this.digMapCount = 0,
    this.groupId,
    List<HarvestItem>? items,
    DateTime? createdAt,
  })  : accountTimeline = accountTimeline ?? const [],
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  Duration get duration => endTime.difference(startTime);

  /// 消耗点卡（点）
  double get pointsConsumed {
    if (accountTimeline.isEmpty) {
      return duration.inSeconds / 3600.0 * kPointsPerHour * accountCount;
    }
    // 分段计算：每段用该段开始时的账号数计费。
    final events = List<AccountCountChange>.from(accountTimeline)
      ..sort((a, b) => a.at.compareTo(b.at));
    var totalSeconds = 0;
    for (var i = 0; i < events.length; i++) {
      final cur = events[i];
      final segStart = cur.at.isBefore(startTime) ? startTime : cur.at;
      final segEnd = (i + 1 < events.length ? events[i + 1].at : endTime);
      final end = segEnd.isAfter(endTime) ? endTime : segEnd;
      if (end.isAfter(segStart) && cur.accountCount > 0) {
        totalSeconds += end.difference(segStart).inSeconds * cur.accountCount;
      }
    }
    // 如果时间轴缺少 startTime 前的事件，补一段用 accountCount。
    final firstAt = events.first.at;
    if (firstAt.isAfter(startTime) && accountCount > 0) {
      totalSeconds += firstAt.difference(startTime).inSeconds * accountCount;
    }
    return totalSeconds / 3600.0 * kPointsPerHour;
  }

  /// 点卡消耗（梦幻币）
  int pointCost() => (pointsConsumed * pointPricePerPoint).round();

  int extraCost(PriceSettings settings) {
    if (activityType == ActivityType.digMap) {
      final mapPrice = settings.otherItemPrices['藏宝图'] ?? 0;
      return digMapCount * mapPrice;
    }
    return 0;
  }

  /// 物品总价值（梦幻币）
  int itemsValue(PriceSettings settings) {
    return items.fold(0, (sum, i) => sum + i.value(settings));
  }

  /// 今日收益 = 物品收入 + 现金收入 - 点卡消耗 - 额外消耗（如挖图成本）
  int profit(PriceSettings settings) {
    return itemsValue(settings) + cashIncome - pointCost() - extraCost(settings);
  }

  Map<String, dynamic> toJson(PriceSettings settings) => {
        'id': id,
        'activityType': activityType.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'accountCount': accountCount,
        'accountTimeline': accountTimeline.map((e) => e.toJson()).toList(),
        'pointPricePerPoint': pointPricePerPoint,
        'cashIncome': cashIncome,
        'digMapCount': digMapCount,
        'groupId': groupId,
        'items': items.map((i) => _harvestToJson(i)).toList(),
        'createdAt': createdAt.toIso8601String(),
        'profit': profit(settings),
      };

  static Map<String, dynamic> _harvestToJson(HarvestItem i) {
    if (i.ringLevel != null) {
      return {'type': 'ring', 'level': i.ringLevel!.name, 'count': i.ringCount};
    }
    if (i.gemType != null) {
      return {
        'type': 'gem',
        'gem': i.gemType!.name,
        'level': i.gemLevel,
        'count': i.gemCount,
      };
    }
    return {'type': 'other', 'name': i.otherName, 'count': i.otherCount};
  }

  static HarvestItem harvestFromJson(Map<String, dynamic> json) {
    switch (json['type'] as String?) {
      case 'ring':
        return HarvestItem.ring(
          RingLevel.values.byName(json['level'] as String),
          (json['count'] as num).toInt(),
        );
      case 'gem':
        return HarvestItem.gem(
          GemType.values.byName(json['gem'] as String),
          (json['level'] as num).toInt(),
          (json['count'] as num).toInt(),
        );
      default:
        return HarvestItem.other(
          json['name'] as String? ?? '',
          (json['count'] as num?)?.toInt() ?? 0,
        );
    }
  }

  static SessionRecord fromJson(Map<String, dynamic> json) {
    final itemListRaw = json['items'];
    final itemList = itemListRaw is List ? itemListRaw : [];
    final timelineRaw = json['accountTimeline'];
    final timelineList = timelineRaw is List ? timelineRaw : const [];
    final timeline = timelineList
        .map((e) => e is Map ? AccountCountChange.fromJson(Map<String, dynamic>.from(e)) : null)
        .whereType<AccountCountChange>()
        .toList();
    ActivityType activityType = ActivityType.unknown;
    final rawType = json['activityType'];
    if (rawType is String && rawType.isNotEmpty) {
      try {
        activityType = ActivityType.values.byName(rawType);
      } catch (_) {
        activityType = ActivityType.unknown;
      }
    }
    return SessionRecord(
      id: json['id'] as String? ?? '',
      activityType: activityType,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      accountCount: (json['accountCount'] as num).toInt(),
      accountTimeline: timeline,
      pointPricePerPoint: (json['pointPricePerPoint'] as num).toInt(),
      cashIncome: (json['cashIncome'] as num?)?.toInt() ?? 0,
      digMapCount: (json['digMapCount'] as num?)?.toInt() ?? 0,
      groupId: json['groupId'] as String?,
      items: itemList
          .map((e) => harvestFromJson(e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
