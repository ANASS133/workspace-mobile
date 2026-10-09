import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sync_manager.dart';
import '../theme/app_theme.dart';

class DisciplineScreen extends StatefulWidget {
  final SyncManager syncManager;
  final bool isUnlocked;
  final VoidCallback onUnlocked;
  final VoidCallback onLock;
  final VoidCallback? onClose;

  const DisciplineScreen({
    super.key,
    required this.syncManager,
    this.isUnlocked = false,
    required this.onUnlocked,
    required this.onLock,
    this.onClose,
  });

  @override
  State<DisciplineScreen> createState() => _DisciplineScreenState();
}

class _DisciplineScreenState extends State<DisciplineScreen> with SingleTickerProviderStateMixin {
  static const String _passcode = '9090';
  Timer? _ticker;
  int _quoteIndex = 0;

  String _pin = '';
  bool _hasError = false;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final List<Map<String, String>> _spiritualReminders = [
    {
      'type': 'Quran',
      'arabic': 'قُل لِّلْمُؤْمِنِينَ يَغُضُّوا۟ مِنْ أَبْصَـٰرِهِمْ وَيَحْفَظُوا۟ فُرُوجَهُمْ ۚ ذَٰلِكَ أَزْكَىٰ لَهُمْ',
      'text': 'Tell the believing men to lower their gaze and guard their chastity. That is purer for them.',
      'source': 'Surat An-Nur — 24:30',
    },
    {
      'type': 'Quran',
      'arabic': 'وَأَمَّا مَنْ خَافَ مَقَامَ رَبِّهِۦ وَنَهَى ٱلنَّفْسَ عَنِ ٱلْهَوَىٰ ۝ فَإِنَّ ٱلْجَنَّةَ هِىَ ٱلْمَأْوَىٰ',
      'text': 'As for the one who feared standing before their Lord and restrained the self from desire, Paradise will certainly be their home.',
      'source': 'Surat An-Nazi\'at — 79:40–41',
    },
    {
      'type': 'Sahih Hadith',
      'arabic': 'وَمَا أُعْطِيَ أَحَدٌ عَطَاءً خَيْرًا وَأَوْسَعَ مِنَ الصَّبْرِ',
      'text': 'No one is given a gift better and more encompassing than patience.',
      'source': 'Sahih al-Bukhari 1469',
    },
    {
      'type': 'Discipline Mindset',
      'arabic': 'الرجولة الحقيقية هي القوة على ضبط نفسك عندما لا يراك أحد.',
      'text': 'True strength is the power to master yourself when nobody is watching. An urge is a wave: let it rise, breathe through it, and let it pass.',
      'source': 'Mindset & Self-Control',
    },
    {
      'type': 'Scholar\'s Wisdom',
      'arabic': 'صَبْرُ النَّفْسِ عَنِ الشَّهْوَةِ أَيْسَرُ مِنَ الصَّبْرِ عَلَى مَا تُوجِبُهُ الشَّهْوَةُ',
      'text': 'Patience in resisting desire is easier than patience in bearing the consequences and guilt desire brings.',
      'source': 'Ibn al-Qayyim — Al-Fawa\'id',
    },
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_shakeController);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.isUnlocked) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant DisciplineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isUnlocked && !widget.isUnlocked) {
      setState(() {
        _pin = '';
        _hasError = false;
      });
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 4 || _hasError) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      if (_pin.length == 4) {
        _checkPin();
      }
    });
  }

  void _onBackspacePressed() {
    if (_pin.isEmpty || _hasError) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClearPressed() {
    if (_pin.isEmpty || _hasError) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = '';
    });
  }

  void _checkPin() async {
    if (_pin == _passcode) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
      setState(() {
        _pin = '';
        _hasError = false;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
      });
      _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) {
        setState(() {
          _pin = '';
          _hasError = false;
        });
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _onBackspacePressed();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _onClearPressed();
        return KeyEventResult.handled;
      } else {
        final char = event.character;
        if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
          _onDigitPressed(char);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = math.sin(_shakeAnimation.value * math.pi * 4) * 14 * (1 - _shakeAnimation.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isFilled = index < _pin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: isFilled ? 18 : 16,
            height: isFilled ? 18 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hasError
                  ? AppTheme.priorityHigh
                  : isFilled
                      ? const Color(0xFF38BDF8)
                      : Colors.transparent,
              border: Border.all(
                color: _hasError
                    ? AppTheme.priorityHigh
                    : isFilled
                        ? const Color(0xFF38BDF8)
                        : AppTheme.surfaceBorder,
                width: 2,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: (_hasError ? AppTheme.priorityHigh : const Color(0xFF38BDF8)).withOpacity(0.45),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeypad() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 270),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyButton('1'),
              _buildKeyButton('2'),
              _buildKeyButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyButton('4'),
              _buildKeyButton('5'),
              _buildKeyButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyButton('7'),
              _buildKeyButton('8'),
              _buildKeyButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                label: 'Clear',
                onPressed: _onClearPressed,
              ),
              _buildKeyButton('0'),
              _buildActionButton(
                icon: Icons.backspace_outlined,
                onPressed: _onBackspacePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(35),
        splashColor: const Color(0xFF38BDF8).withOpacity(0.25),
        highlightColor: const Color(0xFF38BDF8).withOpacity(0.12),
        child: Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            digit,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({String? label, IconData? icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: AppTheme.textMuted, size: 22)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPinLockView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.18),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 34,
                color: Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Discipline',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _hasError ? 'Incorrect code. Try again.' : 'Enter 4-digit code to access',
              style: TextStyle(
                fontSize: 13,
                fontWeight: _hasError ? FontWeight.w600 : FontWeight.w400,
                color: _hasError ? AppTheme.priorityHigh : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            _buildPinDots(),
            const SizedBox(height: 36),
            _buildKeypad(),
            const SizedBox(height: 24),
            if (widget.onClose != null)
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onClose!();
                },
                icon: Icon(Icons.arrow_back, size: 16, color: AppTheme.textMuted),
                label: Text(
                  'Back',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _nextQuote() {
    HapticFeedback.lightImpact();
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _spiritualReminders.length;
    });
  }

  void _openEmergencySOS() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => const EmergencySOSSheet(),
    );
  }

  void _promptReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.priorityHigh),
            SizedBox(width: 8),
            Text('Reset Streak?'),
          ],
        ),
        content: const Text(
          'A slip is a lesson, not the end. The real victory is getting back up immediately with renewed resolve and sincere tawbah.',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              widget.syncManager.resetNofap();
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.priorityHigh),
            child: const Text('Reset Counter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isUnlocked) {
      return Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: _buildPinLockView(),
      );
    }

    final startMillis = widget.syncManager.nofapStartTime;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final diffMillis = (nowMillis - startMillis).clamp(0, double.infinity).toInt();

    final totalSeconds = diffMillis ~/ 1000;
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    // Milestone calculation (Target: 7 days, 14 days, 30 days, 60 days, 90 days)
    int targetDays = 7;
    if (days >= 7) targetDays = 14;
    if (days >= 14) targetDays = 30;
    if (days >= 30) targetDays = 60;
    if (days >= 60) targetDays = 90;

    final milestoneProgress = (days / targetDays).clamp(0.0, 1.0);
    final milestonePercent = (milestoneProgress * 100).toInt();

    final currentQuote = _spiritualReminders[_quoteIndex];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF38BDF8), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Discipline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.lock_outline, size: 20, color: AppTheme.textMuted),
                  tooltip: 'Lock Discipline',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onLock();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20, color: AppTheme.textMuted),
                  tooltip: 'Reset streak',
                  onPressed: _promptReset,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Mastery over desires, mental clarity, and spiritual elevation.',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),

        // Hero Streak Timer Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                const Color(0xFF38BDF8).withOpacity(0.12),
                AppTheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              Text(
                '$days',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF38BDF8),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'DAYS CLEAN & FOCUSED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              // Live Hours : Mins : Secs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Text(
                  '${hours.toString().padLeft(2, '0')} hours · ${minutes.toString().padLeft(2, '0')} minutes · ${seconds.toString().padLeft(2, '0')} seconds',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Milestone progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$targetDays-Day Milestone',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '$milestonePercent%',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF38BDF8)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: milestoneProgress,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Emergency SOS Button
        FilledButton.icon(
          onPressed: _openEmergencySOS,
          icon: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
          label: const Text('I Feel a Weak Moment / Urge (SOS)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.priorityHigh,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 18),

        // Spiritual & Quranic Reminder Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.dinColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentQuote['type']!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.dinColor),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextQuote,
                    icon: Icon(Icons.refresh, size: 18, color: AppTheme.textMuted),
                    tooltip: 'Next Reminder',
                  ),
                ],
              ),
              if (currentQuote['arabic']!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  currentQuote['arabic']!,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.8,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
              if (currentQuote['text']!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '“${currentQuote['text']!}”',
                  style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                currentQuote['source']!,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmergencySOSSheet extends StatefulWidget {
  const EmergencySOSSheet({super.key});

  @override
  State<EmergencySOSSheet> createState() => _EmergencySOSSheetState();
}

class _EmergencySOSSheetState extends State<EmergencySOSSheet> {
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.priorityHigh.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: AppTheme.priorityHigh, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Grounding & Reset Protocol',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Breathe counter
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                const Text('4-7-8 Breathing Reset', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.flameOrange)),
                const SizedBox(height: 8),
                Text(
                  '$_secondsRemaining s',
                  style: GoogleFonts.jetBrainsMono(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.flameOrange),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inhale 4s • Hold 7s • Exhale 8s slowly',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '1. Put your phone down immediately.\n'
            '2. Make wudu or wash your face with cold water.\n'
            '3. Do 20 push-ups or leave the isolated room right now.\n'
            '4. Remember: The momentary cheap pleasure brings days of brain fog, guilt, and lost drive. Choose your future self.',
            style: TextStyle(fontSize: 13.5, height: 1.6, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('I am in control • Back to Focus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class DisciplinePage extends StatefulWidget {
  final SyncManager syncManager;

  const DisciplinePage({super.key, required this.syncManager});

  @override
  State<DisciplinePage> createState() => _DisciplinePageState();
}

class _DisciplinePageState extends State<DisciplinePage> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Color(0xFF38BDF8), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Discipline',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          if (_isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock_outline, size: 20),
              tooltip: 'Lock',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isUnlocked = false);
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DisciplineScreen(
            syncManager: widget.syncManager,
            isUnlocked: _isUnlocked,
            onUnlocked: () => setState(() => _isUnlocked = true),
            onLock: () => setState(() => _isUnlocked = false),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
