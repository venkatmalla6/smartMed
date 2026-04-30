import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/hive_service.dart';

class SettingsProvider extends ChangeNotifier {
  late Box<String> _settingsBox;

  String _userName = '';
  String _userGender = '';
  String _userTitle = 'Dr.';
  String _specialty = '';

  String get userName => _userName;
  String get userGender => _userGender;
  String get userTitle => _userTitle;
  String get specialty => _specialty;

  SettingsProvider() {
    _init();
  }

  void _init() {
    _settingsBox = Hive.box<String>(HiveService.settingsBoxName);
    _userName = _settingsBox.get('user_name', defaultValue: '')!;
    _userGender = _settingsBox.get('user_gender', defaultValue: '')!;
    _userTitle = _settingsBox.get('user_title', defaultValue: 'Dr.')!;
    _specialty = _settingsBox.get('user_specialty', defaultValue: '')!;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String gender,
    required String title,
    required String specialty,
  }) async {
    _userName = name;
    _userGender = gender;
    _userTitle = title;
    _specialty = specialty;
    
    await _settingsBox.put('user_name', name);
    await _settingsBox.put('user_gender', gender);
    await _settingsBox.put('user_title', title);
    await _settingsBox.put('user_specialty', specialty);
    
    notifyListeners();
  }
}
