import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/shop_settings_model.dart';
import '../../data/local/database_helper.dart';

class SettingsNotifier extends StateNotifier<ShopSettingsModel> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  SettingsNotifier() : super(ShopSettingsModel()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final settings = await _db.getShopSettings();
    state = settings;
  }

  Future<void> updateSettings(ShopSettingsModel updated) async {
    await _db.updateShopSettings(updated);
    state = updated;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, ShopSettingsModel>((ref) {
  return SettingsNotifier();
});
