import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/learning_direction.dart';

/// How long a spent heart takes to regenerate on its own.
const Duration kHeartRegenInterval = Duration(hours: 4);
const int kMaxHearts = 5;
const int kStartingGems = 50;

/// Single source of truth for the gamification loop: hearts, XP, streaks
/// and gems. Backed by a Hive box so every mutation survives an app
/// restart without any extra plumbing (Stage 4 builds the rest of the
/// offline storage layer on top of this).
class GameStateProvider extends ChangeNotifier {
  static const String _boxName = 'playerState';

  late Box<dynamic> _box;
  Timer? _regenTimer;
  bool _isReady = false;

  int _hearts = kMaxHearts;
  int _xp = 0;
  int _gems = kStartingGems;
  int _streakCount = 0;
  int _streakFreezes = 0;
  DateTime? _lastActiveDate;
  DateTime? _nextHeartRefillAt;
  DateTime? _doubleXpExpiresAt;
  Set<String> _activeDates = <String>{};
  UiLang _uiLang = UiLang.fr;
  bool _hasOnboarded = false;

  bool get isReady => _isReady;
  int get hearts => _hearts;
  int get maxHearts => kMaxHearts;
  int get xp => _xp;
  int get gems => _gems;
  int get streakCount => _streakCount;
  int get streakFreezes => _streakFreezes;
  DateTime? get nextHeartRefillAt => _nextHeartRefillAt;

  UiLang get uiLang => _uiLang;
  bool get hasOnboarded => _hasOnboarded;

  /// The learning direction is derived from the interface language: a child
  /// who speaks Kabyle is learning French, and vice-versa.
  LearningDirection get direction => _uiLang == UiLang.kab
      ? LearningDirection.kabyleToFrench
      : LearningDirection.frenchToKabyle;

  bool get hasDoubleXp =>
      _doubleXpExpiresAt != null && DateTime.now().isBefore(_doubleXpExpiresAt!);

  int get level => (_xp ~/ 100) + 1;
  int get xpIntoCurrentLevel => _xp % 100;
  double get levelProgress => xpIntoCurrentLevel / 100.0;

