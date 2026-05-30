import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature history entry
class FeatureHistoryEntry {
  final String featureId;
  final DateTime timestamp;

  const FeatureHistoryEntry({
    required this.featureId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'featureId': featureId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FeatureHistoryEntry.fromJson(Map<String, dynamic> json) {
    return FeatureHistoryEntry(
      featureId: json['featureId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// User preferences model
class UserPreferences {
  final List<String> favoriteFeatureIds;
  final List<FeatureHistoryEntry> history;
  final List<String> recentSearches;

  const UserPreferences({
    this.favoriteFeatureIds = const [],
    this.history = const [],
    this.recentSearches = const [],
  });

  Map<String, dynamic> toJson() => {
        'favoriteFeatureIds': favoriteFeatureIds,
        'history': history.map((e) => e.toJson()).toList(),
        'recentSearches': recentSearches,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      favoriteFeatureIds: (json['favoriteFeatureIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      history: (json['history'] as List<dynamic>?)
              ?.map((e) =>
                  FeatureHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentSearches: (json['recentSearches'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  UserPreferences copyWith({
    List<String>? favoriteFeatureIds,
    List<FeatureHistoryEntry>? history,
    List<String>? recentSearches,
  }) {
    return UserPreferences(
      favoriteFeatureIds: favoriteFeatureIds ?? this.favoriteFeatureIds,
      history: history ?? this.history,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

/// User preferences manager
class UserPreferencesManager {
  static final UserPreferencesManager _instance =
      UserPreferencesManager._internal();
  factory UserPreferencesManager() => _instance;
  UserPreferencesManager._internal();

  static const String _prefsKey = 'user_preferences';
  static const int _maxHistorySize = 20;
  static const int _maxRecentSearches = 10;

  UserPreferences _preferences = const UserPreferences();
  UserPreferences get preferences => _preferences;

  /// Load preferences from storage
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _preferences = UserPreferences.fromJson(json);
      } catch (e) {
        debugPrint('Error loading preferences: $e');
      }
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_preferences.toJson());
    await prefs.setString(_prefsKey, jsonString);
  }

  /// Toggle favorite
  Future<void> toggleFavorite(String featureId) async {
    final favorites = List<String>.from(_preferences.favoriteFeatureIds);

    if (favorites.contains(featureId)) {
      favorites.remove(featureId);
    } else {
      favorites.add(featureId);
    }

    _preferences = _preferences.copyWith(favoriteFeatureIds: favorites);
    await _savePreferences();
  }

  /// Check if feature is favorite
  bool isFavorite(String featureId) {
    return _preferences.favoriteFeatureIds.contains(featureId);
  }

  /// Add to history
  Future<void> addToHistory(String featureId) async {
    var history = List<FeatureHistoryEntry>.from(_preferences.history);

    // Remove existing entry if present
    history.removeWhere((e) => e.featureId == featureId);

    // Add new entry at the beginning
    history.insert(
        0,
        FeatureHistoryEntry(
          featureId: featureId,
          timestamp: DateTime.now(),
        ));

    // Limit history size
    if (history.length > _maxHistorySize) {
      history = history.sublist(0, _maxHistorySize);
    }

    _preferences = _preferences.copyWith(history: history);
    await _savePreferences();
  }

  /// Get recent history
  List<FeatureHistoryEntry> getRecentHistory({int limit = 5}) {
    return _preferences.history.take(limit).toList();
  }

  /// Clear history
  Future<void> clearHistory() async {
    _preferences = _preferences.copyWith(history: []);
    await _savePreferences();
  }

  /// Add recent search
  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    var searches = List<String>.from(_preferences.recentSearches);

    // Remove existing entry if present
    searches.remove(query);

    // Add new entry at the beginning
    searches.insert(0, query);

    // Limit searches size
    if (searches.length > _maxRecentSearches) {
      searches = searches.sublist(0, _maxRecentSearches);
    }

    _preferences = _preferences.copyWith(recentSearches: searches);
    await _savePreferences();
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    _preferences = _preferences.copyWith(recentSearches: []);
    await _savePreferences();
  }
}
