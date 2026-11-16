import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class StorageService {
  static const String _eventsKey = 'events_storage_key';
  static const String _geminiApiKey = 'gemini_api_key';
  static const String _alarmRingtonePathKey = 'alarm_ringtone_path';
  static const String _vieneuServerUrlKey = 'vieneu_server_url';
  static const String _useVieNeuTtsKey = 'use_vieneu_tts';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- QUẢN LÝ SỰ KIỆN ---

  static List<EventModel> getEvents() {
    if (_prefs == null) return [];
    final String? data = _prefs!.getString(_eventsKey);
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(data);
      return jsonList.map((e) => EventModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveEvents(List<EventModel> events) async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = events.map((e) => e.toMap()).toList();
    await _prefs!.setString(_eventsKey, json.encode(jsonList));
  }

  static Future<void> addEvent(EventModel event) async {
    final events = getEvents();
    events.add(event);
    await saveEvents(events);
  }

  static Future<void> updateEvent(EventModel updatedEvent) async {
    final events = getEvents();
    final index = events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      events[index] = updatedEvent;
      await saveEvents(events);
    }
  }

  static Future<void> deleteEvent(String id) async {
    final events = getEvents();
    events.removeWhere((e) => e.id == id);
    await saveEvents(events);
  }

  // Lọc sự kiện theo ngày cụ thể (năm, tháng, ngày)
  static List<EventModel> getEventsForDay(DateTime day) {
    final events = getEvents();
    return events.where((e) {
      return e.dateTime.year == day.year &&
             e.dateTime.month == day.month &&
             e.dateTime.day == day.day;
    }).toList();
  }

  // --- QUẢN LÝ GEMINI API KEY ---

  static String? getGeminiApiKey() {
    return _prefs?.getString(_geminiApiKey);
  }

  static Future<void> saveGeminiApiKey(String apiKey) async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    await _prefs!.setString(_geminiApiKey, apiKey.trim());
  }

  // --- CÀI ĐẶT CHUÔNG ---
  static String? getCustomRingtone() {
    return _prefs?.getString(_alarmRingtonePathKey);
  }

  // --- CÀI ĐẶT VIENEU-TTS AI ---
  static String? getVieNeuServerUrl() {
    return _prefs?.getString(_vieneuServerUrlKey);
  }

  static Future<void> saveVieNeuServerUrl(String url) async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    await _prefs!.setString(_vieneuServerUrlKey, url.trim());
  }

  static bool getUseVieNeuTts() {
    return _prefs?.getBool(_useVieNeuTtsKey) ?? false;
  }

  static Future<void> setUseVieNeuTts(bool use) async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    await _prefs!.setBool(_useVieNeuTtsKey, use);
  }
}
