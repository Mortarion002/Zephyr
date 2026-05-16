import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/weather_icon_mapper.dart';
import '../../../../core/storage/unit_provider.dart';
import '../../../../core/utils/temp_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/retry_error_card.dart';
import '../../../../core/widgets/top_app_bar.dart';
import '../../../../core/widgets/weather_background.dart';
import '../../domain/weather_entity.dart';
import '../providers/weather_provider.dart';
import '../../../search_location/presentation/widgets/add_city_modal.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);

    return Scaffold(
      backgroundColor: TemporaColors.background,
      extendBodyBehindAppBar: true,
      appBar: TemporaTopAppBar(
        onSearchTap: () => showAddCityModal(context),
        onAddTap: () => showAddCityModal(context),
      ),
      body: city == null
          ? const _EmptyState()
          : _CityForecast(cityName: city),
    );
  }
}

// ─── City forecast — resolves async state ─────────────────────────────────────

class _CityForecast extends ConsumerWidget {
  const _CityForecast({required this.cityName});
  final String cityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider(cityName));

    return forecastAsync.when(
      loading: () => const _LoadingBody(),
      error: (e, _) {
        final topPad = MediaQuery.of(context).padding.top + 56 + 8;
        return Padding(
          padding: EdgeInsets.only(top: topPad, left: 20, right: 20),
          child: RetryErrorCard(
            message: e.toString(),
            onRetry: () => ref.invalidate(forecastProvider(cityName)),
          ),
        );
      },
      data: (data) => _ForecastBody(hourly: data.hourly, daily: data.daily),
    );
  }
}

// ─── Data state ───────────────────────────────────────────────────────────────

class _ForecastBody extends ConsumerWidget {
  const _ForecastBody({required this.hourly, required this.daily});
  final List<HourlyForecastEntity> hourly;
  final List<DailyForecastEntity> daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top + 56 + 8;
    final unit = ref.watch(temperatureUnitProvider);

    // Tomorrow's high/low from daily list
    final hasTomorrow = daily.length >= 2;
    final tomorrow = hasTomorrow ? daily[1] : null;
    final today = daily.isNotEmpty ? daily[0] : null;
    final delta = (tomorrow != null && today != null)
        ? (tomorrow.tempHigh - today.tempHigh).round()
        : null;

    return WeatherBackground(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: topPad,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOURLY', style: TemporaTextStyles.labelCaps()),
            const SizedBox(height: 12),
            _HourlySection(hourly: hourly, unit: unit),

            // Tomorrow's Temperature banner
            if (delta != null) ...[
              const SizedBox(height: 16),
              _TomorrowBanner(delta: delta, tomorrow: tomorrow!),
            ],

            const SizedBox(height: 24),
            Text('10-DAY', style: TemporaTextStyles.labelCaps()),
            const SizedBox(height: 12),
            _DailySection(daily: daily, unit: unit),
          ],
        ),
      ),
    );
  }
}

// ─── Tomorrow's Temperature banner ────────────────────────────────────────────

class _TomorrowBanner extends StatelessWidget {
  const _TomorrowBanner({required this.delta, required this.tomorrow});
  final int delta;
  final DailyForecastEntity tomorrow;

  @override
  Widget build(BuildContext context) {
    final isWarmer = delta > 0;
    final deltaColor = isWarmer ? TemporaColors.amber : TemporaColors.cyan;
    final sign = delta >= 0 ? '+' : '';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Symbols.thermostat,
            size: 18,
            color: TemporaColors.amber,
            weight: 200,
            fill: 0,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tomorrow's Temperature",
                  style: TemporaTextStyles.dataMono(
                    color: TemporaColors.onSurface,
                  ),
                ),
                Text(
                  isWarmer
                      ? 'A little higher than today'
                      : 'A little lower than today',
                  style: TemporaTextStyles.dataMono().copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign$delta°',
            style: TemporaTextStyles.headingLg().copyWith(
              color: deltaColor,
              fontSize: 20,
            ),
          ),
          Icon(
            isWarmer ? Symbols.arrow_upward : Symbols.arrow_downward,
            size: 16,
            color: deltaColor,
          ),
        ],
      ),
    );
  }
}

