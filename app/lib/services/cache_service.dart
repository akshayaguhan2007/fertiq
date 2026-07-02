import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  static const _ttl = {
    'satellite': 24,   // hours
    'weather':    6,
    'sensor':     1,
    'farmer':    72,
  };

  Future<void> set(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    data['_cachedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> get(String key, {int ttlHours = 24}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(data['_cachedAt'] as String);
      if (DateTime.now().difference(cachedAt).inHours > ttlHours) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Named getters for each domain
  Future<Map<String, dynamic>?> getSatellite()  => get('satellite',  ttlHours: _ttl['satellite']!);
  Future<Map<String, dynamic>?> getWeather()    => get('weather',    ttlHours: _ttl['weather']!);
  Future<Map<String, dynamic>?> getSensor()     => get('sensor',     ttlHours: _ttl['sensor']!);
  Future<Map<String, dynamic>?> getFarmer()     => get('farmer',     ttlHours: _ttl['farmer']!);

  Future<void> setSatellite(Map<String, dynamic> d) => set('satellite', d);
  Future<void> setWeather(Map<String, dynamic> d)   => set('weather',   d);
  Future<void> setSensor(Map<String, dynamic> d)    => set('sensor',    d);
  Future<void> setFarmer(Map<String, dynamic> d)    => set('farmer',    d);

  // Language preference
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }
}
