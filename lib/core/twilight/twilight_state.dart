import 'dart:math';

import 'package:flutter/material.dart';

enum TwilightPhase { morning, day, twilight, night }

enum PandaMood { stretching, reading, sunset, sleeping, charging }

class TwilightState {
  static final anniversary = DateTime(2026, 2, 4);
  static const comfortMessages = [
    "I'm here.",
    "We'll get through today.",
    "You don't have to carry everything alone.",
  ];

  const TwilightState({
    required this.now,
    required this.phase,
    required this.twilightsTogether,
    required this.batteryLevel,
    required this.isCharging,
  });

  final DateTime now;
  final TwilightPhase phase;
  final int twilightsTogether;
  final int batteryLevel;
  final bool isCharging;

  factory TwilightState.from(DateTime now, {required int batteryLevel, required bool isCharging}) {
    return TwilightState(
      now: now,
      phase: phaseFor(now),
      twilightsTogether: countTwilightsTogether(now),
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );
  }

  static TwilightPhase phaseFor(DateTime now) {
    final hour = now.hour;
    if (hour >= 6 && hour <= 10) return TwilightPhase.morning;
    if (hour >= 11 && hour <= 16) return TwilightPhase.day;
    if (hour >= 17 && hour <= 19) return TwilightPhase.twilight;
    return TwilightPhase.night;
  }

  static int countTwilightsTogether(DateTime now) {
    final start = DateTime(anniversary.year, anniversary.month, anniversary.day);
    final today = DateTime(now.year, now.month, now.day);
    return max(1, today.difference(start).inDays + 1);
  }

  static DateTime nextBoundaryAfter(DateTime now) {
    final candidates = <DateTime>[
      DateTime(now.year, now.month, now.day, 6),
      DateTime(now.year, now.month, now.day, 11),
      DateTime(now.year, now.month, now.day, 17),
      DateTime(now.year, now.month, now.day, 20),
      DateTime(now.year, now.month, now.day + 1),
    ].where((candidate) => candidate.isAfter(now)).toList();

    candidates.sort();
    return candidates.first;
  }

  PandaMood get pandaMood {
    if (isCharging) return PandaMood.charging;
    return switch (phase) {
      TwilightPhase.morning => PandaMood.stretching,
      TwilightPhase.day => PandaMood.reading,
      TwilightPhase.twilight => PandaMood.sunset,
      TwilightPhase.night => PandaMood.sleeping,
    };
  }

  String get pandaLabel {
    return switch (pandaMood) {
      PandaMood.stretching => 'Stretching',
      PandaMood.reading => 'Reading',
      PandaMood.sunset => 'Watching the sunset',
      PandaMood.sleeping => 'Sleeping',
      PandaMood.charging => 'Holding a glowing star',
    };
  }

  String get comfortMessage {
    final index = (twilightsTogether + now.day + now.hour) % comfortMessages.length;
    return comfortMessages[index];
  }

  String get subtitle => 'Since 4 February 2026';

  String get phaseName {
    return switch (phase) {
      TwilightPhase.morning => 'Morning',
      TwilightPhase.day => 'Day',
      TwilightPhase.twilight => 'Twilight',
      TwilightPhase.night => 'Night',
    };
  }

  Color get backgroundTop {
    return switch (phase) {
      TwilightPhase.morning => const Color(0xFFFFE8C8),
      TwilightPhase.day => const Color(0xFFF6F0E3),
      TwilightPhase.twilight => const Color(0xFFFFB38A),
      TwilightPhase.night => const Color(0xFF201B3A),
    };
  }

  Color get backgroundBottom {
    return switch (phase) {
      TwilightPhase.morning => const Color(0xFFF9CBA7),
      TwilightPhase.day => const Color(0xFFEADFD0),
      TwilightPhase.twilight => const Color(0xFF7A4F7A),
      TwilightPhase.night => const Color(0xFF0F1023),
    };
  }

  Color get surfaceColor {
    return switch (phase) {
      TwilightPhase.morning => const Color(0xFFFFFCF8),
      TwilightPhase.day => const Color(0xFFFFFFFF),
      TwilightPhase.twilight => const Color(0xFFFFF3EE),
      TwilightPhase.night => const Color(0xFF231E34),
    };
  }

  Color get accentColor {
    return switch (phase) {
      TwilightPhase.morning => const Color(0xFFF5A469),
      TwilightPhase.day => const Color(0xFFCB8A5F),
      TwilightPhase.twilight => const Color(0xFFF2A17C),
      TwilightPhase.night => const Color(0xFFA8D3FF),
    };
  }

  Color get onSurfaceColor {
    return switch (phase) {
      TwilightPhase.night => const Color(0xFFF6F1FB),
      _ => const Color(0xFF2A201D),
    };
  }

  Color get glowColor {
    return switch (phase) {
      TwilightPhase.morning => const Color(0xFFFFC67A),
      TwilightPhase.day => const Color(0xFFFFE2AB),
      TwilightPhase.twilight => const Color(0xFFFFD18A),
      TwilightPhase.night => const Color(0xFF92C8FF),
    };
  }
}