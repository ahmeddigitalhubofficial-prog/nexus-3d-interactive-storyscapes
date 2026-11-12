import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/story_models.dart';
import '../../domain/entities/game_state_models.dart';

enum StoryStatus { initial, loading, playing, ending, error }

class StoryState extends Equatable {
  final StoryStatus status;
  final String? storyId;
  final StoryDetails? storyDetails;
  final StoryNode? currentNode;
  final PlayerState playerState;
  final List<String> history;
  final List<String> visitedNodeIds;
  final String? activeEffect; // "shake", "flash_red", or null
  final String? errorMessage;

  const StoryState({
    this.status = StoryStatus.initial,
    this.storyId,
    this.storyDetails,
    this.currentNode,
    this.playerState = const PlayerState(),
    this.history = const [],
    this.visitedNodeIds = const [],
    this.activeEffect,
    this.errorMessage,
  });

  StoryState copyWith({
    StoryStatus? status,
    String? storyId,
    StoryDetails? storyDetails,
    StoryNode? currentNode,
    PlayerState? playerState,
    List<String>? history,
    List<String>? visitedNodeIds,
    String? activeEffect,
    String? errorMessage,
  }) {
    return StoryState(
      status: status ?? this.status,
      storyId: storyId ?? this.storyId,
      storyDetails: storyDetails ?? this.storyDetails,
      currentNode: currentNode ?? this.currentNode,
      playerState: playerState ?? this.playerState,
      history: history ?? this.history,
      visitedNodeIds: visitedNodeIds ?? this.visitedNodeIds,
      activeEffect: activeEffect,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        storyId,
        storyDetails,
        currentNode,
        playerState,
        history,
        visitedNodeIds,
        activeEffect,
        errorMessage,
      ];
}

class StoryCubit extends Cubit<StoryState> {
  StoryCubit() : super(const StoryState());

  void startNewStory(StoryDetails details, String storyId) {
    final startNode = details.nodes[details.startNodeId];
    if (startNode == null) {
      emit(StoryState(
        status: StoryStatus.error,
        errorMessage: 'Start node "${details.startNodeId}" not found.',
      ));
      return;
    }

    debugPrint('📖 [StoryCubit] Starting new story: "$storyId"');
    debugPrint('📍 [StoryCubit] Loaded node: "${startNode.id}" (Text: "${startNode.text.substring(0, startNode.text.length > 30 ? 30 : startNode.text.length)}...")');

    emit(StoryState(
      status: StoryStatus.playing,
      storyId: storyId,
      storyDetails: details,
      currentNode: startNode,
      playerState: const PlayerState(), // reset stats
      history: const [],
      visitedNodeIds: [startNode.id],
      activeEffect: startNode.effect,
    ));
  }

  void resumeStory(StoryDetails details, String storyId, String nodeId, PlayerState savedPlayerState, List<String> savedHistory) {
    final currentNode = details.nodes[nodeId];
    if (currentNode == null) {
      emit(StoryState(
        status: StoryStatus.error,
        errorMessage: 'Saved node "$nodeId" not found.',
      ));
      return;
    }

    debugPrint('🔄 [StoryCubit] Resuming story "$storyId" at node: "$nodeId"');

    final List<String> initialVisited = List.from(savedHistory);
    if (!initialVisited.contains(nodeId)) {
      initialVisited.add(nodeId);
    }

    emit(StoryState(
      status: StoryStatus.playing,
      storyId: storyId,
      storyDetails: details,
      currentNode: currentNode,
      playerState: savedPlayerState,
      history: savedHistory,
      visitedNodeIds: initialVisited,
      activeEffect: currentNode.effect,
    ));
  }

  void selectChoice(StoryChoice choice) {
    final details = state.storyDetails;
    final currentNode = state.currentNode;
    if (details == null || currentNode == null) return;

    // 1. Evaluate choice conditions
    if (choice.condition != null && !evaluateCondition(choice.condition!)) {
      // Condition not met (should be disabled in UI, but safe check)
      return;
    }

    debugPrint('👉 [StoryCubit] Selected choice: "${choice.text}" -> target node: "${choice.targetNodeId}"');

    // 2. Save checkpoint snapshot for current node (before modifying state)
    // We treat every node from which a choice is made as a potential checkpoint.
    final Map<String, PlayerStateSnapshot> updatedCheckpoints = Map.from(state.playerState.checkpoints);
    updatedCheckpoints[currentNode.id] = PlayerStateSnapshot(
      health: state.playerState.health,
      fear: state.playerState.fear,
      inventory: List.from(state.playerState.inventory),
    );

    // 3. Update Player State variables
    PlayerState updatedPlayer = state.playerState.copyWith(checkpoints: updatedCheckpoints);
    if (choice.stateUpdates != null) {
      updatedPlayer = applyStateUpdates(updatedPlayer, choice.stateUpdates!);
    }

    // 4. Update History
    final List<String> updatedHistory = List.from(state.history)..add(currentNode.id);

    // 5. Navigate to Target Node
    final targetNode = details.nodes[choice.targetNodeId];
    if (targetNode == null) {
      emit(state.copyWith(
        status: StoryStatus.error,
        errorMessage: 'Target node "${choice.targetNodeId}" not found.',
      ));
      return;
    }

    debugPrint('📍 [StoryCubit] Loaded node: "${targetNode.id}" (Text: "${targetNode.text.substring(0, targetNode.text.length > 30 ? 30 : targetNode.text.length)}...")');

    final List<String> updatedVisited = List.from(state.visitedNodeIds);
    if (!updatedVisited.contains(targetNode.id)) {
      updatedVisited.add(targetNode.id);
    }

    emit(state.copyWith(
      currentNode: targetNode,
      playerState: updatedPlayer,
      history: updatedHistory,
      visitedNodeIds: updatedVisited,
      activeEffect: targetNode.effect,
      status: targetNode.isEnding ? StoryStatus.ending : StoryStatus.playing,
    ));
  }

