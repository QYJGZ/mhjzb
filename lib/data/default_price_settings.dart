import '../models/app_state.dart';
import 'default_item_values.dart';

/// 新安装 app 时的默认价格（首次启动、无本地保存时使用）
/// 初始值来自 [default_item_values.dart]；在设置页点击「导出为默认值」后
/// 可粘贴到本文件替换下方 kDefaultSettingsJson，或直接修改 [default_item_values.dart]。
final Map<String, dynamic> kDefaultSettingsJson = defaultItemValuesJson;

PriceSettings defaultPriceSettings() {
  return PriceSettings.fromJson(kDefaultSettingsJson);
}
