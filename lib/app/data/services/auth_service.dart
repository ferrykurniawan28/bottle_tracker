import 'dart:convert';
import 'dart:math';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final _storage = GetStorage();
  final _uuid = const Uuid();

  String _generateUniqueCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return String.fromCharCodes(
      Iterable.generate(
        AppConstants.uniqueCodeLength,
        (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
      ),
    );
  }

  List<UserModel> _getUsers() {
    final data = _storage.read<String>(AppConstants.usersKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  void _saveUsers(List<UserModel> users) {
    _storage.write(
      AppConstants.usersKey,
      jsonEncode(users.map((e) => e.toJson()).toList()),
    );
  }

  UserModel? getCurrentUser() {
    final data = _storage.read<String>(AppConstants.currentUserKey);
    if (data == null) return null;
    return UserModel.fromJsonString(data);
  }

  void setCurrentUser(UserModel? user) {
    if (user == null) {
      _storage.remove(AppConstants.currentUserKey);
    } else {
      _storage.write(AppConstants.currentUserKey, user.toJsonString());
    }
  }

  ({bool success, String message, UserModel? user}) register({
    required String email,
    required String password,
    required String name,
  }) {
    final users = _getUsers();

    if (users.any((u) => u.email == email.toLowerCase().trim())) {
      return (success: false, message: 'Email already registered', user: null);
    }

    final user = UserModel(
      id: _uuid.v4(),
      email: email.toLowerCase().trim(),
      password: password,
      name: name.trim(),
      uniqueCode: _generateUniqueCode(),
      role: 'user',
    );

    users.add(user);
    _saveUsers(users);
    setCurrentUser(user);

    return (success: true, message: 'Registration successful', user: user);
  }

  ({bool success, String message, UserModel? user}) login({
    required String email,
    required String password,
  }) {
    if (email.toLowerCase().trim() == AppConstants.adminEmail &&
        password == AppConstants.adminPassword) {
      final admin = UserModel(
        id: 'admin-001',
        email: AppConstants.adminEmail,
        password: AppConstants.adminPassword,
        name: 'Admin',
        uniqueCode: 'ADMIN',
        role: 'admin',
      );
      setCurrentUser(admin);
      return (success: true, message: 'Welcome Admin', user: admin);
    }

    final users = _getUsers();
    final user = users.where(
      (u) => u.email == email.toLowerCase().trim() && u.password == password,
    );

    if (user.isEmpty) {
      return (success: false, message: 'Invalid email or password', user: null);
    }

    setCurrentUser(user.first);
    return (success: true, message: 'Login successful', user: user.first);
  }

  void logout() {
    setCurrentUser(null);
  }

  List<UserModel> getAllUsers() => _getUsers();

  void deleteUser(String userId) {
    final users = _getUsers();
    users.removeWhere((u) => u.id == userId);
    _saveUsers(users);
  }
}
