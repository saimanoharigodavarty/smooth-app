import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/data_models/preferences/user_preferences.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/generic_lib/widgets/smooth_card.dart';
import 'package:smooth_app/l10n/app_localizations.dart';
import 'package:smooth_app/pages/preferences/lazy_counter.dart';
import 'package:smooth_app/pages/preferences_v2/models/contributor_badge.dart';
import 'package:smooth_app/query/paged_user_product_query.dart';
import 'package:smooth_app/query/product_query.dart';
import 'package:smooth_app/resources/app_icons.dart' as icons;
import 'package:smooth_app/themes/smooth_theme_colors.dart';

class ContributorDashboard extends StatefulWidget {
  const ContributorDashboard({
    this.onProductFinderTap,
    this.onDataCheckerTap,
    this.onPhotographerTap,
    super.key,
  });

  final VoidCallback? onProductFinderTap;
  final VoidCallback? onDataCheckerTap;
  final VoidCallback? onPhotographerTap;

  @override
  State<ContributorDashboard> createState() => _ContributorDashboardState();
}

class _ContributorDashboardState extends State<ContributorDashboard> {
  static const Map<ContributorBadgeType, LazyCounter> _counters =
      <ContributorBadgeType, LazyCounter>{
        ContributorBadgeType.productFinder: LazyCounterUserSearch(
          UserSearchType.CONTRIBUTOR,
        ),
        ContributorBadgeType.dataChecker: LazyCounterUserSearch(
          UserSearchType.INFORMER,
        ),
        ContributorBadgeType.photographer: LazyCounterUserSearch(
          UserSearchType.PHOTOGRAPHER,
        ),
      };

