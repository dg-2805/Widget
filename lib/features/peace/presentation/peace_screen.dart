import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/cute_widgets.dart';

class PeaceScreen extends StatefulWidget {
  const PeaceScreen({super.key});

  @override
  State<PeaceScreen> createState() => _PeaceScreenState();
}

class _PeaceScreenState extends State<PeaceScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _pausedPosition = Duration.zero;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _completionSubscription;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _completionSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _pausedPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleMusic() async {
    try {
      if (_isPlaying) {
        _pausedPosition = await _player.getCurrentPosition() ?? Duration.zero;
        await _player.pause();
      } else {
        if (_duration > Duration.zero && _pausedPosition >= _duration) {
          _pausedPosition = Duration.zero;
        }
        await _player.play(
          AssetSource('moosik.mp3'),
          position: _pausedPosition,
        );
      }
      if (mounted) setState(() => _isPlaying = !_isPlaying);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play music: $error')),
      );
    }
  }

  Future<void> _seekTo(double value) async {
    if (_duration == Duration.zero) return;
    final position = Duration(
      milliseconds: (_duration.inMilliseconds * value).round(),
    );
    await _player.seek(position);
    if (mounted) {
      setState(() {
        _position = position;
        _pausedPosition = position;
      });
    }
  }

  String _formatDuration(Duration value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${value.inMinutes}:${twoDigits(value.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('peaceee')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CuteCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                          'assets/images/pause.png',
                          height: 500,
                          width: double.infinity,
                          fit: BoxFit.contain,   // was BoxFit.cover
                        ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'A little pocket of peace',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: theme.textTheme.labelMedium,
                      ),
                      Expanded(
                        child: Slider(
                          value: _duration == Duration.zero
                              ? 0
                              : (_position.inMilliseconds /
                                      _duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                          onChanged: _duration == Duration.zero ? null : _seekTo,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        onPressed: _toggleMusic,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        tooltip: _isPlaying ? 'Pause music' : 'Play music',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
