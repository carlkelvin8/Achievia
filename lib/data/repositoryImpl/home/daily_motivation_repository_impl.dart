import 'dart:convert';

import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/data_source/home/daily_motivation_remote_datasource.dart';
import 'package:achievia/domain/entities/widgets/daily_motivation_entity.dart';
import 'package:achievia/domain/repository/home/daily_motivation_repository.dart';
import 'package:flutter/foundation.dart';

class DailyMotivationRepositoryImpl implements DailyMotivationRepository {
  DailyMotivationRepositoryImpl(
    this._datasource,
    this._storage, {
    this.timeout = const Duration(seconds: 8),
  });

  final DailyMotivationDataSource _datasource;
  final LocalStorageService _storage;
  final Duration timeout;

  List<DailyMotivationEntity> _parse(List<Map<String, dynamic>> rows) => rows
      .map(DailyMotivationEntity.fromJson)
      .where((m) => m.message.isNotEmpty)
      .toList();

  /// Resolves today's motivation.
  ///
  /// Selection is `activeOrdered[dayNumber % count]`. The pick is cached for
  /// the day so it stays stable if admins change the pool meanwhile; it is only
  /// replaced when it is no longer active. Offline, today's cached pick is
  /// used. Returns null when nothing can be shown.
  @override
  Future<DailyMotivationEntity?> getTodayMotivation({DateTime? now}) async {
    final time = now ?? DateTime.now();
    final today = DailyMotivationPicker.dayKey(time);
    final cached = _readCache(today);
    try {
      final active = _parse(await _datasource.fetchActive().timeout(timeout));
      final keep = cached == null
          ? null
          : active.where((m) => m.id == cached.id).firstOrNull;
      final chosen = keep ?? DailyMotivationPicker.pick(active, time);
      if (chosen == null) {
        await _storage.saveDailyMotivationCache(null);
        return null;
      }
      if (keep == null) await _writeCache(today, chosen);
      return chosen;
    } catch (error) {
      debugPrint('DailyMotivation: fetch failed: $error');
      return cached;
    }
  }

  DailyMotivationEntity? _readCache(String today) {
    try {
      final raw = _storage.dailyMotivationCache;
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['date'] != today) return null;
      final entity = DailyMotivationEntity.fromJson(json);
      return entity.message.isEmpty ? null : entity;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String today, DailyMotivationEntity m) async {
    try {
      await _storage.saveDailyMotivationCache(
        jsonEncode({'date': today, ...m.toCacheJson()}),
      );
    } catch (error) {
      debugPrint('DailyMotivation: cache write failed: $error');
    }
  }

  @override
  Future<bool> isAdmin() async {
    try {
      return await _datasource.isAdmin();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<DailyMotivationEntity>> listAll() async =>
      _parse(await _datasource.fetchAll());

  @override
  Future<void> add(String message) async {
    final text = _validated(message);
    final all = await _datasource.fetchAll();
    final maxOrder = all
        .map((row) => (row['display_order'] as num?)?.toInt() ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    await _datasource.insert(text, displayOrder: maxOrder + 1);
  }

  @override
  Future<void> edit(String id, String message) =>
      _datasource.updateMessage(id, _validated(message));

  @override
  Future<void> setActive(String id, bool active) =>
      _datasource.setActive(id, active);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  String _validated(String message) {
    final error = DailyMotivationEntity.validateMessage(message);
    if (error != null) throw ArgumentError(error);
    return message.trim();
  }
}
