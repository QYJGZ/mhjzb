import 'package:flutter/foundation.dart';
import 'models/app_state.dart';
import 'services/storage_service.dart';

class _RunningSession {
  bool isRunning = false;
  DateTime? startTime;
  int accountCount = 1;
  List<AccountCountChange> accountTimeline = [];
  int cashIncome = 0;
  int digMapCount = 0;
  String? groupId;
  List<HarvestItem> items = [];

  void resetForStart({required int accountCount}) {
    isRunning = true;
    startTime = DateTime.now();
    this.accountCount = accountCount;
    accountTimeline = [
      AccountCountChange(at: startTime!, accountCount: accountCount),
    ];
    cashIncome = 0;
    digMapCount = 0;
    groupId = null;
    items = [];
  }

  void resetForStop() {
    isRunning = false;
    startTime = null;
    cashIncome = 0;
    digMapCount = 0;
    groupId = null;
    items = [];
    accountTimeline = [];
  }

  int get currentAccountCount {
    if (accountTimeline.isEmpty) return accountCount;
    return accountTimeline.last.accountCount;
  }

  void changeAccountCount(int newCount) {
    final cur = currentAccountCount;
    if (newCount == cur) return;
    accountTimeline = List<AccountCountChange>.from(accountTimeline)
      ..add(AccountCountChange(at: DateTime.now(), accountCount: newCount));
  }

  double pointsConsumedUntil(DateTime endTime) {
    final st = startTime;
    if (st == null) return 0;
    final timeline = accountTimeline;
    if (timeline.isEmpty) {
      final secs = endTime.difference(st).inSeconds;
      return secs / 3600.0 * kPointsPerHour * accountCount;
    }
    final events = List<AccountCountChange>.from(timeline)
      ..sort((a, b) => a.at.compareTo(b.at));
    var totalSeconds = 0;
    for (var i = 0; i < events.length; i++) {
      final cur = events[i];
      final segStart = cur.at.isBefore(st) ? st : cur.at;
      final segEnd = (i + 1 < events.length ? events[i + 1].at : endTime);
      final end = segEnd.isAfter(endTime) ? endTime : segEnd;
      if (end.isAfter(segStart) && cur.accountCount > 0) {
        totalSeconds += end.difference(segStart).inSeconds * cur.accountCount;
      }
    }
    final firstAt = events.first.at;
    if (firstAt.isAfter(st) && accountCount > 0) {
      totalSeconds += firstAt.difference(st).inSeconds * accountCount;
    }
    return totalSeconds / 3600.0 * kPointsPerHour;
  }
}

class AppStateHolder extends ChangeNotifier {
  AppStateHolder._();
  static late final AppStateHolder _instance;
  static AppStateHolder get instance => _instance;

  static Future<AppStateHolder> init() async {
    final storage = await StorageService.create();
    final settings = await storage.loadSettings();
    final records = await storage.loadRecords();
    _instance = AppStateHolder._()
      .._storage = storage
      .._settings = settings
      .._records = records;
    return _instance;
  }

  late StorageService _storage;
  PriceSettings _settings = PriceSettings();
  List<SessionRecord> _records = [];

  int _accountCount = 1;
  ActivityType _selectedActivity = ActivityType.unknown;
  late final Map<ActivityType, _RunningSession> _sessions = {
    for (final t in ActivityType.values.where((t) => t != ActivityType.unknown))
      t: _RunningSession(),
  };
  bool _isTotalRunning = false;
  DateTime? _totalStartTime;
  String? _currentGroupId;
  int _totalAccountCount = 1;
  List<AccountCountChange> _totalAccountTimeline = [];
  int _totalCashIncome = 0;
  List<HarvestItem> _totalItems = [];

  PriceSettings get settings => _settings;
  List<SessionRecord> get records => _records;
  int get accountCount => _accountCount;

  ActivityType get selectedActivity => _selectedActivity;
  void setSelectedActivity(ActivityType t) {
    if (_selectedActivity == t) return;
    _selectedActivity = t;
    notifyListeners();
  }

  bool get anyRunning =>
      _isTotalRunning || _sessions.values.any((s) => s.isRunning);

  bool get isTotalRunning => _isTotalRunning;
  DateTime? get totalStartTime => _totalStartTime;
  int get totalAccountCount => _totalAccountCount;
  int get currentTotalAccountCount {
    if (_totalAccountTimeline.isEmpty) return _totalAccountCount;
    return _totalAccountTimeline.last.accountCount;
  }

