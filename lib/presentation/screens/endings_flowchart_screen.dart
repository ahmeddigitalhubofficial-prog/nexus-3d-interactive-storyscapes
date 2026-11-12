import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/app_localizations.dart';
import '../cubit/language_cubit.dart';
import '../cubit/story_cubit.dart';
import '../widgets/glass_container.dart';

class EndingsFlowchartScreen extends StatelessWidget {
  final String storyId;
  final bool isRewindMode;

  const EndingsFlowchartScreen({
    super.key,
    required this.storyId,
    this.isRewindMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>().state;
    final l10n = AppLocalizations(language);
    
    return BlocBuilder<StoryCubit, StoryState>(
      builder: (context, state) {
        final details = state.storyDetails;
        if (details == null) {
          return const Scaffold(body: Center(child: Text('No story active')));
        }

        // Gather list of nodes to display in order of history, then remaining nodes
        final historyNodes = state.history;
        final currentNodeId = state.currentNode?.id;
        
        final List<String> orderedNodeIds = [];
        orderedNodeIds.addAll(historyNodes);
        if (currentNodeId != null && !orderedNodeIds.contains(currentNodeId)) {
          orderedNodeIds.add(currentNodeId);
        }

        // Add remaining nodes from the details to represent unexplored paths
        for (var nodeId in details.nodes.keys) {
          if (!orderedNodeIds.contains(nodeId)) {
            orderedNodeIds.add(nodeId);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isRewindMode ? l10n.translate('rewind') : l10n.translate('flowchart')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              // Dark background
              Container(
                color: const Color(0xFF0F172A),
              ),

              // Scrollable Timeline Tree
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                itemCount: orderedNodeIds.length,
                itemBuilder: (context, index) {
                  final nodeId = orderedNodeIds[index];
                  final node = details.nodes[nodeId];
                  if (node == null) return const SizedBox.shrink();

                  final isVisited = state.visitedNodeIds.contains(nodeId);
                  final hasCheckpoint = state.playerState.checkpoints.containsKey(nodeId);
                  final isCurrent = currentNodeId == nodeId;

                  return Stack(
                    children: [
                      // Left Timeline connection line
                      if (index < orderedNodeIds.length - 1)
                        Positioned(
                          top: 24, // below the center of the circle avatar (radius 12, height 24)
                          bottom: 0,
                          left: 11, // centers a width-2 line within the 24px wide circle avatar area
                          child: Container(
                            width: 2,
                            color: isVisited
                                ? const Color(0xFF7C4DFF).withValues(alpha: 0.5)
                                : Colors.white12,
                          ),
                        ),

                      // Right Node Card details
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0, bottom: 24.0),
                        child: GestureDetector(
                          onTap: isRewindMode && hasCheckpoint
                              ? () {
                                  // Perform the rewind!
                                  final success = context.read<StoryCubit>().rewindToCheckpoint(nodeId);
                                  if (success) {
                                    // Pop once: back to the story play screen
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Rewound back to ${node.id}!')),
                                    );
                                  }
                                }
                              : null,
                          child: GlassContainer(
                            borderRadius: 12,
                            padding: const EdgeInsets.all(16),
                            color: isCurrent
                                ? const Color(0xFF00E5FF)
                                : isVisited
                                    ? const Color(0xFF162235)
                                    : Colors.black,
                            opacity: isCurrent
                                ? 0.08
                                : isVisited
                                    ? 0.15
                                    : 0.3,
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF00E5FF)
                                  : isRewindMode && hasCheckpoint
                                      ? Colors.orangeAccent
                                      : Colors.white10,
                              width: isCurrent ? 2 : 1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isVisited
                                            ? 'Scene: ${node.id.toUpperCase()}'
                                            : 'Locked Scene',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent
                                              ? const Color(0xFF00E5FF)
                                              : isVisited
                                                  ? Colors.white70
                                                  : Colors.white24,
                                        ),
                                      ),
                                    ),
                                    if (isRewindMode && hasCheckpoint)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.orange, width: 0.5),
                                        ),
                                        child: Text(
                                          l10n.translate('rewind').split(' ')[0], // "تراجع" or "Rewind"
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isVisited
                                      ? node.text
                                      : '???',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isVisited ? Colors.white60 : Colors.white10,
                                    fontSize: 13,
                                  ),
                                ),
                                if (node.isEnding && isVisited) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ending: ${node.endingTitle}',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Circle avatar indicator on top left
                      Positioned(
                        top: 0,
                        left: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: isCurrent
                              ? const Color(0xFF00E5FF)
                              : isVisited
                                  ? const Color(0xFF7C4DFF)
                                  : Colors.white10,
                          child: Icon(
                            isCurrent
                                ? Icons.play_arrow
                                : node.isEnding
                                    ? Icons.emoji_events
                                    : Icons.lens,
                            size: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
