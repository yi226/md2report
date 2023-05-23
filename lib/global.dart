import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global extends ChangeNotifier {
  /// 单例模式
  factory Global() => _getInstance();

  factory Global.init() => _getInstance();

  static Global? _instance;

  static Global get instance => _getInstance();

  static Global _getInstance() {
    _instance ??= Global._internal();
    return _instance!;
  }

  /// 初始化
  Global._internal() {
    init();
  }

  init() async {
    String? tmp = await get('mode');
    if (tmp != null) {
      mode = ThemeMode.values[int.parse(tmp)];
    }
  }

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  set mode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  Future<String?> get(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userName = prefs.getString(key);
    return userName;
  }

  Future save(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }
}
