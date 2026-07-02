import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kApiBase = 'http://localhost:8000'; // web/Windows desktop
// Android emulator → use http://10.0.2.2:8000
// Real Android device → use http://10.186.32.104:8000

class AuthService extends ChangeNotifier {
  AuthService._();
  static final instance = AuthService._();

  String? _token;
  String? _userId;
  String? _name;
  String? _email;

  String? get token   => _token;
  String? get userId  => _userId;
  String? get name    => _name;
  String? get email   => _email;
  bool   get isLoggedIn => _token != null;

  Future<void> loadFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    _token  = p.getString('token');
    _userId = p.getString('userId');
    _name   = p.getString('name');
    _email  = p.getString('email');
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    if (_token != null) {
      await p.setString('token',  _token!);
      await p.setString('userId', _userId!);
      await p.setString('name',   _name ?? '');
      await p.setString('email',  _email ?? '');
    } else {
      await p.remove('token');
      await p.remove('userId');
      await p.remove('name');
      await p.remove('email');
    }
  }

  Future<String?> register(String email, String password, String name) async {
    try {
      final res = await http.post(
        Uri.parse('$kApiBase/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        _token  = data['token'];
        _userId = data['user_id'];
        _name   = data['name'];
        _email  = data['email'];
        await _savePrefs();
        notifyListeners();
        return null;
      }
      return data['detail'] as String? ?? 'Registration failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$kApiBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        _token  = data['token'];
        _userId = data['user_id'];
        _name   = data['name'];
        _email  = data['email'];
        await _savePrefs();
        notifyListeners();
        return null;
      }
      return data['detail'] as String? ?? 'Login failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await http.post(
        Uri.parse('$kApiBase/auth/logout'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
    _token = _userId = _name = _email = null;
    await _savePrefs();
    notifyListeners();
  }
}
