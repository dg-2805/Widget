import 'dart:math';

import 'package:flutter/material.dart';

enum TwilightPhase { morning, day, twilight, night }

enum PandaMood { counting, daytime, afternoon, wishing, sleeping, celebrating, charging }

enum BackgroundScene { pandaCharging, celebration, pandaCount, pandaDay, afternoon, pandaWish, pandaNight }

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
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day, 0, 5),
      DateTime(now.year, now.month, now.day, 7),
      DateTime(now.year, now.month, now.day, 13),
      DateTime(now.year, now.month, now.day, 16),
      DateTime(now.year, now.month, now.day, 22),
      DateTime(now.year, now.month, now.day + 1),
    ].where((candidate) => candidate.isAfter(now)).toList();

    candidates.sort();
    return candidates.first;
  }

  PandaMood get pandaMood {
    if (isCharging) return PandaMood.charging;
    return switch (backgroundScene) {
      BackgroundScene.celebration => PandaMood.celebrating,
      BackgroundScene.pandaCount => PandaMood.counting,
      BackgroundScene.pandaDay => PandaMood.daytime,
      BackgroundScene.afternoon => PandaMood.afternoon,
      BackgroundScene.pandaWish => PandaMood.wishing,
      BackgroundScene.pandaNight => PandaMood.sleeping,
      BackgroundScene.pandaCharging => PandaMood.charging,
    };
  }

  BackgroundScene get backgroundScene => sceneFor(now, isCharging: isCharging);
  String get backgroundAsset => backgroundScene.assetPath;

  static BackgroundScene sceneFor(DateTime now, {required bool isCharging}) {
    // The monthly celebration always takes precedence over the daily scene.
    if (now.day == 4) return BackgroundScene.celebration;
    if (isCharging) return BackgroundScene.pandaCharging;
    if (now.hour == 0 && now.minute < 5) return BackgroundScene.pandaCount;
    if (now.hour >= 7 && now.hour < 13) return BackgroundScene.pandaDay;
    if (now.hour >= 13 && now.hour < 16) return BackgroundScene.afternoon;
    if (now.hour >= 16 && now.hour < 22) return BackgroundScene.pandaWish;
    return BackgroundScene.pandaNight;
  }

  String get pandaLabel {
    return switch (pandaMood) {
      PandaMood.counting => 'Counting twilights',
      PandaMood.daytime => 'Enjoying the day',
      PandaMood.afternoon => 'Quiet afternoon',
      PandaMood.wishing => 'Enjoying the evening',
      PandaMood.sleeping => 'Cozy night',
      PandaMood.celebrating => 'Another month together',
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
      TwilightPhase.night => const Color(0xFF355F95),
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

extension BackgroundSceneAsset on BackgroundScene {
  String get assetPath => switch (this) {
    BackgroundScene.pandaCharging => 'assets/images/panda_charging.jpeg',
    BackgroundScene.celebration => 'assets/images/celebration.jpeg',
    BackgroundScene.pandaCount => 'assets/images/panda_count.jpeg',
    BackgroundScene.pandaDay => 'assets/images/panda_day.jpg',
    BackgroundScene.afternoon => 'assets/images/afternoon.jpeg',
    BackgroundScene.pandaWish => 'assets/images/panda_wish.jpeg',
    BackgroundScene.pandaNight => 'assets/images/panda_night.jpg',
  };
}
