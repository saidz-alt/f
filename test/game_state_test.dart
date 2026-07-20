import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kabyle_duo/services/game_state_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kabyle_duo_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('GameStateProvider', () {
    test('starts with full hearts, starting gems, zero XP', () async {
      final g = GameStateProvider();
      await g.init();
      expect(g.hearts, kMaxHearts);
      expect(g.gems, kStartingGems);
      expect(g.xp, 0);
      expect(g.streakCount, 0);
    });

    test('losing hearts floors at zero and sets a refill time', () async {
      final g = GameStateProvider();
      await g.init();
      for (var i = 0; i < 7; i++) {
        g.loseHeart();
      }
      expect(g.hearts, 0);
      expect(g.nextHeartRefillAt, isNotNull);
    });

    test('XP accrues and levels up every 100 XP', () async {
      final g = GameStateProvider();
      await g.init();
      g.addXp(250);
      expect(g.xp, 250);
      expect(g.level, 3); // (250 ~/ 100) + 1
      expect(g.xpIntoCurrentLevel, 50);
    });

    test('spending gems is guarded by balance', () async {
      final g = GameStateProvider();
      await g.init();
      expect(g.spendGems(999999), isFalse);
      expect(g.gems, kStartingGems);
      expect(g.spendGems(10), isTrue);
      expect(g.gems, kStartingGems - 10);
    });

    test('first activity starts a 1-day streak; same day is idempotent',
        () async {
      final g = GameStateProvider();
      await g.init();
      g.recordActivityForToday();
      expect(g.streakCount, 1);
      g.recordActivityForToday();
      expect(g.streakCount, 1); // no double-count within a day
    });

    test('state persists across a re-open of the box', () async {
      final g1 = GameStateProvider();
      await g1.init();
      g1.addXp(70);
      g1.addGems(25);
      // Close so the second instance re-reads from disk.
      await Hive.close();
      Hive.init(tempDir.path);

      final g2 = GameStateProvider();
      await g2.init();
      expect(g2.xp, 70);
      expect(g2.gems, kStartingGems + 25);
    });
  });
}
