import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/storage/unit_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/temp_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/weather_entity.dart';

class WeatherMetricsGrid extends StatelessWidget {
  const WeatherMetricsGrid({super.key, required this.weather, required this.unit});

  final WeatherEntity weather;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Feels Like (full width)
        _FeelsLikeCard(weather: weather, unit: unit),
        const SizedBox(height: 12),

        // Row 2: UV Index + Humidity
        Row(
          children: [
            Expanded(child: _UvIndexCard(weather: weather)),
            const SizedBox(width: 12),
            Expanded(child: _HumidityCard(weather: weather, unit: unit)),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Dew Point + Wind
        Row(
          children: [
            Expanded(child: _DewPointCard(weather: weather, unit: unit)),
            const SizedBox(width: 12),
            Expanded(child: _WindCard(weather: weather)),
          ],
        ),
        const SizedBox(height: 12),

        // Row 4: Visibility + Pressure
        Row(
          children: [
            Expanded(child: _VisibilityCard(weather: weather)),
            const SizedBox(width: 12),
            Expanded(child: _PressureCard(weather: weather)),
          ],
        ),
        const SizedBox(height: 12),

        // Sunrise / Sunset arc card
        _SunriseCard(weather: weather),
      ],
    );
  }
}

// ─── Feels Like (full-width) ──────────────────────────────────────────────────

class _FeelsLikeCard extends StatelessWidget {
  const _FeelsLikeCard({required this.weather, required this.unit});
  final WeatherEntity weather;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    final range = weather.tempMax - weather.tempMin;
    final progress = range > 0
        ? ((weather.feelsLike - weather.tempMin) / range).clamp(0.0, 1.0)
        : 0.5;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Symbols.device_thermostat,
                    size: 16,
                    color: TemporaColors.amber,
                    weight: 200,
                    fill: 0,
                  ),
                  const SizedBox(width: 6),
                  Text('FEELS LIKE', style: TemporaTextStyles.labelCaps()),
                ],
              ),
              Text(
                _feelsLikeLabel(weather.feelsLike),
                style: TemporaTextStyles.dataMono(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TempFormatter.format(weather.feelsLike, unit),
                style: TemporaTextStyles.headingLg(),
              ),
              const Spacer(),
              Text(
                'Lo ${TempFormatter.format(weather.tempMin, unit)}',
                style: TemporaTextStyles.dataMono(),
              ),
              const SizedBox(width: 8),
              Text(
                'Hi ${TempFormatter.format(weather.tempMax, unit)}',
                style: TemporaTextStyles.dataMono(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 3, color: Colors.white.withAlpha(20)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TemporaColors.cyan, TemporaColors.amber],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _feelsLikeLabel(double temp) {
    if (temp >= 40) return 'Very Hot';
    if (temp >= 32) return 'Hot';
    if (temp >= 24) return 'Warm';
    if (temp >= 16) return 'Comfortable';
    if (temp >= 8) return 'Cool';
    return 'Cold';
  }
}

// ─── UV Index ─────────────────────────────────────────────────────────────────

class _UvIndexCard extends StatelessWidget {
  const _UvIndexCard({required this.weather});
  final WeatherEntity weather;

  String get _uvLabel {
    final h = weather.observedAt.hour;
    final isDay = h >= 6 && h < 20;
    if (!isDay) return 'Low';
    // Approximate UV from condition
    final id = weather.conditionId;
    if (id == 800) return 'High';
    if (id >= 801 && id <= 802) return 'Moderate';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UV INDEX', style: TemporaTextStyles.labelCaps()),
              const Icon(
                Symbols.sunny,
                size: 16,
                color: TemporaColors.amber,
                weight: 200,
                fill: 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_uvLabel, style: TemporaTextStyles.headingLg()),
          const SizedBox(height: 4),
          Text(
            'Current index',
            style: TemporaTextStyles.dataMono(),
          ),
        ],
      ),
    );
  }
}

// ─── Humidity ─────────────────────────────────────────────────────────────────

class _HumidityCard extends StatelessWidget {
  const _HumidityCard({required this.weather, required this.unit});
  final WeatherEntity weather;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HUMIDITY', style: TemporaTextStyles.labelCaps()),
              const Icon(
                Symbols.humidity_percentage,
                size: 16,
                color: TemporaColors.cyan,
                weight: 200,
                fill: 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${weather.humidity}%',
            style: TemporaTextStyles.headingLg(),
          ),
          const SizedBox(height: 4),
          Text(
            _humidityLabel(weather.humidity),
            style: TemporaTextStyles.dataMono(),
          ),
        ],
      ),
    );
  }

  String _humidityLabel(int h) {
    if (h >= 80) return 'Very humid';
    if (h >= 60) return 'Humid';
    if (h >= 40) return 'Comfortable';
    return 'Dry';
  }
}

// ─── Dew Point ────────────────────────────────────────────────────────────────

class _DewPointCard extends StatelessWidget {
  const _DewPointCard({required this.weather, required this.unit});
  final WeatherEntity weather;
  final TemperatureUnit unit;

