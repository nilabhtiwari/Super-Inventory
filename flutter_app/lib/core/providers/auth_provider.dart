import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isManager => user?.isManager ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.keyUser);
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson);
        final user = UserModel.fromMap(map);
        state = state.copyWith(user: user);
      } catch (_) {
        await prefs.remove(AppConstants.keyUser);
      }
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final cleanEmail = email.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();

      final regPw = prefs.getString('reg_pw_$cleanEmail');
      if (regPw != null && regPw != password) {
        state = state.copyWith(isLoading: false, errorMessage: 'Incorrect password. Please try again.');
        return false;
      }

      final regUserJson = prefs.getString('reg_$cleanEmail');
      UserModel user;
      if (regUserJson != null) {
        user = UserModel.fromMap(jsonDecode(regUserJson));
      } else {
        UserRole role = UserRole.seller;
        String name = 'Staff Seller';
        if (cleanEmail.contains('admin')) {
          role = UserRole.admin;
          name = 'Admin Owner';
        } else if (cleanEmail.contains('manager')) {
          role = UserRole.manager;
          name = 'Store Manager';
        }
        user = UserModel(
          id: 1,
          uuid: 'user-001',
          name: name,
          email: cleanEmail,
          role: role,
          token: 'jwt_mock_token_active',
          lastLogin: DateTime.now(),
        );
      }

      await prefs.setString(AppConstants.keyUser, jsonEncode(user.toMap()));
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final cleanEmail = email.trim().toLowerCase();
      final user = UserModel(
        id: 1,
        uuid: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: (fullName != null && fullName.isNotEmpty) ? fullName : 'Store Owner',
        email: cleanEmail,
        role: UserRole.admin,
        token: 'jwt_mock_token_active',
        lastLogin: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reg_$cleanEmail', jsonEncode(user.toMap()));
      await prefs.setString('reg_pw_$cleanEmail', password);

      // User registered! Keep user null so they must authenticate via sign-in
      state = state.copyWith(user: null, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUser);
    await prefs.remove(AppConstants.keyToken);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
