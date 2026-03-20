class DailyIncome {
  /// 每一次“录入”都需要唯一标识，方便逐条删除。
  final String id;
  final DateTime date;
  final int coinIncome; // 梦幻币收入
  final int cashIncome; // 现金收入（人民币）

  const DailyIncome({
    required this.id,
    required this.date,
    required this.coinIncome,
    required this.cashIncome,
  });

  DailyIncome copyWith({
    String? id,
    DateTime? date,
    int? coinIncome,
    int? cashIncome,
  }) {
    return DailyIncome(
      id: id ?? this.id,
      date: date ?? this.date,
      coinIncome: coinIncome ?? this.coinIncome,
      cashIncome: cashIncome ?? this.cashIncome,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'coinIncome': coinIncome,
        'cashIncome': cashIncome,
      };

  static DailyIncome fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String? ?? '';
    final d = DateTime.tryParse(rawDate) ?? DateTime.now();
    // 兼容旧数据：旧版本只有“同一天一条”，没有 id，因此用日期字符串作为 id。
    final id = json['id'] as String? ?? DateTime(d.year, d.month, d.day).toIso8601String();
    return DailyIncome(
      id: id,
      date: DateTime(d.year, d.month, d.day),
      coinIncome: (json['coinIncome'] as num?)?.toInt() ?? 0,
      cashIncome: (json['cashIncome'] as num?)?.toInt() ?? 0,
    );
  }
}