// ─── Hourly section ───────────────────────────────────────────────────────────

class _HourlySection extends StatelessWidget {
  const _HourlySection({required this.hourly, required this.unit});
  final List<HourlyForecastEntity> hourly;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < hourly.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _HourlyTile(item: hourly[i], unit: unit),
            ],
          ],
        ),
      ),
    );
  }
}

class _HourlyTile extends StatelessWidget {
  const _HourlyTile({required this.item, required this.unit});
  final HourlyForecastEntity item;
  final TemperatureUnit unit;

  bool get _isDay {
    final h = item.time.hour;
    return h >= 6 && h < 20;
  }

  @override
  Widget build(BuildContext context) {
    final icon = WeatherIconMapper.iconFor(item.conditionId, isDay: _isDay);
    final iconColor = WeatherIconMapper.colorFor(item.conditionId);
    final pop = (item.precipitationProbability * 100).round();

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormatter.hourLabel(item.time),
            style: TemporaTextStyles.dataMono(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Icon(icon, size: 26, color: iconColor, weight: 200, fill: 0),
          const SizedBox(height: 10),
          Text(
            TempFormatter.format(item.temperature, unit),
            style: TemporaTextStyles.headingLg().copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            pop > 0 ? '$pop%' : '',
            style: TemporaTextStyles.dataMono(color: TemporaColors.cyan),
          ),
        ],
      ),
    );
  }
}

// ─── Daily section ────────────────────────────────────────────────────────────

class _DailySection extends StatelessWidget {
  const _DailySection({required this.daily, required this.unit});
  final List<DailyForecastEntity> daily;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < daily.length; i++) ...[
            _DailyTile(
              item: daily[i],
              unit: unit,
              isToday: i == 0,
            ),
            if (i < daily.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.white.withAlpha(15),
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({required this.item, required this.unit, this.isToday = false});
  final DailyForecastEntity item;
  final TemperatureUnit unit;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final icon = WeatherIconMapper.iconFor(item.conditionId);
    final iconColor = WeatherIconMapper.colorFor(item.conditionId);
    final dayLabel = isToday
        ? 'Today'
        : DateFormatter.shortDayCaps(item.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              dayLabel,
              style: TemporaTextStyles.dataMono(
                color: isToday
                    ? TemporaColors.onSurface
                    : TemporaColors.onSurfaceVariant,
              ).copyWith(fontWeight: isToday ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          Icon(icon, size: 22, color: iconColor, weight: 200, fill: 0),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.condition,
              style: TemporaTextStyles.dataMono(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // High temp
          Text(
            TempFormatter.format(item.tempHigh, unit),
            style: TemporaTextStyles.headingLg().copyWith(fontSize: 16),
          ),
          const SizedBox(width: 12),
          // Low temp (muted)
          SizedBox(
            width: 36,
            child: Text(
              TempFormatter.format(item.tempLow, unit),
              style: TemporaTextStyles.dataMono(),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading state (shimmer) ─────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 56 + 8;

    return Shimmer.fromColors(
      baseColor: TemporaColors.surfaceContainer,
      highlightColor: TemporaColors.surfaceContainerHigh,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: topPad,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimBox(width: 60, height: 12),
            const SizedBox(height: 12),
            _ShimBox(height: 110),
            const SizedBox(height: 24),
            _ShimBox(width: 50, height: 12),
            const SizedBox(height: 12),
            _ShimBox(height: 380),
          ],
        ),
      ),
    );
  }
}

class _ShimBox extends StatelessWidget {
  const _ShimBox({this.width, required this.height});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return WeatherBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 180,
              child: SvgPicture.asset(
                'assets/illustrations/forecast.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO LOCATION SET',
              style: TemporaTextStyles.labelCaps(
                color: TemporaColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first city',
              style: TemporaTextStyles.bodyMd(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
