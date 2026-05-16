import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/colors.dart';

// Maps OpenWeatherMap condition codes to Material Symbols icons and accent colors.
// Amber = warm/clear/solar. Cyan = rain/cold/moisture. Grey = overcast/neutral.
//
// OWM code ranges:
//   2xx  Thunderstorm
//   3xx  Drizzle
//   5xx  Rain
//   6xx  Snow
//   7xx  Atmosphere (mist, smoke, haze, fog, dust, tornado…)
//   800  Clear sky
//   80x  Clouds
class WeatherIconMapper {
  WeatherIconMapper._();

  static IconData iconFor(int conditionId, {bool isDay = true}) {
    if (conditionId >= 200 && conditionId < 300) return Symbols.thunderstorm;
    if (conditionId >= 300 && conditionId < 400) return Symbols.rainy;
    if (conditionId >= 500 && conditionId < 600) {
      if (conditionId >= 511) return Symbols.weather_mix; // freezing/heavy
      return Symbols.rainy;
    }
    if (conditionId >= 600 && conditionId < 700) return Symbols.weather_snowy;
    if (conditionId >= 700 && conditionId < 800) return Symbols.foggy;
    if (conditionId == 800) return isDay ? Symbols.light_mode : Symbols.bedtime;
    if (conditionId == 801) {
      return isDay ? Symbols.partly_cloudy_day : Symbols.partly_cloudy_night;
    }
    if (conditionId >= 802) return Symbols.cloud;
    return Symbols.cloud;
  }

  static Color colorFor(int conditionId) {
    if (conditionId == 800 || conditionId == 801) return TemporaColors.amber;
    if (conditionId >= 200 && conditionId < 600) return TemporaColors.cyan;
    if (conditionId >= 600 && conditionId < 700) return Colors.white70;
    return TemporaColors.onSurfaceVariant;
  }

  // Glow shadow colour for the icon drop-shadow effect
  static Color glowFor(int conditionId, {bool isDay = true}) {
    if (conditionId == 800 || conditionId == 801) {
      return isDay ? TemporaColors.amberGlow : TemporaColors.primaryBlueGlow;
    }
    if (conditionId >= 200 && conditionId < 600) return TemporaColors.cyanGlow;
    if (conditionId >= 600 && conditionId < 700) return const Color(0x4DB8D4F0);
    if (conditionId >= 700 && conditionId < 800) return const Color(0x4D8898A8);
    return const Color(0x4D4A6A8A);
  }
}