  @override
  Widget build(BuildContext context) {
    final dew = weather.temperature - ((100 - weather.humidity) / 5);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DEW POINT', style: TemporaTextStyles.labelCaps()),
              const Icon(
                Symbols.water_drop,
                size: 16,
                color: TemporaColors.cyan,
                weight: 200,
                fill: 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            TempFormatter.format(dew, unit),
            style: TemporaTextStyles.headingLg(),
          ),
          const SizedBox(height: 4),
          Text(
            dew > 20 ? 'Muggy' : dew > 13 ? 'Comfortable' : 'Dry',
            style: TemporaTextStyles.dataMono(),
          ),
        ],
      ),
    );
  }
}

// ─── Wind ─────────────────────────────────────────────────────────────────────

class _WindCard extends StatelessWidget {
  const _WindCard({required this.weather});
  final WeatherEntity weather;

  @override
  Widget build(BuildContext context) {
    final dir = DateFormatter.windDirection(weather.windDeg);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WIND', style: TemporaTextStyles.labelCaps()),
              const Icon(
                Symbols.air,
                size: 16,
                color: TemporaColors.primaryBlue,
                weight: 200,
                fill: 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: weather.windSpeedKmh.toStringAsFixed(0),
                  style: TemporaTextStyles.headingLg(),
                ),
                TextSpan(
                  text: ' km/h',
                  style: TemporaTextStyles.dataMono(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$dir wind',
            style: TemporaTextStyles.dataMono(),
          ),
        ],
      ),
    );
  }
}

// ─── Visibility ───────────────────────────────────────────────────────────────

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.weather});
  final WeatherEntity weather;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VISIBILITY', style: TemporaTextStyles.labelCaps()),
              const Icon(
                Symbols.visibility,
                size: 16,
                color: TemporaColors.onSurfaceVariant,
                weight: 200,
                fill: 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: weather.visibilityKm.toStringAsFixed(2),
                  style: TemporaTextStyles.headingLg(),
                ),
                TextSpan(
                  text: ' km',
                  style: TemporaTextStyles.dataMono(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weather.visibilityKm >= 10 ? 'Clear' : 'Reduced',
            style: TemporaTextStyles.dataMono(),
          ),
        ],
      ),
    );
  }
}

// ─── Pressure ─────────────────────────────────────────────────────────────────

class _PressureCard extends StatelessWidget {
  const _PressureCard({required this.weather});
  final WeatherEntity weather;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRESSURE', style: TemporaTextStyles.labelCaps()),
              const Icon(
                Symbols.speed,
                size: 16,
                color: TemporaColors.onSurfaceVariant,
                weight: 200,
                fill: 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: weather.pressure.toString(),
                  style: TemporaTextStyles.headingLg(),
                ),
                TextSpan(
                  text: ' mb',
                  style: TemporaTextStyles.dataMono(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weather.pressure >= 1013 ? 'High' : 'Low',
            style: TemporaTextStyles.dataMono(),
          ),
        ],
      ),
    );
  }
}

// ─── Sunrise / Sunset arc card ────────────────────────────────────────────────

class _SunriseCard extends StatelessWidget {
  const _SunriseCard({required this.weather});
  final WeatherEntity weather;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Symbols.wb_twilight,
                    size: 16,
                    color: TemporaColors.amber,
                    weight: 200,
                    fill: 0,
                  ),
                  const SizedBox(width: 6),
                  Text('SUNRISE / SUNSET', style: TemporaTextStyles.labelCaps()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Arc painter
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SunArcPainter(
                sunrise: weather.sunrise,
                sunset: weather.sunset,
                current: weather.observedAt,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sunrise', style: TemporaTextStyles.dataMono()),
                  Text(
                    DateFormatter.timeLabel12h(weather.sunrise),
                    style: TemporaTextStyles.headingLg().copyWith(fontSize: 18),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Sunset', style: TemporaTextStyles.dataMono()),
                  Text(
                    DateFormatter.timeLabel12h(weather.sunset),
                    style: TemporaTextStyles.headingLg().copyWith(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SunArcPainter extends CustomPainter {
  const _SunArcPainter({
    required this.sunrise,
    required this.sunset,
    required this.current,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime current;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;

    // Track arc
    final trackPaint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // Progress along arc
    final totalSecs = sunset.difference(sunrise).inSeconds.toDouble();
    final elapsed = current.difference(sunrise).inSeconds.toDouble();
    final progress = (elapsed / totalSecs).clamp(0.0, 1.0);

    if (progress > 0) {
      // Lighter gold for the arc line
      const arcColor = Color(0xFFFFD54F);

      final progressPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * progress,
        false,
        progressPaint,
      );

      // Sun dot — smaller and softer glow
      final angle = math.pi + math.pi * progress;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(dx, dy),
        7,
        Paint()
          ..color = const Color(0x334D9DE0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(dx, dy),
        5,
        Paint()..color = arcColor,
      );
    }

    // Horizon line
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = Colors.white.withAlpha(15)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.current != current;
}
