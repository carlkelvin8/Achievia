import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:achievia/domain/entities/widgets/examination_config_entity.dart';

// Examination configuration provider
final examinationConfigProvider =
    NotifierProvider<ExaminationConfigNotifier, ExaminationConfig>(
      ExaminationConfigNotifier.new,
    );

// Individual configuration providers for easy access
final numberOfItemsProvider = Provider<int>((ref) {
  return ref.watch(examinationConfigProvider).numberOfItems;
});

final durationProvider = Provider<int>((ref) {
  return ref.watch(examinationConfigProvider).durationMinutes;
});

final isDefaultProvider = Provider<bool>((ref) {
  return ref.watch(examinationConfigProvider).isDefault;
});

class ExaminationConfigNotifier extends Notifier<ExaminationConfig> {
  static const String _numberOfItemsKey = 'number_of_items';
  static const String _durationKey = 'duration_minutes';
  static const String _isDefaultKey = 'is_default';

  @override
  ExaminationConfig build() {
    _loadConfig();
    return ExaminationConfig.defaultConfig;
  }

  // Load configuration from SharedPreferences
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numberOfItems =
          prefs.getInt(_numberOfItemsKey) ??
          ExaminationConfig.defaultConfig.numberOfItems;
      final durationMinutes =
          prefs.getInt(_durationKey) ??
          ExaminationConfig.defaultConfig.durationMinutes;
      final isDefault =
          prefs.getBool(_isDefaultKey) ??
          ExaminationConfig.defaultConfig.isDefault;

      state = ExaminationConfig(
        numberOfItems: numberOfItems,
        durationMinutes: durationMinutes,
        isDefault: isDefault,
      );
    } catch (e) {
      // If there's an error, use default configuration
      state = ExaminationConfig.defaultConfig;
    }
  }

  // Save configuration to SharedPreferences
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_numberOfItemsKey, state.numberOfItems);
      await prefs.setInt(_durationKey, state.durationMinutes);
      await prefs.setBool(_isDefaultKey, state.isDefault);
    } catch (e) {
      // Handle error silently
    }
  }

  // Update number of items
  Future<void> updateNumberOfItems(int items) async {
    state = state.copyWith(numberOfItems: items, isDefault: false);
    await _saveConfig();
  }

  // Update duration
  Future<void> updateDuration(int minutes) async {
    state = state.copyWith(durationMinutes: minutes, isDefault: false);
    await _saveConfig();
  }

  // Reset to default configuration
  Future<void> resetToDefault() async {
    state = ExaminationConfig.defaultConfig;
    await _saveConfig();
  }

  // Toggle default mode
  Future<void> toggleDefault() async {
    state = state.copyWith(isDefault: !state.isDefault);
    await _saveConfig();
  }

  // Set specific configuration
  Future<void> setConfig(ExaminationConfig config) async {
    state = config;
    await _saveConfig();
  }

  // Get formatted duration string
  String getFormattedDuration() {
    final hours = state.durationMinutes ~/ 60;
    final minutes = state.durationMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h $minutes m' : '${hours}h';
    }
    return '$minutes mins';
  }

  // Get formatted items string
  String getFormattedItems() {
    return '${state.numberOfItems} items';
  }
}
