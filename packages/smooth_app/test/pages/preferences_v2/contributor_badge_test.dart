import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_app/pages/preferences_v2/models/contributor_badge.dart';

void main() {
  test('a badge starts locked and progresses toward bronze', () {
    const ContributorBadgeProgress progress = ContributorBadgeProgress(0);

    expect(progress.tier, isNull);
    expect(progress.nextTier, ContributorBadgeTier.bronze);
    expect(progress.nextThreshold, 1);
    expect(progress.progress, 0.0);
  });

  test('badge tiers advance at their thresholds', () {
    expect(
      const ContributorBadgeProgress(1).tier,
      ContributorBadgeTier.bronze,
    );
    expect(
      const ContributorBadgeProgress(10).tier,
      ContributorBadgeTier.silver,
    );
    expect(
      const ContributorBadgeProgress(100).tier,
      ContributorBadgeTier.gold,
    );
  });

  test('gold badges have complete progress and no next level', () {
    const ContributorBadgeProgress progress = ContributorBadgeProgress(150);

    expect(progress.nextTier, isNull);
    expect(progress.nextThreshold, isNull);
    expect(progress.progress, 1.0);
  });

  test('progress is capped at one', () {
    expect(const ContributorBadgeProgress(1000).progress, 1.0);
  });

  test('custom thresholds work as expected', () {
    const ContributorBadgeProgress progress = ContributorBadgeProgress(
      5,
      bronzeThreshold: 5,
      silverThreshold: 25,
      goldThreshold: 50,
    );
    expect(progress.tier, ContributorBadgeTier.bronze);
    expect(progress.nextTier, ContributorBadgeTier.silver);
    expect(progress.nextThreshold, 25);
    expect(progress.progress, 5 / 25);
  });
}
