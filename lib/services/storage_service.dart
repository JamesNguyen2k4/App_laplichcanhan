import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class StorageService {
  static const String _eventsKey = 'events_storage_key';
  static const String _geminiApiKey = 'gemini_api_key';
  static const String _alarmRingtonePathKey = 'alarm_ringtone_path';
  static const String _useVieNeuTtsKey = 'use_vieneu_tts';
  static const String _ttsVoiceNameKey = 'tts_voice_name';
  static const String _ttsVoiceLocaleKey = 'tts_voice_locale';
  static const String _ttsSpeechRateKey = 'tts_speech_rate';
  static const String _ttsPitchKey = 'tts_pitch';

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

  static EventModel? getEventById(String id) {
    final events = getEvents();
    try {
      return events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
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

  // --- CÀI ĐẶT VIENEU-TTS 0.3B OFFLINE ---
  static bool getUseVieNeuTts() {
    return _prefs?.getBool(_useVieNeuTtsKey) ?? true;
  }

  static Future<void> setUseVieNeuTts(bool use) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_useVieNeuTtsKey, use);
  }

  // --- CÀI ĐẶT GIỌNG ĐỌC TTS ---
  static String? getTtsVoiceName() => _prefs?.getString(_ttsVoiceNameKey);
  static String? getTtsVoiceLocale() => _prefs?.getString(_ttsVoiceLocaleKey);

  static Future<void> saveTtsVoice(String? name, String? locale) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (name == null || locale == null) {
      await _prefs!.remove(_ttsVoiceNameKey);
      await _prefs!.remove(_ttsVoiceLocaleKey);
    } else {
      await _prefs!.setString(_ttsVoiceNameKey, name);
      await _prefs!.setString(_ttsVoiceLocaleKey, locale);
    }
  }

  static double getTtsSpeechRate() => _prefs?.getDouble(_ttsSpeechRateKey) ?? 0.5;

  static Future<void> saveTtsSpeechRate(double rate) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_ttsSpeechRateKey, rate);
  }

  static double getTtsPitch() => _prefs?.getDouble(_ttsPitchKey) ?? 1.0;

  static Future<void> saveTtsPitch(double pitch) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_ttsPitchKey, pitch);
  }
}