  /// True once a streak exists but today hasn't been logged yet — used to
  /// grey out the flame icon as a gentle "don't lose it" nudge.
  bool get isStreakAtRisk {
    if (_streakCount == 0) return false;
    return !_activeDates.contains(_dateKey(DateTime.now()));
  }

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);

    _hearts = (_box.get('hearts') as int?) ?? kMaxHearts;
    _xp = (_box.get('xp') as int?) ?? 0;
    _gems = (_box.get('gems') as int?) ?? kStartingGems;
    _streakCount = (_box.get('streakCount') as int?) ?? 0;
    _streakFreezes = (_box.get('streakFreezes') as int?) ?? 0;

    final lastActiveIso = _box.get('lastActiveDate') as String?;
    _lastActiveDate = lastActiveIso != null ? DateTime.tryParse(lastActiveIso) : null;

    final nextRefillIso = _box.get('nextHeartRefillAt') as String?;
    _nextHeartRefillAt = nextRefillIso != null ? DateTime.tryParse(nextRefillIso) : null;

    final doubleXpIso = _box.get('doubleXpExpiresAt') as String?;
    _doubleXpExpiresAt = doubleXpIso != null ? DateTime.tryParse(doubleXpIso) : null;

    final storedDates = (_box.get('activeDates') as List?)?.cast<String>() ?? <String>[];
    _activeDates = storedDates.toSet();

    final uiLangName = _box.get('uiLang') as String?;
    _uiLang = UiLang.values.firstWhere(
      (l) => l.name == uiLangName,
      orElse: () => UiLang.fr,
    );
    _hasOnboarded = (_box.get('hasOnboarded') as bool?) ?? false;

    _refillHeartsIfDue();
    _regenTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refillHeartsIfDue());

    _isReady = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------
  // Hearts
  // ---------------------------------------------------------------------

  void loseHeart() {
    if (_hearts <= 0) return;
    _hearts -= 1;
    _nextHeartRefillAt ??= DateTime.now().add(kHeartRegenInterval);
    _persist();
    notifyListeners();
  }

  void refillHeartsInstantly() {
    _hearts = kMaxHearts;
    _nextHeartRefillAt = null;
    _persist();
    notifyListeners();
  }

  void _refillHeartsIfDue() {
    if (_hearts >= kMaxHearts || _nextHeartRefillAt == null) return;
    final now = DateTime.now();
    var changed = false;

    while (_hearts < kMaxHearts &&
        _nextHeartRefillAt != null &&
        !now.isBefore(_nextHeartRefillAt!)) {
      _hearts += 1;
      changed = true;
      _nextHeartRefillAt =
          _hearts < kMaxHearts ? _nextHeartRefillAt!.add(kHeartRegenInterval) : null;
    }

    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // XP
  // ---------------------------------------------------------------------

  void addXp(int amount) {
    if (amount <= 0) return;
    _xp += hasDoubleXp ? amount * 2 : amount;
    _persist();
    notifyListeners();
  }

  void activateDoubleXp(Duration duration) {
    _doubleXpExpiresAt = DateTime.now().add(duration);
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Gems / Lingots
  // ---------------------------------------------------------------------

  void addGems(int amount) {
    if (amount <= 0) return;
    _gems += amount;
    _persist();
    notifyListeners();
  }

  bool spendGems(int amount) {
    if (amount <= 0 || _gems < amount) return false;
    _gems -= amount;
    _persist();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------
  // Streaks
  // ---------------------------------------------------------------------

  void grantStreakFreeze() {
    _streakFreezes += 1;
    _persist();
    notifyListeners();
  }

  /// Call once per completed lesson. Handles same-day idempotency,
  /// consecutive-day increments, a single-freeze-protected gap, and a
  /// hard reset when the streak has genuinely lapsed.
  void recordActivityForToday() {
    final now = DateTime.now();
    final today = _dateKey(now);

    if (_activeDates.contains(today)) return;

    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final twoDaysAgo = _dateKey(now.subtract(const Duration(days: 2)));

    if (_activeDates.isEmpty) {
      _streakCount = 1;
    } else if (_activeDates.contains(yesterday)) {
      _streakCount += 1;
    } else if (_streakFreezes > 0 && _activeDates.contains(twoDaysAgo)) {
      _streakFreezes -= 1;
      _streakCount += 1;
    } else {
      _streakCount = 1;
    }

    _activeDates.add(today);
    _lastActiveDate = now;
    _persist();
    notifyListeners();
  }

  /// Last [n] days, oldest first, as active/inactive booleans — feeds the
  /// weekly calendar strip on the Progress screen.
  List<bool> lastNDaysActivity(int n) {
    final now = DateTime.now();
    return List<bool>.generate(n, (i) {
      final day = now.subtract(Duration(days: n - 1 - i));
      return _activeDates.contains(_dateKey(day));
    });
  }

  // ---------------------------------------------------------------------
  // Course direction
  // ---------------------------------------------------------------------

  /// Called from the onboarding screen: records the child's language and
  /// marks onboarding done.
  void completeOnboarding(UiLang lang) {
    _uiLang = lang;
    _hasOnboarded = true;
    _persist();
    notifyListeners();
  }

  /// Change the interface language later (from the Profile screen).
  void setUiLang(UiLang lang) {
    if (_uiLang == lang) return;
    _uiLang = lang;
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------

  void _persist() {
    _box.put('hearts', _hearts);
    _box.put('xp', _xp);
    _box.put('gems', _gems);
    _box.put('streakCount', _streakCount);
    _box.put('streakFreezes', _streakFreezes);
    _box.put('lastActiveDate', _lastActiveDate?.toIso8601String());
    _box.put('nextHeartRefillAt', _nextHeartRefillAt?.toIso8601String());
    _box.put('doubleXpExpiresAt', _doubleXpExpiresAt?.toIso8601String());
    _box.put('activeDates', _activeDates.toList());
    _box.put('uiLang', _uiLang.name);
    _box.put('hasOnboarded', _hasOnboarded);
  }
}
