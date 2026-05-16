import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/storage/unit_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/temp_formatter.dart';
import '../../../../core/utils/weather_icon_mapper.dart';
import '../../../../core/utils/weather_illustration_mapper.dart';
import '../../../../core/widgets/retry_error_card.dart';
import '../../../../core/widgets/top_app_bar.dart';
import '../../../../core/widgets/weather_background.dart';
import '../../domain/weather_entity.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_metrics_grid.dart';
import '../../../search_location/presentation/widgets/add_city_modal.dart';

class MainWeatherScreen extends ConsumerWidget {
  const MainWeatherScreen({super.key});

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
          : _CityWeather(cityName: city),
    );
  }
}

// ─── City weather — resolves async state ─────────────────────────────────────

class _CityWeather extends ConsumerWidget {
  const _CityWeather({required this.cityName});
  final String cityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider(cityName));

    return weatherAsync.when(
      loading: () => const _LoadingBody(),
      error: (e, _) {
        final topPad = MediaQuery.of(context).padding.top + 56 + 8;
        return Padding(
          padding: EdgeInsets.only(top: topPad, left: 20, right: 20),
          child: RetryErrorCard(
            message: e.toString(),
            onRetry: () => ref.invalidate(currentWeatherProvider(cityName)),
          ),
        );
      },
      data: (weather) => _WeatherBody(weather: weather),
    );
  }
}

// ─── Data state ───────────────────────────────────────────────────────────────

class _WeatherBody extends ConsumerWidget {
  const _WeatherBody({required this.weather});
  final WeatherEntity weather;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top + 56 + 8;
    final unit = ref.watch(temperatureUnitProvider);
    final isDay = weather.observedAt.isAfter(weather.sunrise) &&
        weather.observedAt.isBefore(weather.sunset);
    final glowColor = WeatherIconMapper.glowFor(weather.conditionId, isDay: isDay);

    return WeatherBackground(
      accentColor: glowColor,
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
            _HeroSection(weather: weather, unit: unit),
            const SizedBox(height: 24),
            WeatherMetricsGrid(weather: weather, unit: unit),
          ],
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.weather, required this.unit});
  final WeatherEntity weather;
  final TemperatureUnit unit;

  bool get _isDay {
    final now = weather.observedAt;
    return now.isAfter(weather.sunrise) && now.isBefore(weather.sunset);
  }

  @override
  Widget build(BuildContext context) {
    final illustrationPath = WeatherIllustrationMapper.assetFor(
      weather.conditionId,
      isDay: _isDay,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: text info ──────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // City name + location icon
              Row(
                children: [
                  Icon(
                    Symbols.location_on,
                    size: 14,
                    color: TemporaColors.onSurfaceVariant,
                    weight: 200,
                    fill: 0,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      weather.cityName,
                      style: TemporaTextStyles.headingLg().copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Temperature
              Text(
                TempFormatter.format(weather.temperature, unit),
                style: TemporaTextStyles.dataHuge(),
              ),

              // Condition
              Text(
                weather.condition,
                style: TemporaTextStyles.bodyMd(
                  color: TemporaColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),

              // High / Low + Feels like
              Text(
                '${TempFormatter.format(weather.tempMax, unit)} / ${TempFormatter.format(weather.tempMin, unit)}  '
                'Feels like ${TempFormatter.format(weather.feelsLike, unit)}',
                style: TemporaTextStyles.dataMono(
                  color: TemporaColors.onSurface,
                ).copyWith(fontSize: 13),
              ),

              const SizedBox(height: 12),
              // Date
              Text(
                DateFormatter.dayAndDate(weather.observedAt),
                style: TemporaTextStyles.dataMono(),
              ),
            ],
          ),
        ),

        // ── Right: SVG illustration ──────────────────────────────────────
        SizedBox(
          width: 150,
          height: 180,
          child: SvgPicture.asset(
            illustrationPath,
            fit: BoxFit.contain,
          ),
        ),
      ],
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 160, height: 22),
                      const SizedBox(height: 16),
                      _ShimmerBox(width: 110, height: 64),
                      const SizedBox(height: 8),
                      _ShimmerBox(width: 80, height: 16),
                      const SizedBox(height: 10),
                      _ShimmerBox(width: 180, height: 14),
                    ],
                  ),
                ),
                _ShimmerBox(width: 150, height: 160),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _ShimmerBox(height: 100)),
                const SizedBox(width: 12),
                Expanded(child: _ShimmerBox(height: 100)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ShimmerBox(height: 100)),
                const SizedBox(width: 12),
                Expanded(child: _ShimmerBox(height: 100)),
              ],
            ),
            const SizedBox(height: 12),
            _ShimmerBox(height: 96),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width, required this.height});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