  void triggerEffect(String effectName) {
    emit(state.copyWith(activeEffect: effectName));
  }

  void clearEffect() {
    emit(state.copyWith(activeEffect: null));
  }

  // --- Rewind/Checkpoint feature ---
  bool rewindToCheckpoint(String nodeId) {
    final details = state.storyDetails;
    if (details == null) return false;

    final targetNode = details.nodes[nodeId];
    final snapshot = state.playerState.checkpoints[nodeId];
    if (targetNode == null || snapshot == null) return false;

    // Restore player state from snapshot
    final PlayerState restoredPlayer = state.playerState.copyWith(
      health: snapshot.health,
      fear: snapshot.fear,
      inventory: List.from(snapshot.inventory),
      // keep checkpoints maps intact (or clean future checkpoints, but keeping them is fine)
    );

    // Reconstruct history back to this node
    final int nodeIndex = state.history.indexOf(nodeId);
    List<String> restoredHistory = const [];
    if (nodeIndex != -1) {
      restoredHistory = state.history.sublist(0, nodeIndex);
    }

    emit(state.copyWith(
      status: targetNode.isEnding ? StoryStatus.ending : StoryStatus.playing,
      currentNode: targetNode,
      playerState: restoredPlayer,
      history: restoredHistory,
      activeEffect: targetNode.effect,
    ));
    return true;
  }

  // --- Undo Last Choice during gameplay ---
  bool undoLastChoice() {
    final details = state.storyDetails;
    if (details == null || state.history.isEmpty) return false;

    // Get the previous node ID from history
    final previousNodeId = state.history.last;
    final targetNode = details.nodes[previousNodeId];
    final snapshot = state.playerState.checkpoints[previousNodeId];
    
    if (targetNode == null || snapshot == null) return false;

    // Pop the last node from history
    final List<String> restoredHistory = List.from(state.history)..removeLast();

    // Revert player state using snapshot
    final restoredPlayer = state.playerState.copyWith(
      health: snapshot.health,
      fear: snapshot.fear,
      inventory: List.from(snapshot.inventory),
    );

    debugPrint('⏮️ [StoryCubit] Undoing last choice. Returning to: "$previousNodeId"');

    emit(state.copyWith(
      status: targetNode.isEnding ? StoryStatus.ending : StoryStatus.playing,
      currentNode: targetNode,
      playerState: restoredPlayer,
      history: restoredHistory,
      activeEffect: targetNode.effect,
    ));
    return true;
  }

  // --- AR Object Completion ---
  void completeARInspection(String triggerItem) {
    if (state.playerState.inventory.contains(triggerItem)) return;

    debugPrint('🔍 [StoryCubit] AR Inspection Completed. Added item to inventory: "$triggerItem"');

    final List<String> updatedInventory = List.from(state.playerState.inventory)..add(triggerItem);
    final updatedPlayer = state.playerState.copyWith(inventory: updatedInventory);

    emit(state.copyWith(playerState: updatedPlayer));
  }

