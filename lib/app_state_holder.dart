import 'package:flutter/foundation.dart';
import 'models/app_state.dart';
import 'services/storage_service.dart';

class _RunningSession {
  bool isRunning = false;
  DateTime? startTime;
  int accountCount = 1;
  int cashIncome = 0;
  int digMapCount = 0;
  List<HarvestItem> items = [];

  void resetForStart({required int accountCount}) {
    isRunning = true;
    startTime = DateTime.now();
    this.accountCount = accountCount;
    cashIncome = 0;
    digMapCount = 0;
    items = [];
  }

  void resetForStop() {
    isRunning = false;
    startTime = null;
    cashIncome = 0;
    digMapCount = 0;
    items = [];
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
    for (final t in ActivityType.values) t: _RunningSession(),
  };

  PriceSettings get settings => _settings;
  List<SessionRecord> get records => _records;
  int get accountCount => _accountCount;

  ActivityType get selectedActivity => _selectedActivity;
  void setSelectedActivity(ActivityType t) {
    if (_selectedActivity == t) return;
    _selectedActivity = t;
    notifyListeners();
  }

  bool get anyRunning => _sessions.values.any((s) => s.isRunning);

  bool isRunningFor(ActivityType t) => _sessions[t]?.isRunning ?? false;
  DateTime? startTimeFor(ActivityType t) => _sessions[t]?.startTime;
  int accountCountFor(ActivityType t) => _sessions[t]?.accountCount ?? 1;
  int cashIncomeFor(ActivityType t) => _sessions[t]?.cashIncome ?? 0;
  int digMapCountFor(ActivityType t) => _sessions[t]?.digMapCount ?? 0;
  List<HarvestItem> sessionItemsFor(ActivityType t) =>
      List.unmodifiable(_sessions[t]?.items ?? const []);

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
    notifyListeners();
  }

  void setCashIncome(int n) {
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
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.items.add(HarvestItem.ring(level, count));
    notifyListeners();
  }

  void addGem(GemType type, int level, int count) {
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.items.add(HarvestItem.gem(type, level, count));
    notifyListeners();
  }

  void addOther(String name, int count) {
    final s = _sessions[_selectedActivity];
    if (s == null || !s.isRunning) return;
    s.items.add(HarvestItem.other(name, count));
    notifyListeners();
  }

  void removeItemAt(int index) {
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
      pointPricePerPoint: _settings.pointPrice,
      cashIncome: s.cashIncome,
      digMapCount: s.digMapCount,
      items: List.from(s.items),
    );
    await _storage.appendRecord(record, _settings);
    _records.insert(0, record);
    s.resetForStop();
    notifyListeners();
    return record;
  }

  /// 从历史中删除一条记录并持久化。
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _storage.saveRecords(_records, _settings);
    notifyListeners();
  }
}
