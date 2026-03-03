import 'package:flutter/foundation.dart';
import 'models/app_state.dart';
import 'services/storage_service.dart';

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

  bool _isRunning = false;
  DateTime? _startTime;
  int _accountCount = 1;
  int _cashIncome = 0;
  List<HarvestItem> _sessionItems = [];

  PriceSettings get settings => _settings;
  List<SessionRecord> get records => _records;
  bool get isRunning => _isRunning;
  DateTime? get startTime => _startTime;
  int get accountCount => _accountCount;
  int get cashIncome => _cashIncome;
  List<HarvestItem> get sessionItems => List.unmodifiable(_sessionItems);

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
    if (!_isRunning && n >= 1 && n <= 10) {
      _accountCount = n;
      notifyListeners();
    }
  }

  void startSession() {
    if (_isRunning) return;
    _isRunning = true;
    _startTime = DateTime.now();
    _sessionItems = [];
    _cashIncome = 0;
    notifyListeners();
  }

  void setCashIncome(int n) {
    _cashIncome = n;
    notifyListeners();
  }

  void addRing(RingLevel level, int count) {
    _sessionItems.add(HarvestItem.ring(level, count));
    notifyListeners();
  }

  void addGem(GemType type, int level, int count) {
    _sessionItems.add(HarvestItem.gem(type, level, count));
    notifyListeners();
  }

  void addOther(String name, int count) {
    _sessionItems.add(HarvestItem.other(name, count));
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index >= 0 && index < _sessionItems.length) {
      _sessionItems.removeAt(index);
      notifyListeners();
    }
  }

  /// 结束本次计时：计算收益并写入历史，返回本场记录（用于展示本次收益）。
  Future<SessionRecord?> endSession() async {
    if (!_isRunning || _startTime == null) return null;
    final endTime = DateTime.now();
    final record = SessionRecord(
      id: '${_startTime!.millisecondsSinceEpoch}',
      startTime: _startTime!,
      endTime: endTime,
      accountCount: _accountCount,
      pointPricePerPoint: _settings.pointPrice,
      cashIncome: _cashIncome,
      items: List.from(_sessionItems),
    );
    await _storage.appendRecord(record, _settings);
    _records.insert(0, record);
    _isRunning = false;
    _startTime = null;
    _sessionItems = [];
    _cashIncome = 0;
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
