import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceWhisperPlayer extends StatefulWidget {
  final Color textColor;
  final Color accentColor;

  const VoiceWhisperPlayer({
    super.key,
    required this.textColor,
    required this.accentColor,
  });

  @override
  State<VoiceWhisperPlayer> createState() => _VoiceWhisperPlayerState();
}

class _VoiceWhisperPlayerState extends State<VoiceWhisperPlayer> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  int _currentSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      _stop();
    } else {
      _start();
    }
  }

  void _start() {
    setState(() {
      _isPlaying = true;
      if (_currentSeconds >= 15) _currentSeconds = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_currentSeconds >= 15) {
        _stop();
      } else {
        setState(() {
          _currentSeconds++;
        });
        if (_currentSeconds % 3 == 0) {
          HapticFeedback.selectionClick();
        }
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentSeconds / 15.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Play/Pause button
              InkWell(
                onTap: _togglePlay,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and animated soundwaves
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '15s Audio Love Whisper 🎙️',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                        Text(
                          '00:${_currentSeconds.toString().padLeft(2, '0')} / 00:15',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: widget.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Soundwave bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(20, (index) {
                        final waveHeights = [8.0, 16.0, 24.0, 14.0, 20.0, 28.0, 18.0, 12.0, 22.0, 26.0,
                                             14.0, 20.0, 28.0, 16.0, 12.0, 24.0, 18.0, 26.0, 14.0, 10.0];
                        final baseHeight = waveHeights[index % waveHeights.length];
                        final active = (index / 20.0) <= progress;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 3,
                          height: _isPlaying
                              ? (baseHeight * ((index + _currentSeconds) % 3 == 0 ? 1.2 : 0.6)).clamp(6.0, 28.0)
                              : baseHeight * 0.5,
                          decoration: BoxDecoration(
                            color: active ? widget.accentColor : widget.accentColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
