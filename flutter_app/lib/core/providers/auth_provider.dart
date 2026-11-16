import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

const String _supabaseRestUrl = 'https://lradlwctnqwajejuffys.supabase.co/rest/v1';
const String _supabaseAnonKey = 'sb_publishable_CGkLGQ0WjVp_YzgYJyl7uw_OlNhe5Zh';

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
      final cleanEmail = email.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();

      // 1. Fast match from local storage cache
      final regPw = prefs.getString('reg_pw_$cleanEmail');
      if (regPw != null && regPw == password) {
        final regUserJson = prefs.getString('reg_$cleanEmail');
        UserModel user;
        if (regUserJson != null) {
          user = UserModel.fromMap(jsonDecode(regUserJson));
        } else {
          user = UserModel(
            id: 1,
            uuid: 'user-001',
            name: 'Store Owner',
            email: cleanEmail,
            role: UserRole.seller,
            token: 'jwt_mock_token_active',
            lastLogin: DateTime.now(),
          );
        }
        await prefs.setString(AppConstants.keyUser, jsonEncode(user.toMap()));
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }

      // 2. Query Supabase Cloud for cross-device authentication (Device B support)
      try {
        final queryUri = Uri.parse('$_supabaseRestUrl/sellers?email=eq.${Uri.encodeComponent(cleanEmail)}&select=*');
        final response = await http.get(
          queryUri,
          headers: {
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List list = jsonDecode(response.body);
          if (list.isNotEmpty) {
            final seller = list[0];
            final storedPw = seller['password_hash'] as String?;
            if (storedPw != null && storedPw == password) {
              final user = UserModel(
                id: (seller['id'] is int) ? seller['id'] : 1,
                uuid: 'user-${seller['id']}',
                name: (seller['store_name'] ?? seller['owner_name'] ?? 'Store Owner').toString(),
                email: cleanEmail,
                role: UserRole.seller,
                token: 'jwt_supabase_${seller['id']}',
                lastLogin: DateTime.now(),
              );
              // Cache locally so subsequent sign-ins on this device are instant
              await prefs.setString('reg_$cleanEmail', jsonEncode(user.toMap()));
              await prefs.setString('reg_pw_$cleanEmail', password);
              await prefs.setString(AppConstants.keyUser, jsonEncode(user.toMap()));
              state = state.copyWith(user: user, isLoading: false);
              return true;
            } else {
              state = state.copyWith(isLoading: false, errorMessage: 'wrong username/password try again');
              return false;
            }
          }
        }
      } catch (cloudErr) {
        // Fall through to offline check if network is unavailable
      }

      // 3. Fallback check if user exists locally but password was wrong
      if (regPw != null && regPw != password) {
        state = state.copyWith(isLoading: false, errorMessage: 'wrong username/password try again');
        return false;
      }

      // 4. Default mock accounts for admin/manager
      if (cleanEmail.contains('admin') || cleanEmail.contains('manager')) {
        UserRole role = cleanEmail.contains('admin') ? UserRole.admin : UserRole.manager;
        final user = UserModel(
          id: 1,
          uuid: 'user-001',
          name: cleanEmail.contains('admin') ? 'Admin Owner' : 'Store Manager',
          email: cleanEmail,
          role: role,
          token: 'jwt_mock_token_active',
          lastLogin: DateTime.now(),
        );
        await prefs.setString(AppConstants.keyUser, jsonEncode(user.toMap()));
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, errorMessage: 'wrong username/password try again');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'wrong username/password try again');
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
      final cleanEmail = email.trim().toLowerCase();
      final storeName = (fullName != null && fullName.isNotEmpty) ? fullName : 'Store Owner';

      // 1. Sync to Supabase Cloud directly (Cross-device persistence)
      try {
        final insertUri = Uri.parse('$_supabaseRestUrl/sellers');
        await http.post(
          insertUri,
          headers: {
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({
            'store_name': storeName,
            'owner_name': storeName,
            'email': cleanEmail,
            'password_hash': password,
            'role': 'seller',
            'status': 'active',
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (cloudErr) {
        // Offline resilience
      }

      // 2. Cache in local SharedPreferences
      final user = UserModel(
        id: 1,
        uuid: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: storeName,
        email: cleanEmail,
        role: UserRole.admin,
        token: 'jwt_active',
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
