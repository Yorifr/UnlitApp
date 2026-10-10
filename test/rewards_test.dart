import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/quests.dart';
import 'package:unlit/logic/rewards.dart';
import 'package:unlit/models/activity_log.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';

XpEntry xpAt(DateTime t, [XpReason r = XpReason.questCheckIn]) =>
    XpEntry(time: t, amount: 10, reason: r);

void main() {
  // Takip 1 Ekim'de başladı; ölçüm haftası 1–7 Ekim.
  final start = DateTime(2026, 10, 1, 9);

  group('görevler', () {
    test('ölçüm haftasında erteleme görevi yok', () {
      expect(isMeasurementDay(DateTime(2026, 10, 7, 23), start), isTrue);
      expect(isMeasurementDay(DateTime(2026, 10, 8), start), isFalse);
      expect(measurementDayNumber(DateTime(2026, 10, 3), start), 3);
      expect(measurementDayNumber(DateTime(2026, 10, 9), start), isNull);

      expect(questsForDay(DateTime(2026, 10, 3), trackingStart: start), [
        QuestType.checkIn,
        QuestType.tagTrigger,
        QuestType.breathe,
      ]);
      final after = questsForDay(DateTime(2026, 10, 10), trackingStart: start);
      expect(after, contains(QuestType.delay));
      expect(after.length, 3);
    });

    test('ilerleme o güne ait kayıtlardan hesaplanır', () {
      final day = DateTime(2026, 10, 10);
      final activity = ActivityLog(
        moods: [MoodEntry(time: DateTime(2026, 10, 10, 9), mood: Mood.good)],
        delays: [
          DelayAttempt(
            start: DateTime(2026, 10, 9, 12),
            end: DateTime(2026, 10, 9, 12, 10),
            outcome: DelayOutcome.success,
          ), // dün → sayılmaz
          DelayAttempt(
            start: DateTime(2026, 10, 10, 12),
            end: DateTime(2026, 10, 10, 12, 4),
            outcome: DelayOutcome.gaveIn,
          ), // başarılı değil → sayılmaz
        ],
      );
      final events = [
        SmokingEvent(
          time: DateTime(2026, 10, 10, 8),
          source: EventSource.demo,
          trigger: SmokingTrigger.coffee,
        ),
        SmokingEvent(time: DateTime(2026, 10, 10, 9), source: EventSource.demo),
      ];
      int p(QuestType t) =>
          questProgress(t, day: day, events: events, activity: activity);
      expect(p(QuestType.checkIn), 1);
      expect(p(QuestType.tagTrigger), 1);
      expect(p(QuestType.breathe), 0);
      expect(p(QuestType.delay), 0);
    });
  });

  group('ödüller', () {
    test('tamamlanan görev aynı gün bir kez ödüllendirilir', () {
      final now = DateTime(2026, 10, 3, 10);
      final activity = ActivityLog(
        moods: [MoodEntry(time: now, mood: Mood.good)],
      );
      final first = pendingQuestRewards(
        now: now,
        trackingStart: start,
        events: [],
        activity: activity,
      );
      expect(first.map((g) => g.reason), [XpReason.questCheckIn]);
      expect(first.single.amount, xpPerQuest);

      activity.xp.addAll(first);
      final second = pendingQuestRewards(
        now: now,
        trackingStart: start,
        events: [],
        activity: activity,
      );
      expect(second, isEmpty);
    });

    test('üç görev de bitince bonus gelir', () {
      final now = DateTime(2026, 10, 3, 20);
      final activity = ActivityLog(
        moods: [MoodEntry(time: now, mood: Mood.okay)],
        breaths: [now],
      );
      final events = [
        SmokingEvent(
          time: now,
          source: EventSource.demo,
          trigger: SmokingTrigger.stress,
        ),
      ];
      final gains = pendingQuestRewards(
        now: now,
        trackingStart: start,
        events: events,
        activity: activity,
      );
      expect(gains.length, 4); // 3 görev + bonus
      expect(gains.last.reason, XpReason.allQuests);
      expect(gains.fold(0, (s, g) => s + g.amount), 3 * xpPerQuest + 20);
    });

    test('erteleme ödülünün günlük sınırı var', () {
      final now = DateTime(2026, 10, 10, 12);
      final activity = ActivityLog(
        xp: [
          for (var i = 0; i < maxDelayRewardsPerDay; i++)
            XpEntry(time: now, amount: 15, reason: XpReason.delaySuccess),
        ],
      );
      expect(canRewardDelay(activity, now), isFalse);
      expect(canRewardDelay(activity, DateTime(2026, 10, 11)), isTrue);
    });
  });

  group('seri', () {
    final today = DateTime(2026, 10, 10, 15);

    test('ardışık günler seriyi büyütür', () {
      final xp = [for (var d = 6; d <= 10; d++) xpAt(DateTime(2026, 10, d))];
      final s = computeStreak(xp, today);
      expect(s.current, 5);
      expect(s.best, 5);
      expect(s.activeToday, isTrue);
    });

    test('bugün henüz bir şey yapılmadıysa seri bozulmaz', () {
      final xp = [for (var d = 6; d <= 9; d++) xpAt(DateTime(2026, 10, d))];
      final s = computeStreak(xp, today);
      expect(s.current, 4);
      expect(s.activeToday, isFalse);
    });

    test('tek kaçırılan gün "dinlenme günü" ile affedilir', () {
      final xp = [
        xpAt(DateTime(2026, 10, 6)),
        xpAt(DateTime(2026, 10, 7)),
        // 8 Ekim kaçırıldı
        xpAt(DateTime(2026, 10, 9)),
        xpAt(DateTime(2026, 10, 10)),
      ];
      expect(computeStreak(xp, today).current, 4);
    });

    test('art arda iki gün kaçırılırsa seri yeniden başlar', () {
      final xp = [
        xpAt(DateTime(2026, 10, 5)),
        xpAt(DateTime(2026, 10, 6)),
        // 7 ve 8 Ekim kaçırıldı
        xpAt(DateTime(2026, 10, 9)),
        xpAt(DateTime(2026, 10, 10)),
      ];
      final s = computeStreak(xp, today);
      expect(s.current, 2);
      expect(s.best, 2);
    });

    test('aynı hafta içinde ikinci kaçırma seriyi sıfırlar', () {
      final xp = [
        xpAt(DateTime(2026, 10, 3)),
        // 4 Ekim kaçırıldı (dinlenme günü)
        xpAt(DateTime(2026, 10, 5)),
        xpAt(DateTime(2026, 10, 6)),
        // 7 Ekim kaçırıldı (7 gün dolmadı → seri sıfırlanır)
        xpAt(DateTime(2026, 10, 8)),
        xpAt(DateTime(2026, 10, 9)),
      ];
      final s = computeStreak(xp, today);
      expect(s.current, 2);
      expect(s.best, 3);
    });

    test('hiç XP yoksa seri 0', () {
      final s = computeStreak([], today);
      expect(s.current, 0);
      expect(s.best, 0);
    });
  });
}
