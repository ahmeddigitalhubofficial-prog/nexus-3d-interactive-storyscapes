import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart' hide PlayerState;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/entities/story_models.dart';
import '../../domain/entities/game_state_models.dart';
import '../../domain/repositories/story_repository.dart';
import '../cubit/language_cubit.dart';
import '../cubit/save_cubit.dart';
import '../cubit/story_cubit.dart';
import '../cubit/theme_cubit.dart';
import '../widgets/glass_container.dart';
import '../widgets/typewriter_text.dart';
import '../widgets/visual_effect_overlay.dart';
import 'endings_flowchart_screen.dart';
import 'achievements_screen.dart';

class StoryPlayScreen extends StatefulWidget {
  final String storyId;
  final StoryRepository storyRepository;

  const StoryPlayScreen({
    super.key,
    required this.storyId,
    required this.storyRepository,
  });

  @override
  State<StoryPlayScreen> createState() => _StoryPlayScreenState();
}

class _StoryPlayScreenState extends State<StoryPlayScreen> with TickerProviderStateMixin {
  // Audio Players
  late AudioPlayer _bgmPlayer;
  late AudioPlayer _sfxPlayer;
  late AudioPlayer _narrationPlayer;
  late AudioPlayer _ambientPlayer;
  String? _currentBgmPath;

  // Stream Subscriptions
  StreamSubscription? _narrationCompleteSubscription;
  StreamSubscription? _narrationDurationSubscription;

  // Parallax Gyroscope values
  double _parallaxX = 0.0;
  double _parallaxY = 0.0;
  StreamSubscription? _sensorSubscription;

  // Timed Choice Timer
  Timer? _qteTimer;
  int _qteTimeLeft = 0;

  // Story state trackers
  bool _textFinishedTyping = false;
  String? _lastNodeId;

  // TTS (Text-to-Speech) Narrator
  late FlutterTts _flutterTts;
  bool _isTtsMuted = false;

  // Premium settings state
  double _narrationVolume = 1.0;
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.7;
  bool _isAutoPlayEnabled = false;
  List<String> _localUnlockedAchievements = [];
  bool _narrationFinished = false;
  Timer? _autoPlayTimer;
  OverlayEntry? _achievementOverlayEntry;
  double _bgmPlayerVolume = 0.5;
  Duration? _narrationDuration;

  // Vignette animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _narrationPlayer = AudioPlayer();
    _narrationPlayer.setReleaseMode(ReleaseMode.stop);
    _bgmPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _ambientPlayer = AudioPlayer();
    _bgmPlayer.setReleaseMode(ReleaseMode.loop); // Loop background music
    _ambientPlayer.setReleaseMode(ReleaseMode.loop); // Loop ambient sound

    _loadSettings();

    // Vignette pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(_pulseController);

