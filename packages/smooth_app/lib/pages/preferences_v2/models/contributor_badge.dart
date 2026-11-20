enum ContributorBadgeTier {
  bronze,
  silver,
  gold,
}

class ContributorBadgeProgress {
  const ContributorBadgeProgress(
    this.count, {
    this.bronzeThreshold = defaultBronzeThreshold,
    this.silverThreshold = defaultSilverThreshold,
    this.goldThreshold = defaultGoldThreshold,
  });

  static const int defaultBronzeThreshold = 1;
  static const int defaultSilverThreshold = 10;
  static const int defaultGoldThreshold = 100;

  final int count;
  final int bronzeThreshold;
  final int silverThreshold;
  final int goldThreshold;

  ContributorBadgeTier? get tier {
    if (count >= goldThreshold) {
      return ContributorBadgeTier.gold;
    }
    if (count >= silverThreshold) {
      return ContributorBadgeTier.silver;
    }
    if (count >= bronzeThreshold) {
      return ContributorBadgeTier.bronze;
    }
    return null;
  }

  ContributorBadgeTier? get nextTier {
    switch (tier) {
      case null:
        return ContributorBadgeTier.bronze;
      case ContributorBadgeTier.bronze:
        return ContributorBadgeTier.silver;
      case ContributorBadgeTier.silver:
        return ContributorBadgeTier.gold;
      case ContributorBadgeTier.gold:
        return null;
    }
  }

  int? get nextThreshold {
    switch (nextTier) {
      case null:
        return null;
      case ContributorBadgeTier.bronze:
        return bronzeThreshold;
      case ContributorBadgeTier.silver:
        return silverThreshold;
      case ContributorBadgeTier.gold:
        return goldThreshold;
    }
  }

  double get progress {
    final int? threshold = nextThreshold;
    if (threshold == null) {
      return 1.0;
    }
    if (threshold <= 0) {
      return 0.0;
    }
    return (count / threshold).clamp(0.0, 1.0);
  }
}
