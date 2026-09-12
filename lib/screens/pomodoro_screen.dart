import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessionsBeforeLongBreak = 4;

  int _currentSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedSessions = 0;
  Timer? _timer;

  bool _showSettings = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        setState(() => _currentSeconds--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _pulseController.stop();
    _timer?.cancel();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _currentSeconds = _workMinutes * 60;
      _totalSeconds = _workMinutes * 60;
    });
    _pulseController.stop();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _pulseController.stop();
    HapticFeedback.heavyImpact();

    if (!_isBreak) {
      _completedSessions++;
      if (_completedSessions % _sessionsBeforeLongBreak == 0) {
        setState(() {
          _isBreak = true;
          _currentSeconds = _longBreakMinutes * 60;
          _totalSeconds = _longBreakMinutes * 60;
          _isRunning = false;
        });
        _showNotification('Time for a long break! 🎉');
      } else {
        setState(() {
          _isBreak = true;
          _currentSeconds = _breakMinutes * 60;
          _totalSeconds = _breakMinutes * 60;
          _isRunning = false;
        });
        _showNotification('Break time! ☕');
      }
    } else {
      setState(() {
        _isBreak = false;
        _currentSeconds = _workMinutes * 60;
        _totalSeconds = _workMinutes * 60;
        _isRunning = false;
      });
      _showNotification('Back to work! 💪');
    }
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 15)),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _currentSeconds) / _totalSeconds
        : 0.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'Pomodoro',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _showSettings ? Icons.close_rounded : Icons.settings_rounded,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _showSettings = !_showSettings),
                  ),
                ],
              ),
            ),
            if (_showSettings) _buildSettings(colorScheme),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isBreak ? (_currentSeconds > _breakMinutes * 60 * 0.5 ? 'Long Break' : 'Short Break') : 'Focus Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isBreak
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRunning ? _pulseAnimation.value : 1.0,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                                backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isBreak ? colorScheme.primary : const Color(0xFFD93025),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Text(
                              _formatTime(_currentSeconds),
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurface,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(
                          icon: Icons.refresh_rounded,
                          onTap: _resetTimer,
                          colorScheme: colorScheme,
                          size: 44,
                        ),
                        const SizedBox(width: 20),
                        _controlButton(
                          icon: _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: _isRunning ? _pauseTimer : _startTimer,
                          colorScheme: colorScheme,
                          size: 64,
                          filled: true,
                        ),
                        const SizedBox(width: 20),
                        _controlButton(
                          icon: Icons.skip_next_rounded,
                          onTap: _onTimerComplete,
                          colorScheme: colorScheme,
                          size: 44,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildSessionIndicators(colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timer Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _settingRow('Focus duration', '$_workMinutes min', colorScheme, () {
            _showPicker('Focus', _workMinutes, 60, (val) {
              setState(() {
                _workMinutes = val;
                if (!_isRunning && !_isBreak) {
                  _currentSeconds = _workMinutes * 60;
                  _totalSeconds = _workMinutes * 60;
                }
              });
            });
          }),
          _settingRow('Short break', '$_breakMinutes min', colorScheme, () {
            _showPicker('Break', _breakMinutes, 30, (val) {
              setState(() => _breakMinutes = val);
            });
          }),
          _settingRow('Long break', '$_longBreakMinutes min', colorScheme, () {
            _showPicker('Long break', _longBreakMinutes, 60, (val) {
              setState(() => _longBreakMinutes = val);
            });
          }),
          _settingRow('Sessions before long break', '$_sessionsBeforeLongBreak', colorScheme, () {
            _showPicker('Sessions', _sessionsBeforeLongBreak, 8, (val) {
              setState(() => _sessionsBeforeLongBreak = val);
            });
          }),
        ],
      ),
    );
  }

  Widget _settingRow(String label, String value, ColorScheme colorScheme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Text(value, style: TextStyle(fontSize: 14, color: colorScheme.primary)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showPicker(String title, int current, int max, ValueChanged<int> onChanged) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(max, (i) {
              final val = i + 1;
              return ListTile(
                title: Text('$val min'),
                trailing: current == val
                    ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  onChanged(val);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionIndicators(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_sessionsBeforeLongBreak, (i) {
        final isCompleted = i < _completedSessions % _sessionsBeforeLongBreak;
        final isCurrent = i == _completedSessions % _sessionsBeforeLongBreak && !_isBreak;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 24 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isCompleted
                ? colorScheme.primary
                : isCurrent
                    ? const Color(0xFFD93025)
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required double size,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFD93025) : Colors.transparent,
          borderRadius: BorderRadius.circular(size / 2),
          border: filled ? null : Border.all(color: colorScheme.outline, width: 2),
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: filled ? Colors.white : colorScheme.onSurface,
        ),
      ),
    );
  }
}
