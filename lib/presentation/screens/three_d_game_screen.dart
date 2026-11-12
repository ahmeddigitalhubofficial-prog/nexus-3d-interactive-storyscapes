import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

import '../cubit/language_cubit.dart';
import '../cubit/story_cubit.dart';
import '../widgets/glass_container.dart';
import '../widgets/native_3d_scene_widget.dart';
import '../../domain/entities/story_models.dart';

class ThreeDGameScreen extends StatefulWidget {
  final String storyId;
  final String title;

  const ThreeDGameScreen({
    super.key,
    this.storyId = 'chrono_core',
    this.title = 'Nexus 3D: Interactive Storyscapes',
  });

  @override
  State<ThreeDGameScreen> createState() => _ThreeDGameScreenState();
}

class _ThreeDGameScreenState extends State<ThreeDGameScreen> {
  final String _currentTimeState = '2140';
  static bool _iframeRegistered = false;
  final String _viewType = 'nexus-3d-webgl-view';

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_iframeRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
          iframe.src = 'web3d_game/index.html';
          iframe.style.border = 'none';
          iframe.style.width = '100%';
          iframe.style.height = '100%';
          return iframe;
        },
      );
      _iframeRegistered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117).withValues(alpha: 0.85),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00E5FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFF00E5FF), blurRadius: 8, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Time-Shift Badge / Timeline Status
          if (widget.storyId == 'chrono_core')
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _currentTimeState == '2088' ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFFFF3300).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _currentTimeState == '2088' ? const Color(0xFF00E5FF) : const Color(0xFFFF3300),
                ),
              ),
              child: Text(
                _currentTimeState == '2088' ? '⏳ 2088 Timeline' : '⚠️ 2140 Ruin',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _currentTimeState == '2088' ? const Color(0xFF00E5FF) : const Color(0xFFFF3300),
                ),
              ),
            ),
        ],
      ),
      body: BlocBuilder<StoryCubit, StoryState>(
        builder: (context, state) {
          final node = state.currentNode;
          if (node == null) {
            return Stack(
              children: [
                _buildAdaptive3DBackground(),
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ],
            );
          }

          final playerState = state.playerState;

          return Stack(
            children: [
              // 1. Adaptive 3D Scene Background (WebGL on Web, Native CustomPainter on Mobile/Desktop)
              Positioned.fill(
                child: _buildAdaptive3DBackground(),
              ),

              // 2. Interactive Story Node Dialogue Overlay & Choices
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(),

                    // Story Narrative Glass Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              node.text,
                              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Choice Options Buttons
                            ...node.choices.map((choice) {
                              final isLocked = _isChoiceLocked(choice, playerState);
                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLocked
                                        ? Colors.white10
                                        : const Color(0xFF162235).withValues(alpha: 0.9),
                                    foregroundColor: isLocked ? Colors.white38 : const Color(0xFF00E5FF),
                                    side: BorderSide(
                                      color: isLocked ? Colors.white12 : const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: isLocked
                                      ? null
                                      : () {
                                          context.read<StoryCubit>().selectChoice(choice);
                                        },
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLocked ? Icons.lock : Icons.play_arrow_rounded,
                                        size: 18,
                                        color: isLocked ? Colors.white38 : const Color(0xFF00E5FF),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          choice.text,
                                          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isLocked ? Colors.white38 : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdaptive3DBackground() {
    if (kIsWeb) {
      return HtmlElementView(viewType: _viewType);
    }
    return Native3DSceneWidget(
      storyId: widget.storyId,
      timeState: _currentTimeState,
    );
  }

  bool _isChoiceLocked(StoryChoice choice, dynamic playerState) {
    if (choice.condition == null) return false;
    final cond = choice.condition!;
    if (cond.variable == 'inventory') {
      if (cond.operator == 'contains') {
        final inv = (playerState as dynamic).inventory as List<String>;
        return !inv.contains(cond.value.toString());
      }
    }
    return false;
  }
}
