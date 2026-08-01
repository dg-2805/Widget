import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/bucket_item.dart';
import '../models/mood.dart';
import '../services/firebase_service.dart';
import '../services/widget_service.dart';
import '../core/theme/app_theme.dart';
import '../core/twilight/twilight_state.dart';

class AppState extends ChangeNotifier {
  final _fb = FirebaseService.instance;
  final _battery = Battery();
  bool isInitializing = true;
  bool isDay = AppTheme.isDayTime();
  TwilightState twilight = TwilightState.from(
    DateTime.now(),
    batteryLevel: 100,
    isCharging: false,
  );
  int batteryLevel = 100;
  bool isCharging = false;
  DateTime anniversary = DateTime(2026, 2, 4);
  int daysTogether = 0;
  Mood myMood = Mood.okay;

  List<Note> notes = [];
  List<BucketItem> bucketItems = [];

  StreamSubscription? _notesSub;
  StreamSubscription? _bucketSub;
  StreamSubscription<BatteryState>? _batteryStateSub;
  Timer? _midnightTimer;
  Timer? _themeTimer;
  Timer? _boundaryTimer;
  Timer? _batteryTimer;

  bool get isPaired => _fb.isPaired;

  Future<void> init() async {
    try {
      await _fb.init();
      if (_fb.isPaired) {
        await _startListening();
      }
      await _refreshTwilightState(pushWidget: true);
      _scheduleTwilightRefresh();
      _scheduleBatteryRefresh();
      _listenToBatteryState();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> pair(String code) async {
    await _fb.joinSpace(code);
    await _startListening();
    notifyListeners();
  }

  Future<void> _startListening() async {
    anniversary = await _fb.getAnniversary();
    _recalculateDays();

    _notesSub?.cancel();
    _notesSub = _fb.notesStream().listen((n) {
      notes = n;
      _pushWidget();
      notifyListeners();
    });

    _bucketSub?.cancel();
    _bucketSub = _fb.bucketStream().listen((b) {
      bucketItems = b;
      notifyListeners();
    });
  }

  void _recalculateDays() {
    final now = DateTime.now();
    final start = DateTime(anniversary.year, anniversary.month, anniversary.day);
    final today = DateTime(now.year, now.month, now.day);
    daysTogether = today.difference(start).inDays;
  }

  void _pushWidget() {
    WidgetService.update(twilight);
  }

  Future<void> _refreshTwilightState({bool pushWidget = false}) async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    batteryLevel = level;
    isCharging = state == BatteryState.charging || state == BatteryState.full;
    twilight = TwilightState.from(
      DateTime.now(),
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );
    isDay = twilight.phase != TwilightPhase.night;
    if (pushWidget) _pushWidget();
  }

  void _scheduleTwilightRefresh() {
    _boundaryTimer?.cancel();
    final now = DateTime.now();
    final nextBoundary = TwilightState.nextBoundaryAfter(now);
    _boundaryTimer = Timer(nextBoundary.difference(now), () async {
      await _refreshTwilightState(pushWidget: true);
      _recalculateDays();
      notifyListeners();
      _scheduleTwilightRefresh();
    });
  }

  void _scheduleBatteryRefresh() {
    _batteryTimer?.cancel();
    _batteryTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _refreshTwilightState(pushWidget: true);
      notifyListeners();
    });
  }

  void _listenToBatteryState() {
    _batteryStateSub?.cancel();
    _batteryStateSub = _battery.onBatteryStateChanged.listen((state) async {
      isCharging = state == BatteryState.charging || state == BatteryState.full;
      await _refreshTwilightState(pushWidget: true);
      notifyListeners();
    });
  }

  Future<void> addNote(String text, String authorName) =>
      _fb.addNote(text, authorName);
  Future<void> updateNote(String id, String text) => _fb.updateNote(id, text);
  Future<void> deleteNote(String id) => _fb.deleteNote(id);

  Future<void> addBucketItem(String title) => _fb.addBucketItem(title);
  Future<void> updateBucketItem(String id, String title) =>
      _fb.updateBucketItem(id, title);
  Future<void> toggleBucketItem(String id, bool completed) =>
      _fb.toggleBucketItem(id, completed);
  Future<void> deleteBucketItem(String id) => _fb.deleteBucketItem(id);

  @override
  void dispose() {
    _notesSub?.cancel();
    _bucketSub?.cancel();
    _batteryStateSub?.cancel();
    _midnightTimer?.cancel();
    _themeTimer?.cancel();
    _boundaryTimer?.cancel();
    _batteryTimer?.cancel();
    super.dispose();
  }
}