  double totalPointsConsumed({DateTime? at}) {
    if (!_isTotalRunning || _totalStartTime == null) return 0;
    final st = _totalStartTime!;
    final endTime = at ?? DateTime.now();
    final timeline = _totalAccountTimeline;
    if (timeline.isEmpty) {
      final secs = endTime.difference(st).inSeconds;
      return secs / 3600.0 * kPointsPerHour * _totalAccountCount;
    }
    final events = List<AccountCountChange>.from(timeline)
      ..sort((a, b) => a.at.compareTo(b.at));
    var totalSeconds = 0;
    for (var i = 0; i < events.length; i++) {
      final cur = events[i];
      final segStart = cur.at.isBefore(st) ? st : cur.at;
      final segEnd = (i + 1 < events.length ? events[i + 1].at : endTime);
      final end = segEnd.isAfter(endTime) ? endTime : segEnd;
      if (end.isAfter(segStart) && cur.accountCount > 0) {
        totalSeconds += end.difference(segStart).inSeconds * cur.accountCount;
      }
    }
    final firstAt = events.first.at;
    if (firstAt.isAfter(st) && _totalAccountCount > 0) {
      totalSeconds += firstAt.difference(st).inSeconds * _totalAccountCount;
    }
    return totalSeconds / 3600.0 * kPointsPerHour;
  }

  void adjustTotalAccountCount(int delta) {
    if (!_isTotalRunning) return;
    final cur = currentTotalAccountCount;
    var next = cur + delta;
    if (next < 0) next = 0;
    if (next == cur) return;
    _totalAccountTimeline = List<AccountCountChange>.from(_totalAccountTimeline)
      ..add(AccountCountChange(at: DateTime.now(), accountCount: next));
    notifyListeners();
  }

  bool isRunningFor(ActivityType t) {
    if (t == ActivityType.unknown) return _isTotalRunning;
    return _sessions[t]?.isRunning ?? false;
  }

  DateTime? startTimeFor(ActivityType t) {
    if (t == ActivityType.unknown) return _totalStartTime;
    return _sessions[t]?.startTime;
  }

  int accountCountFor(ActivityType t) {
    if (t == ActivityType.unknown) return _totalAccountCount;
    return _sessions[t]?.accountCount ?? 1;
  }

  int currentAccountCountFor(ActivityType t) {
    if (t == ActivityType.unknown) return currentTotalAccountCount;
    return _sessions[t]?.currentAccountCount ?? 1;
  }

  double pointsConsumedFor(ActivityType t, {DateTime? at}) {
    if (t == ActivityType.unknown) return totalPointsConsumed(at: at);
    final s = _sessions[t];
    if (s == null || !s.isRunning || s.startTime == null) return 0;
    return s.pointsConsumedUntil(at ?? DateTime.now());
  }

  int cashIncomeFor(ActivityType t) {
    if (t == ActivityType.unknown) return _totalCashIncome;
    return _sessions[t]?.cashIncome ?? 0;
  }

  int digMapCountFor(ActivityType t) => _sessions[t]?.digMapCount ?? 0;

  List<HarvestItem> sessionItemsFor(ActivityType t) {
    if (t == ActivityType.unknown) return List.unmodifiable(_totalItems);
    return List.unmodifiable(_sessions[t]?.items ?? const []);
  }

  /// 兼容旧页面调用：默认取当前选择的活动类型。
  bool get isRunning => isRunningFor(_selectedActivity);
  DateTime? get startTime => startTimeFor(_selectedActivity);
  int get cashIncome => cashIncomeFor(_selectedActivity);
  int get digMapCount => digMapCountFor(_selectedActivity);
  List<HarvestItem> get sessionItems => sessionItemsFor(_selectedActivity);

  Future<void> loadSettings() async {
    _settings = await _storage.loadSettings();
    _records = await _storage.loadRecords();
    notifyListeners();
  }

  /// 仅更新内存中的价格（不持久化），用于设置页编辑时收益页即时刷新
  void setSettings(PriceSettings s) {
    _settings = s;
    notifyListeners();
  }

  Future<void> saveSettings(PriceSettings s) async {
    _settings = s;
    await _storage.saveSettings(s);
    notifyListeners();
  }

  void setAccountCount(int n) {
    if (n >= 1 && n <= 10) {
      _accountCount = n;
      notifyListeners();
    }
  }

  void startSession(ActivityType type) {
    final s = _sessions[type];
    if (s == null || s.isRunning) return;
    s.resetForStart(accountCount: _accountCount);
    // 在开始时就绑定所属总计时分组，这样即使总计时先结束，
    // 该活动后续结束保存时仍能归入同一条总计时。
    if (_isTotalRunning && _currentGroupId != null) {
      s.groupId = _currentGroupId;
    }
    notifyListeners();
  }

  void setCashIncome(int n) {
    if (_selectedActivity == ActivityType.unknown) {
      if (!_isTotalRunning) return;
      _totalCashIncome = n;
      notifyListeners();
      return;
    }
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.cashIncome = n;
    notifyListeners();
  }

  void setDigMapCount(int n) {
    if (_selectedActivity != ActivityType.digMap) return;
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.digMapCount = n < 0 ? 0 : n;
    notifyListeners();
  }

  void addRing(RingLevel level, int count) {
    if (_selectedActivity == ActivityType.unknown) {
      if (!_isTotalRunning) return;
      _totalItems.add(HarvestItem.ring(level, count));
      notifyListeners();
      return;
    }
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.items.add(HarvestItem.ring(level, count));
    notifyListeners();
  }