  // --- Heart Rate Measurement Result ---
  void submitHeartRateCheck(int heartRate) {
    final check = state.currentNode?.heartRateCheck;
    final details = state.storyDetails;
    if (check == null || details == null) return;

    // threshold is 90 BPM
    final targetNodeId = (heartRate > 90) ? check.highBpmTargetNodeId : check.lowBpmTargetNodeId;
    final targetNode = details.nodes[targetNodeId];

    debugPrint('❤️ [StoryCubit] Heart rate check submitted: $heartRate BPM. Target node: "$targetNodeId"');

    if (targetNode == null) {
      emit(state.copyWith(
        status: StoryStatus.error,
        errorMessage: 'Heart rate target node "$targetNodeId" not found.',
      ));
      return;
    }

    // Save checkpoint snapshot
    final Map<String, PlayerStateSnapshot> updatedCheckpoints = Map.from(state.playerState.checkpoints);
    updatedCheckpoints[state.currentNode!.id] = PlayerStateSnapshot(
      health: state.playerState.health,
      fear: state.playerState.fear,
      inventory: List.from(state.playerState.inventory),
    );

    final List<String> updatedHistory = List.from(state.history)..add(state.currentNode!.id);

    final List<String> updatedVisited = List.from(state.visitedNodeIds);
    if (!updatedVisited.contains(targetNode.id)) {
      updatedVisited.add(targetNode.id);
    }

    emit(state.copyWith(
      currentNode: targetNode,
      history: updatedHistory,
      visitedNodeIds: updatedVisited,
      activeEffect: targetNode.effect,
      playerState: state.playerState.copyWith(checkpoints: updatedCheckpoints),
      status: targetNode.isEnding ? StoryStatus.ending : StoryStatus.playing,
    ));
  }

  // --- QTE / Timed Choice Expiry ---
  void handleTimerExpiry() {
    final details = state.storyDetails;
    final fallbackNodeId = state.currentNode?.fallbackNodeId;
    if (details == null || fallbackNodeId == null) return;

    final targetNode = details.nodes[fallbackNodeId];

    debugPrint('⏰ [StoryCubit] QTE Timer Expired! Target fallback node: "$fallbackNodeId"');

    if (targetNode == null) {
      emit(state.copyWith(
        status: StoryStatus.error,
        errorMessage: 'Fallback node "$fallbackNodeId" not found.',
      ));
      return;
    }

    // Save checkpoint snapshot
    final Map<String, PlayerStateSnapshot> updatedCheckpoints = Map.from(state.playerState.checkpoints);
    updatedCheckpoints[state.currentNode!.id] = PlayerStateSnapshot(
      health: state.playerState.health,
      fear: state.playerState.fear,
      inventory: List.from(state.playerState.inventory),
    );

    final List<String> updatedHistory = List.from(state.history)..add(state.currentNode!.id);

    final List<String> updatedVisited = List.from(state.visitedNodeIds);
    if (!updatedVisited.contains(targetNode.id)) {
      updatedVisited.add(targetNode.id);
    }

    emit(state.copyWith(
      currentNode: targetNode,
      history: updatedHistory,
      visitedNodeIds: updatedVisited,
      activeEffect: targetNode.effect,
      playerState: state.playerState.copyWith(checkpoints: updatedCheckpoints),
      status: targetNode.isEnding ? StoryStatus.ending : StoryStatus.playing,
    ));
  }

  // --- Helper Methods for Conditions & Updates ---
  bool evaluateCondition(Condition condition) {
    if (condition.variable == 'inventory') {
      final valueStr = condition.value as String;
      if (condition.operator == 'contains') {
        return state.playerState.inventory.contains(valueStr);
      } else if (condition.operator == 'not_contains') {
        return !state.playerState.inventory.contains(valueStr);
      }
    } else if (condition.variable == 'health') {
      final val = condition.value as int;
      if (condition.operator == '==') return state.playerState.health == val;
      if (condition.operator == '>=') return state.playerState.health >= val;
      if (condition.operator == '<=') return state.playerState.health <= val;
    } else if (condition.variable == 'fear') {
      final val = condition.value as int;
      if (condition.operator == '==') return state.playerState.fear == val;
      if (condition.operator == '>=') return state.playerState.fear >= val;
      if (condition.operator == '<=') return state.playerState.fear <= val;
    }
    return true;
  }

  PlayerState applyStateUpdates(PlayerState current, List<StateUpdate> updates) {
    int health = current.health;
    int fear = current.fear;
    List<String> inventory = List.from(current.inventory);

    for (var update in updates) {
      if (update.variable == 'health') {
        final val = update.value as int;
        if (update.operation == 'add') health = (health + val).clamp(0, 100);
        if (update.operation == 'subtract') health = (health - val).clamp(0, 100);
        if (update.operation == 'set') health = val.clamp(0, 100);
      } else if (update.variable == 'fear') {
        final val = update.value as int;
        if (update.operation == 'add') fear = (fear + val).clamp(0, 100);
        if (update.operation == 'subtract') fear = (fear - val).clamp(0, 100);
        if (update.operation == 'set') fear = val.clamp(0, 100);
      } else if (update.variable == 'inventory') {
        final val = update.value as String;
        if (update.operation == 'add' && !inventory.contains(val)) {
          inventory.add(val);
        }
        if (update.operation == 'remove') {
          inventory.remove(val);
        }
      }
    }

    return current.copyWith(
      health: health,
      fear: fear,
      inventory: inventory,
    );
  }
}