  final Map<ContributorBadgeType, int?> _counts =
      <ContributorBadgeType, int?>{};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadCounts());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context);
    final List<_ContributorBadgeData> badges = _getBadges(appLocalizations);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        MEDIUM_SPACE,
        MEDIUM_SPACE,
        MEDIUM_SPACE,
        0.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  appLocalizations.preferences_contributor_dashboard_summary,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: appLocalizations.label_reload,
                onPressed: _loading ? null : _loadCounts,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryValue(
                  label: appLocalizations
                      .preferences_contributor_dashboard_summary_added,
                  value: _counts[ContributorBadgeType.productFinder],
                ),
              ),
              const SizedBox(width: SMALL_SPACE),
              Expanded(
                child: _SummaryValue(
                  label: appLocalizations
                      .preferences_contributor_dashboard_summary_edited,
                  value: _counts[ContributorBadgeType.dataChecker],
                ),
              ),
              const SizedBox(width: SMALL_SPACE),
              Expanded(
                child: _SummaryValue(
                  label: appLocalizations
                      .preferences_contributor_dashboard_summary_photos,
                  value: _counts[ContributorBadgeType.photographer],
                ),
              ),
            ],
          ),
          const SizedBox(height: MEDIUM_SPACE),
          Text(
            appLocalizations.preferences_contributor_dashboard_badges,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: SMALL_SPACE),
          ...badges.map(
            (_ContributorBadgeData badge) {
              VoidCallback? onTap;
              switch (badge.type) {
                case ContributorBadgeType.productFinder:
                  onTap = widget.onProductFinderTap;
                  break;
                case ContributorBadgeType.dataChecker:
                  onTap = widget.onDataCheckerTap;
                  break;
                case ContributorBadgeType.photographer:
                  onTap = widget.onPhotographerTap;
                  break;
              }
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: SMALL_SPACE),
                child: _BadgeCard(
                  badge: badge,
                  count: _counts[badge.type],
                  loading: _loading && _counts[badge.type] == null,
                  onTap: onTap,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadCounts() async {
    if (_loading || !mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final UserPreferences userPreferences = context.read<UserPreferences>();
    final bool isLoggedIn = ProductQuery.isLoggedIn();

    final Map<ContributorBadgeType, int?> localCounts =
        <ContributorBadgeType, int?>{
          for (final MapEntry<ContributorBadgeType, LazyCounter> entry
              in _counters.entries)
            entry.key:
                entry.value.getLocalCount(userPreferences) ??
                (!isLoggedIn ? 0 : null),
        };

    if (mounted) {
      setState(() {
        _counts.addAll(localCounts);
      });
    }

    if (!isLoggedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    final Map<ContributorBadgeType, int?> serverCounts =
        <ContributorBadgeType, int?>{};
    await Future.wait(
      _counters.entries.map(
        (MapEntry<ContributorBadgeType, LazyCounter> entry) async {
          final int? count = await entry.value.getServerCount();
          serverCounts[entry.key] = count;
          if (count != null) {
            await entry.value.setLocalCount(
              count,
              userPreferences,
              notify: false,
            );
          }
        },
      ),
    );

    if (mounted) {
      setState(() {
        _counts.addAll(serverCounts);
        _loading = false;
      });
    }
  }

  List<_ContributorBadgeData> _getBadges(
    AppLocalizations appLocalizations,
  ) => <_ContributorBadgeData>[
    _ContributorBadgeData(
      type: ContributorBadgeType.productFinder,
      title: appLocalizations.preferences_contributor_dashboard_badge_finder,
      description:
          appLocalizations.preferences_contributions_new_products_subtitle,
      icon: const icons.Milk.happy(size: 22.0),
      counter: _counters[ContributorBadgeType.productFinder]!,
    ),
    _ContributorBadgeData(
      type: ContributorBadgeType.dataChecker,
      title: appLocalizations.preferences_contributor_dashboard_badge_checker,
      description: appLocalizations.preferences_contributor_dashboard_edited,
      icon: const icons.Changes(size: 22.0),
      counter: _counters[ContributorBadgeType.dataChecker]!,
    ),
    _ContributorBadgeData(
      type: ContributorBadgeType.photographer,
      title:
          appLocalizations.preferences_contributor_dashboard_badge_photographer,
      description: appLocalizations.preferences_contributor_dashboard_photos,
      icon: const icons.Camera.happy(size: 22.0),
      counter: _counters[ContributorBadgeType.photographer]!,
    ),
  ];
}

enum ContributorBadgeType {
  productFinder,
  dataChecker,
  photographer,
}

class _ContributorBadgeData {
  const _ContributorBadgeData({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.counter,
  });

  final ContributorBadgeType type;
  final String title;
  final String description;
  final Widget icon;
  final LazyCounter counter;
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return SmoothCard.flat(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SMALL_SPACE,
        vertical: SMALL_SPACE,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            (value ?? 0).toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: VERY_SMALL_SPACE),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.count,
    this.loading = false,
    this.onTap,
  });

  final _ContributorBadgeData badge;
  final int? count;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context);
    final int displayCount = count ?? 0;
    final ContributorBadgeProgress progress = ContributorBadgeProgress(
      displayCount,
    );
    final SmoothColorsThemeExtension colors = context
        .extension<SmoothColorsThemeExtension>();

    return SmoothCard.flat(
      padding: EdgeInsetsDirectional.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: ROUNDED_BORDER_RADIUS,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MEDIUM_SPACE),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: _getTierColor(progress.tier).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: badge.icon,
              ),
              const SizedBox(width: MEDIUM_SPACE),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            badge.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: SMALL_SPACE),
                        _TierBadgeChip(
                          tier: progress.tier,
                          label: _getTierLabel(progress.tier, appLocalizations),
                        ),
                      ],
                    ),
                    const SizedBox(height: VERY_SMALL_SPACE),
                    Text(
                      badge.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.primaryTone,
                      ),
                    ),
                    const SizedBox(height: SMALL_SPACE),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            loading
                                ? appLocalizations
                                      .preferences_contributor_dashboard_loading
                                : _getProgressLabel(
                                    progress,
                                    appLocalizations,
                                  ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          progress.nextThreshold != null
                              ? '$displayCount / ${progress.nextThreshold}'
                              : '$displayCount',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VERY_SMALL_SPACE),
                    ClipRRect(
                      borderRadius: ANGULAR_BORDER_RADIUS,
                      child: LinearProgressIndicator(
                        value: progress.progress,
                        minHeight: 6.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTierColor(progress.nextTier ?? progress.tier),
                        ),
                        backgroundColor: colors.greyLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProgressLabel(
    ContributorBadgeProgress progress,
    AppLocalizations appLocalizations,
  ) {
    final ContributorBadgeTier? tier = progress.tier;
    final ContributorBadgeTier? nextTier = progress.nextTier;
    if (nextTier == null) {
      return appLocalizations.preferences_contributor_dashboard_gold;
    }

    final String tierLabel = _getTierLabel(tier, appLocalizations);
    return appLocalizations.preferences_contributor_dashboard_next_level(
      tierLabel,
      _getTierLabel(nextTier, appLocalizations),
      progress.nextThreshold!,
    );
  }

  String _getTierLabel(
    ContributorBadgeTier? tier,
    AppLocalizations appLocalizations,
  ) {
    switch (tier) {
      case null:
        return appLocalizations.preferences_contributor_dashboard_locked;
      case ContributorBadgeTier.bronze:
        return appLocalizations.preferences_contributor_dashboard_bronze;
      case ContributorBadgeTier.silver:
        return appLocalizations.preferences_contributor_dashboard_silver;
      case ContributorBadgeTier.gold:
        return appLocalizations.preferences_contributor_dashboard_gold;
    }
  }

  Color _getTierColor(ContributorBadgeTier? tier) {
    switch (tier) {
      case null:
        return const Color(0xFF757575);
      case ContributorBadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case ContributorBadgeTier.silver:
        return const Color(0xFF8E9BAE);
      case ContributorBadgeTier.gold:
        return const Color(0xFFE5A100);
    }
  }
}

class _TierBadgeChip extends StatelessWidget {
  const _TierBadgeChip({
    required this.tier,
    required this.label,
  });

  final ContributorBadgeTier? tier;
  final String label;

  Color get _color {
    switch (tier) {
      case null:
        return const Color(0xFF757575);
      case ContributorBadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case ContributorBadgeTier.silver:
        return const Color(0xFF8E9BAE);
      case ContributorBadgeTier.gold:
        return const Color(0xFFE5A100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _color;
    final bool isLocked = tier == null;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SMALL_SPACE,
        vertical: VERY_SMALL_SPACE,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: CIRCULAR_BORDER_RADIUS,
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isLocked ? Icons.lock_outline : Icons.workspace_premium,
            size: 14.0,
            color: color,
          ),
          const SizedBox(width: VERY_SMALL_SPACE),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