  void addGem(GemType type, int level, int count) {
    if (_selectedActivity == ActivityType.unknown) {
      if (!_isTotalRunning) return;
      _totalItems.add(HarvestItem.gem(type, level, count));
      notifyListeners();
      return;
    }
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.items.add(HarvestItem.gem(type, level, count));
    notifyListeners();
  }

  void addOther(String name, int count) {
    if (_selectedActivity == ActivityType.unknown) {
      if (!_isTotalRunning) return;
      _totalItems.add(HarvestItem.other(name, count));
      notifyListeners();
      return;
    }
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.items.add(HarvestItem.other(name, count));
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (_selectedActivity == ActivityType.unknown) {
      if (!_isTotalRunning) return;
      if (index >= 0 && index < _totalItems.length) {
        _totalItems.removeAt(index);
        notifyListeners();
      }
      return;
    }
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    if (index >= 0 && index < s.items.length) {
      s.items.removeAt(index);
      notifyListeners();
    }
  }

  /// 结束本次计时：计算收益并写入历史，返回本场记录（用于展示本次收益）。
  Future<SessionRecord?> endSession(ActivityType type) async {
    final s = _sessions[type];
    if (s == null || !s.isRunning || s.startTime == null) return null;
    final endTime = DateTime.now();
    final record = SessionRecord(
      id: '${s.startTime!.millisecondsSinceEpoch}',
      activityType: type,
      startTime: s.startTime!,
      endTime: endTime,
      accountCount: s.accountCount,
      accountTimeline: List<AccountCountChange>.from(s.accountTimeline),
      pointPricePerPoint: _settings.pointPrice,
      cashIncome: s.cashIncome,
      digMapCount: s.digMapCount,
      groupId: s.groupId,
      items: List.from(s.items),
    );
    await _storage.appendRecord(record, _settings);
    _records.insert(0, record);
    s.resetForStop();
    notifyListeners();
    return record;
  }

  /// 计时中调整在线账号数：上线为正数，下线为负数。
  /// - 下线不会让在线数为负，最低为 0
  void adjustRunningAccountCount(ActivityType type, int delta) {
    final s = _sessions[type];
    if (s == null || !s.isRunning) return;
    final cur = s.currentAccountCount;
    var next = cur + delta;
    if (next < 0) next = 0;
    s.changeAccountCount(next);
    notifyListeners();
  }

  /// 总计时：仅记录一段时间的所有活动，不单独生成记录，结束时通过 groupId 在历史页汇总。
  void startTotalSession() {
    if (_isTotalRunning) return;
    _isTotalRunning = true;
    _totalStartTime = DateTime.now();
    _currentGroupId = '${_totalStartTime!.millisecondsSinceEpoch}';
    _totalAccountCount = _accountCount;
    _totalAccountTimeline = [
      AccountCountChange(at: _totalStartTime!, accountCount: _totalAccountCount),
    ];
    _totalCashIncome = 0;
    _totalItems = [];
    _selectedActivity = ActivityType.unknown;
    // 如果有活动在总计时开始前就已经在跑，也把它们归入本次总计时。
    for (final s in _sessions.values) {
      if (s.isRunning && (s.groupId == null || s.groupId!.isEmpty)) {
        s.groupId = _currentGroupId;
      }
    }
    notifyListeners();
  }

  void endTotalSession() {
    if (!_isTotalRunning || _totalStartTime == null) return;
    final startTime = _totalStartTime!;
    final endTime = DateTime.now();
    final groupId = _currentGroupId;

    // 如果用户在「收益」页对总计时录入了金钱/物品（包括负数调整），
    // 结束总计时时把它保存成一条“总计时”记录，这样历史汇总会统计到。
    if (_totalCashIncome != 0 || _totalItems.isNotEmpty) {
      final record = SessionRecord(
        id: '${startTime.millisecondsSinceEpoch}-total',
        activityType: ActivityType.unknown,
        startTime: startTime,
        endTime: endTime,
        accountCount: _totalAccountCount,
        accountTimeline: List<AccountCountChange>.from(_totalAccountTimeline),
        pointPricePerPoint: _settings.pointPrice,
        cashIncome: _totalCashIncome,
        digMapCount: 0,
        groupId: groupId,
        items: List<HarvestItem>.from(_totalItems),
      );
      // 异步持久化：不阻塞 UI，失败也不影响结束总计时。
      _storage.appendRecord(record, _settings).then((_) {
        _records.insert(0, record);
        notifyListeners();
      }).catchError((_) {});
    }

    _isTotalRunning = false;
    _totalStartTime = null;
    _currentGroupId = null;
    _totalAccountCount = 1;
    _totalAccountTimeline = [];
    _totalCashIncome = 0;
    _totalItems = [];
    notifyListeners();
  }

  /// 从历史中删除一条记录并持久化。
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _storage.saveRecords(_records, _settings);
    notifyListeners();
  }
}