    // Subscribe to narration complete
    _narrationCompleteSubscription = _narrationPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        _onNarrationFinished();
      }
    });

    _narrationDurationSubscription = _narrationPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _narrationDuration = d;
        });
      }
    });

    // Initialize local unlocked achievements list
    _localUnlockedAchievements = List.from(context.read<SaveCubit>().state.globalState.unlockedAchievements);

    // Subscribe to accelerometer to simulate Gyroscope Parallax
    _sensorSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (!mounted) return;
        setState(() {
          // Map raw accelerometer coordinates to small offsets
          _parallaxX = (-event.x).clamp(-12.0, 12.0);
          _parallaxY = (event.y).clamp(-12.0, 12.0);
        });
      },
      onError: (error) {
        // Safely ignore sensor exceptions on platforms without accelerometer hardware (like Chrome/Emulators)
      },
    );

    _flutterTts = FlutterTts();
    _setupTts();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _narrationVolume = prefs.getDouble('vol_narration') ?? 1.0;
      _bgmVolume = prefs.getDouble('vol_bgm') ?? 0.5;
      _sfxVolume = prefs.getDouble('vol_sfx') ?? 0.7;
      _isAutoPlayEnabled = prefs.getBool('autoplay_enabled') ?? false;
      _bgmPlayerVolume = _bgmVolume;
    });
    await _narrationPlayer.setVolume(_narrationVolume);
    await _sfxPlayer.setVolume(_sfxVolume);
    await _bgmPlayer.setVolume(_bgmVolume);
    await _ambientPlayer.setVolume(_bgmVolume * 0.25);
    _startAmbientLoop();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('vol_narration', _narrationVolume);
    await prefs.setDouble('vol_bgm', _bgmVolume);
    await prefs.setDouble('vol_sfx', _sfxVolume);
    await prefs.setBool('autoplay_enabled', _isAutoPlayEnabled);
  }

  Future<void> _setupTts() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        _onNarrationFinished();
      }
    });
  }

  Future<void> _speak(String text, String lang) async {
    if (_isTtsMuted) return;
    await _flutterTts.stop();
    await _flutterTts.setVolume(_narrationVolume);
    _fadeBgmVolume(_bgmVolume * 0.2); // Dim background music during narration

    if (lang == 'ar') {
      await _flutterTts.setLanguage('ar-EG');
      // Query and set a male Egyptian Arabic voice to match pre-recorded male voice (Charon)
      try {
        final dynamic voices = await _flutterTts.getVoices;
        if (voices is List) {
          bool voiceSet = false;
          // 1. Try to find a male Egyptian voice (avoiding female names like Salma, Hoda, Layla, Zeina, Amina, etc.)
          for (var voice in voices) {
            if (voice is Map) {
              final locale = (voice['locale'] ?? '').toString().toLowerCase();
              final name = (voice['name'] ?? '').toString().toLowerCase();
              if ((locale == 'ar-eg' || locale.startsWith('ar_eg')) &&
                  (name.contains('male') || name.contains('maged') || name.contains('esm') ||
                   (!name.contains('salma') && !name.contains('hoda') && !name.contains('layla') && !name.contains('zeina')))) {
                await _flutterTts.setVoice(Map<String, String>.from(voice));
                debugPrint('🎤 [TTS] Set Male Egyptian Arabic voice: ${voice['name']}');
                voiceSet = true;
                break;
              }
            }
          }
          // 2. Fallback to any Egyptian voice if male is not found
          if (!voiceSet) {
            for (var voice in voices) {
              if (voice is Map) {
                final locale = (voice['locale'] ?? '').toString().toLowerCase();
                if (locale == 'ar-eg' || locale.startsWith('ar_eg')) {
                  await _flutterTts.setVoice(Map<String, String>.from(voice));
                  debugPrint('🎤 [TTS] Fallback to any Egyptian voice: ${voice['name']}');
                  voiceSet = true;
                  break;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [TTS] Could not set male Egyptian voice: $e');
      }
    } else {
      await _flutterTts.setLanguage('en-US');
    }

    await _flutterTts.speak(text);
  }

  Future<void> _handleNarration(StoryNode node, String lang) async {
    if (_isTtsMuted) return;

    // Stop any currently playing narration or TTS
    await _narrationPlayer.stop();
    await _flutterTts.stop();

    final customPath = node.narrationPath;
    final fallbackPath = 'assets/audio/narration/$lang/${widget.storyId}_${node.id}.mp3';

    bool voiceOverPlayed = false;

    Future<bool> tryPlayVoiceOver(String path) async {
      try {
        await _narrationPlayer.setVolume(_narrationVolume);
        _fadeBgmVolume(_bgmVolume * 0.2); // Dim background music during narration
        if (path.startsWith('http://') || path.startsWith('https://')) {
          await _narrationPlayer.play(UrlSource(path));
          debugPrint('🎤 [Voice-Over] Playing network narration: $path');
        } else {
          final cleanPath = path.replaceAll('assets/', '');
          await _narrationPlayer.play(AssetSource(cleanPath));
          debugPrint('🎤 [Voice-Over] Playing pre-recorded narration: assets/$cleanPath');
        }
        return true;
      } catch (e) {
        debugPrint('⚠️ [Voice-Over] Failed to play $path: $e');
        return false;
      }
    }

    if (customPath != null && customPath.isNotEmpty) {
      voiceOverPlayed = await tryPlayVoiceOver(customPath);
    }

    if (!voiceOverPlayed) {
      voiceOverPlayed = await tryPlayVoiceOver(fallbackPath);
    }

    if (!voiceOverPlayed) {
      debugPrint('🎤 [Voice-Over] Pre-recorded narration not found at custom or fallback path. Falling back to TTS.');
      await _speak(node.text, lang);
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _narrationCompleteSubscription?.cancel();
    _narrationDurationSubscription?.cancel();
    _qteTimer?.cancel();
    _autoPlayTimer?.cancel();
    _achievementOverlayEntry?.remove();
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _narrationPlayer.dispose();
    _ambientPlayer.dispose();
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  // --- Audio management ---
  Future<void> _fadeBgmVolume(double targetVolume) async {
    final double startVolume = _bgmPlayerVolume;
    final int steps = 10;
    final double stepVal = (targetVolume - startVolume) / steps;
    double currentVolume = startVolume;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      currentVolume += stepVal;
      await _bgmPlayer.setVolume(currentVolume.clamp(0.0, 1.0));
    }
    await _bgmPlayer.setVolume(targetVolume);
    _bgmPlayerVolume = targetVolume;
  }

  void _startAmbientLoop() async {
    try {
      String path;
      if (widget.storyId.contains('horror')) {
        path = 'audio/horror_ambient.mp3';
      } else if (widget.storyId.contains('history')) {
        path = 'audio/history_ambient.mp3';
      } else {
        path = 'audio/comedy_bgm.mp3';
      }
      await _ambientPlayer.stop();
      await _ambientPlayer.setVolume(_bgmVolume * 0.25);
      await _ambientPlayer.play(AssetSource(path));
      debugPrint('🎵 [Ambient Loop] Playing: assets/$path at volume ${_bgmVolume * 0.25}');
    } catch (e) {
      debugPrint('⚠️ Failed to play ambient loop: $e');
    }
  }

  void _handleAudio(StoryNode node) async {
    // 1. Play Background Music (BGM)
    if (node.audioPath != null && node.audioPath != _currentBgmPath) {
      _currentBgmPath = node.audioPath;
      try {
        await _bgmPlayer.stop();
        await _bgmPlayer.setVolume(_bgmVolume);
        _bgmPlayerVolume = _bgmVolume;
        final path = node.audioPath!;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          await _bgmPlayer.play(UrlSource(path));
        } else {
          await _bgmPlayer.play(AssetSource(path.replaceAll('assets/', '')));
        }
      } catch (_) {
        // Catch error silently if audio file doesn't exist yet
      }
    } else if (node.audioPath == null) {
      _bgmPlayer.stop();
      _bgmPlayerVolume = 0.0;
      _currentBgmPath = null;
    }

    // 2. Play Sound Effect (SFX)
    if (node.sfxPath != null) {
      try {
        await _sfxPlayer.stop();
        await _sfxPlayer.setVolume(_sfxVolume);
        final path = node.sfxPath!;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          await _sfxPlayer.play(UrlSource(path));
        } else {
          await _sfxPlayer.play(AssetSource(path.replaceAll('assets/', '')));
        }
      } catch (_) {
        // Catch error silently
      }
    }
  }

  // --- QTE Timer management ---
  void _startQteTimer(StoryNode node) {
    _qteTimer?.cancel();
    if (node.timerSeconds == null) return;

    setState(() {
      _qteTimeLeft = node.timerSeconds!;
    });

    _qteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_qteTimeLeft > 1) {
        setState(() {
          _qteTimeLeft--;
        });
        HapticFeedback.lightImpact(); // Subtle vibration for timer ticks
      } else {
        _qteTimer?.cancel();
        // Trigger timer expiry on story cubit
        context.read<StoryCubit>().handleTimerExpiry();
      }
    });
  }

  void _onNarrationFinished() async {
    if (!mounted) return;
    _fadeBgmVolume(_bgmVolume);
    _narrationFinished = true;
    if (_isAutoPlayEnabled) {
      _triggerAutoPlay();
    }
  }

  void _triggerAutoPlay() {
    _autoPlayTimer?.cancel();
    final node = context.read<StoryCubit>().state.currentNode;
    if (node == null || node.choices.isEmpty) return;

    final validChoices = node.choices.where((choice) {
      return choice.condition == null ||
          context.read<StoryCubit>().evaluateCondition(choice.condition!);
    }).toList();

    if (validChoices.length == 1) {
      _autoPlayTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && _isAutoPlayEnabled && _narrationFinished) {
          final currentNode = context.read<StoryCubit>().state.currentNode;
          if (currentNode == node) {
            context.read<StoryCubit>().selectChoice(validChoices.first);
          }
        }
      });
    }
  }

  void _checkGameplayAchievements(StoryNode node, PlayerState player) {
    if (node.isEnding) {
      if (widget.storyId == 'horror_crypt' && player.health == 100) {
        context.read<SaveCubit>().unlockAchievement('ach_undamaged');
      }
      if (widget.storyId == 'history_timetravel' && player.fear <= 20) {
        context.read<SaveCubit>().unlockAchievement('ach_calm');
      }
    }
    if (player.inventory.contains('flashlight') || player.inventory.contains('rusty_key') || player.inventory.contains('sun_crystal')) {
      context.read<SaveCubit>().unlockAchievement('ach_collector');
    }
  }

  void _showAchievementOverlay(Achievement ach, String language) {
    final title = language == 'ar' ? ach.titleAr : ach.titleEn;
    final desc = language == 'ar' ? ach.descriptionAr : ach.descriptionEn;

    try {
      _sfxPlayer.stop();
      _sfxPlayer.setVolume(_sfxVolume);
      _sfxPlayer.play(AssetSource('audio/coin_reward.mp3'));
    } catch (_) {}

    _achievementOverlayEntry?.remove();
    _achievementOverlayEntry = OverlayEntry(
      builder: (context) => AchievementToast(
        title: title,
        description: desc,
        onDismissed: () {
          _achievementOverlayEntry?.remove();
          _achievementOverlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_achievementOverlayEntry!);
  }

  void _showSettingsDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.translate('settings'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Auto-Play Mode',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _isAutoPlayEnabled,
                          activeThumbColor: const Color(0xFF00E5FF),
                          onChanged: (val) {
                            setDialogState(() {
                              _isAutoPlayEnabled = val;
                            });
                            setState(() {
                              _isAutoPlayEnabled = val;
                            });
                            _saveSettings();
                            if (_isAutoPlayEnabled && _narrationFinished) {
                              _triggerAutoPlay();
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 10),
                    Text(
                      'Narration Volume: ${(_narrationVolume * 100).round()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Slider(
                      value: _narrationVolume,
                      activeColor: const Color(0xFF00E5FF),
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        setDialogState(() {
                          _narrationVolume = val;
                        });
                        setState(() {
                          _narrationVolume = val;
                        });
                        _narrationPlayer.setVolume(val);
                        _flutterTts.setVolume(val);
                        _saveSettings();
                      },
                    ),
                    Text(
                      'Background Music: ${(_bgmVolume * 100).round()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Slider(
                      value: _bgmVolume,
                      activeColor: const Color(0xFF00E5FF),
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        setDialogState(() {
                          _bgmVolume = val;
                        });
                        setState(() {
                          _bgmVolume = val;
                        });
                        _bgmPlayer.setVolume(val);
                        _ambientPlayer.setVolume(val * 0.25);
                        _saveSettings();
                      },
                    ),
                    Text(
                      'Sound Effects: ${(_sfxVolume * 100).round()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Slider(
                      value: _sfxVolume,
                      activeColor: const Color(0xFF00E5FF),
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        setDialogState(() {
                          _sfxVolume = val;
                        });
                        setState(() {
                          _sfxVolume = val;
                        });
                        _sfxPlayer.setVolume(val);
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Show Codex/Lore Book Bottom Sheet ---
  void _showCodex(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.translate('codex'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    l10n.translate('empty_codex'),
                    style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // --- Show Save game dialog ---
  void _showSaveGameDialog(BuildContext context, StoryState storyState, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return BlocBuilder<SaveCubit, SaveState>(
          builder: (context, saveState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.translate('save_now'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ...saveState.slots.map((slot) {
                      final isUsed = slot.storyId != null;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          context.read<SaveCubit>().saveGame(
                                slot.id,
                                widget.storyId,
                                storyState.currentNode!.id,
                                storyState.playerState,
                                storyState.history,
                              );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Game Saved successfully!')),
                          );
                        },
                        child: Text(
                          isUsed
                              ? '${l10n.translate('empty_slot')} ${slot.id} (Overwrites)'
                              : '${l10n.translate('empty_slot')} ${slot.id}',
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>().state;
    final l10n = AppLocalizations(language);
    final themeName = context.watch<ThemeCubit>().state;

    return BlocListener<SaveCubit, SaveState>(
      listenWhen: (previous, current) =>
          previous.globalState.unlockedAchievements.length <
          current.globalState.unlockedAchievements.length,
      listener: (context, saveState) {
        final newAchievements = saveState.globalState.unlockedAchievements
            .where((id) => !_localUnlockedAchievements.contains(id))
            .toList();
        for (var achId in newAchievements) {
          _localUnlockedAchievements.add(achId);
          final ach = AchievementsScreen.getById(achId);
          if (ach != null) {
            _showAchievementOverlay(ach, language);
          }
        }
      },
      child: BlocConsumer<StoryCubit, StoryState>(
        listener: (context, state) {
          if (state.status == StoryStatus.playing || state.status == StoryStatus.ending) {
            if (state.currentNode != null) {
              final isNewNode = state.currentNode!.id != _lastNodeId;
              
              if (isNewNode) {
                _lastNodeId = state.currentNode!.id;
                _autoPlayTimer?.cancel();
                _narrationFinished = false;
                _narrationDuration = null; // Reset duration for dynamic typewriter
                _handleAudio(state.currentNode!);
                _textFinishedTyping = false; // Only reset when we actually move to a new node!
                final language = context.read<LanguageCubit>().state;
                _handleNarration(state.currentNode!, language);
                _checkGameplayAchievements(state.currentNode!, state.playerState);
              }
              
              // Check if node is ending to record unlock in global state
              if (state.currentNode!.isEnding && state.currentNode!.endingTitle != null) {
                context.read<SaveCubit>().unlockEnding(widget.storyId, state.currentNode!.endingTitle!);
              }
            }
          }
        },
        builder: (context, state) {
          if (state.status == StoryStatus.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (state.status == StoryStatus.error) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.redAccent, size: 64),
                      const SizedBox(height: 16),
                      Text('Error: ${state.errorMessage}', textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ThemeCubit>().setMenuTheme();
                          Navigator.pop(context);
                        },
                        child: const Text('Back to Menu'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final node = state.currentNode;
          if (node == null) return const SizedBox.shrink();

          final player = state.playerState;

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                // Reset theme
                context.read<ThemeCubit>().setMenuTheme();
              }
            },
            child: Scaffold(
              body: VisualEffectOverlay(
                effect: state.activeEffect,
                storyId: widget.storyId,
                onFinished: () {
                  context.read<StoryCubit>().clearEffect();
                },
                child: Stack(
                  children: [
                    // 1. Illustrated Background with Gyroscope Parallax tilt
                    Positioned.fill(
                      left: -15 + _parallaxX,
                      right: -15 - _parallaxX,
                      top: -15 + _parallaxY,
                      bottom: -15 - _parallaxY,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getGenreGradients(widget.storyId),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: node.imagePath.startsWith('http')
                            ? Image.network(
                                node.imagePath,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      _getGenreIcon(widget.storyId),
                                      size: 100,
                                      color: Colors.white10,
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                node.imagePath,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      _getGenreIcon(widget.storyId),
                                      size: 100,
                                      color: Colors.white10,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    // Pulsing vignette for high fear
                    if (player.fear >= 75)
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.red.withValues(alpha: _pulseAnimation.value * 0.4),
                                      ],
                                      stops: const [0.6, 1.0],
                                      radius: 1.2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    // 2. Playable Story Layers
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Header: Player stats indicator
                                      _buildStatusBar(player, l10n, themeName),
                                      const SizedBox(height: 16),
                
                                      // Secondary actions (Save, Codex, Flowchart, TTS Narration)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildActionIcon(Icons.save, () => _showSaveGameDialog(context, state, l10n)),
                                          _buildActionIcon(Icons.menu_book, () => _showCodex(context, l10n)),
                                          _buildActionIcon(Icons.account_tree, () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EndingsFlowchartScreen(storyId: widget.storyId),
                                              ),
                                            );
                                          }),
                                          _buildActionIcon(
                                            _isTtsMuted ? Icons.volume_off : Icons.volume_up,
                                            () {
                                              setState(() {
                                                _isTtsMuted = !_isTtsMuted;
                                              });
                                              if (_isTtsMuted) {
                                                _flutterTts.stop();
                                                _narrationPlayer.stop();
                                              } else {
                                                _handleNarration(node, language);
                                              }
                                            },
                                          ),
                                          _buildActionIcon(Icons.settings, () => _showSettingsDialog(context, l10n)),
                                          if (state.history.isNotEmpty)
                                            _buildActionIcon(
                                              Icons.undo,
                                              () => context.read<StoryCubit>().undoLastChoice(),
                                            ),
                                        ],
                                      ),
                                      const Spacer(),
                
                                      // 3. Timed Choice/QTE Indicator
                                      if (node.timerSeconds != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: LinearProgressIndicator(
                                            value: _qteTimeLeft / node.timerSeconds!,
                                            backgroundColor: Colors.white12,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                                          ),
                                        ),
                
                                      // 4. 3D Object Inspection trigger
                                      if (node.arConfig != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF00E5FF),
                                              foregroundColor: Colors.black,
                                            ),
                                            icon: const Icon(Icons.view_in_ar),
                                            label: Text('🔍 Inspect 3D Object: ${node.arConfig!.triggerItem}'),
                                            onPressed: () {
                                              final storyCubit = context.read<StoryCubit>();
                                              storyCubit.completeARInspection(node.arConfig!.triggerItem);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('✨ Inspected 3D Item: ${node.arConfig!.triggerItem}'),
                                                  backgroundColor: const Color(0xFF00E5FF),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                
                                      // 5. Visual Novel Glassmorphic Dialog Box
                                      GlassContainer(
                                        borderRadius: 16,
                                        padding: const EdgeInsets.all(20),
                                        color: Colors.black,
                                        opacity: 0.6,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TypewriterText(
                                              text: node.text,
                                              duration: _narrationDuration,
                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black45,
                                                    offset: Offset(1, 1),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              onFinished: () {
                                                setState(() {
                                                  _textFinishedTyping = true;
                                                });
                                                _startQteTimer(node);
                                              },
                                            ),
                                            const SizedBox(height: 16),
                
                                            // Choice Action Buttons
                                            if (_textFinishedTyping) ...[
                                              if (node.choices.isNotEmpty)
                                                ...node.choices.map((choice) {
                                                  final isEnabled = choice.condition == null ||
                                                      context.read<StoryCubit>().evaluateCondition(choice.condition!);
                
                                                  return Container(
                                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                                        backgroundColor: isEnabled ? Colors.white12 : Colors.white10,
                                                        foregroundColor: isEnabled ? Colors.white : Colors.white24,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                          side: BorderSide(
                                                            color: isEnabled ? Colors.white24 : Colors.transparent,
                                                          ),
                                                        ),
                                                      ),
                                                      onPressed: isEnabled
                                                          ? () {
                                                              if (player.fear >= 75) {
                                                                HapticFeedback.heavyImpact();
                                                              } else {
                                                                HapticFeedback.mediumImpact();
                                                              }
                                                              context.read<StoryCubit>().selectChoice(choice);
                                                            }
                                                          : null,
                                                      child: Text(
                                                        choice.text,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                })
                                              else if (node.isEnding) ...[
                                                // Story has ended, show ending details
                                                Text(
                                                  node.endingTitle ?? '',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white10,
                                                  ),
                                                  onPressed: () {
                                                    // Reset theme
                                                    context.read<ThemeCubit>().setMenuTheme();
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(l10n.translate('close')),
                                                ),
                                                const SizedBox(height: 8),
                                                // Rewind to checkpoint costing ticket
                                                if (player.checkpoints.isNotEmpty)
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.orange,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                    onPressed: () => _handleRewind(player, l10n),
                                                    child: Text(l10n.translate('rewind')),
                                                  ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildStatusBar(PlayerState player, AppLocalizations l10n, String themeName) {
    final isComedy = themeName == 'comedy';
    final textColor = isComedy ? Colors.black : Colors.white;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      opacity: 0.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Health Indicator
          _buildProgressIndicator(Icons.favorite, Colors.red, player.health / 100.0, '${player.health}', textColor),
          // Fear Indicator
          _buildProgressIndicator(Icons.warning, Colors.amber, player.fear / 100.0, '${player.fear}', textColor),
          // Inventory Brief Icon
          Row(
            children: [
              const Icon(Icons.backpack, color: Colors.cyan, size: 20),
              const SizedBox(width: 6),
              Text(
                '${player.inventory.length}',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(IconData icon, Color color, double value, String label, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 3),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: value),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, val, _) {
                    return LinearProgressIndicator(
                      value: val,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onPressed) {
    return CircleAvatar(
      backgroundColor: Colors.white10,
      radius: 20,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  // --- Handle Ticket Spend & Rewind Dialog ---
  Future<void> _handleRewind(PlayerState player, AppLocalizations l10n) async {
    final saveCubit = context.read<SaveCubit>();
    final tickets = saveCubit.state.globalState.tickets;

    if (tickets < 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough tickets to rewind! Watch an ad to get more.')),
      );
      return;
    }

    if (!mounted) return;
    final success = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎟️', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.translate('rewind'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rewinding to a previous choice costs 1 ticket. Proceed?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.translate('back')),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Confirm'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    if (success) {
      final ok = await saveCubit.spendTicket(amount: 1);
      if (!mounted) return;
      if (ok) {
        // Navigate to flowchart screen to let them tap on which checkpoint to restore
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EndingsFlowchartScreen(storyId: widget.storyId, isRewindMode: true),
          ),
        );
      }
    }
  }



  List<Color> _getGenreGradients(String storyId) {
    if (storyId.contains('horror')) {
      return [const Color(0xFF1B0002), const Color(0xFF070001)];
    } else if (storyId.contains('comedy')) {
      return [const Color(0xFFFFFDE7), const Color(0xFFFFF9C4)];
    } else if (storyId.contains('history')) {
      return [const Color(0xFF2C2219), const Color(0xFF1E1710)];
    }
    return [const Color(0xFF0F172A), const Color(0xFF020617)];
  }

  IconData _getGenreIcon(String storyId) {
    if (storyId.contains('horror')) return Icons.dark_mode;
    if (storyId.contains('comedy')) return Icons.sentiment_very_satisfied;
    if (storyId.contains('history')) return Icons.history_edu;
    return Icons.menu_book;
  }
}

class AchievementToast extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onDismissed;

  const AchievementToast({
    super.key,
    required this.title,
    required this.description,
    required this.onDismissed,
  });

  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );

    // Slide up from bottom
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismissed();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 64.0, left: 24.0, right: 24.0),
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F0F10), Color(0xFF1E1E24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF003087).withValues(alpha: 0.2), // Subtle PlayStation blue glow
                        blurRadius: 24,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PS5 style Trophy Icon Container with a gold gradient
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Glowing small indicator
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0072CE), // PlayStation Blue
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'TROPHY EARNED',
                                  style: TextStyle(
                                    color: Color(0xFF0072CE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
