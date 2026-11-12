import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String coverImage;
  final String ageRating;
  final String difficulty;
  final bool isRemote;
  final bool is3d;

  const Story({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.coverImage,
    required this.ageRating,
    required this.difficulty,
    this.isRemote = false,
    this.is3d = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      genre: json['genre'] as String,
      coverImage: json['cover_image'] as String,
      ageRating: json['age_rating'] as String,
      difficulty: json['difficulty'] as String,
      isRemote: json['is_remote'] as bool? ?? false,
      is3d: json['is_3d'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'cover_image': coverImage,
      'age_rating': ageRating,
      'difficulty': difficulty,
      'is_remote': isRemote,
      'is_3d': is3d,
    };
  }

  @override
  List<Object?> get props => [id, title, description, genre, coverImage, ageRating, difficulty, isRemote, is3d];
}

class StoryDetails extends Equatable {
  final String storyTitle;
  final String startNodeId;
  final Map<String, StoryNode> nodes;

  const StoryDetails({
    required this.storyTitle,
    required this.startNodeId,
    required this.nodes,
  });

  factory StoryDetails.fromJson(Map<String, dynamic> json) {
    final nodesMap = json['nodes'] as Map<String, dynamic>;
    final parsedNodes = nodesMap.map(
      (key, value) => MapEntry(key, StoryNode.fromJson(value as Map<String, dynamic>)),
    );
    return StoryDetails(
      storyTitle: json['story_title'] as String,
      startNodeId: json['start_node_id'] as String,
      nodes: parsedNodes,
    );
  }

  @override
  List<Object?> get props => [storyTitle, startNodeId, nodes];
}

class StoryNode extends Equatable {
  final String id;
  final String text;
  final String imagePath;
  final String? audioPath;
  final String? sfxPath;
  final String? narrationPath;
  final String? effect; // e.g. "shake", "flash_red"
  final ARConfig? arConfig;
  final HeartRateCheck? heartRateCheck;
  final int? timerSeconds;
  final String? fallbackNodeId;
  final List<StoryChoice> choices;
  final bool isEnding;
  final String? endingTitle;

  const StoryNode({
    required this.id,
    required this.text,
    required this.imagePath,
    this.audioPath,
    this.sfxPath,
    this.narrationPath,
    this.effect,
    this.arConfig,
    this.heartRateCheck,
    this.timerSeconds,
    this.fallbackNodeId,
    required this.choices,
    this.isEnding = false,
    this.endingTitle,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'] as String,
      text: json['text'] as String,
      imagePath: json['image_path'] as String,
      audioPath: json['audio_path'] as String?,
      sfxPath: json['sfx_path'] as String?,
      narrationPath: json['narration_path'] as String?,
      effect: json['effect'] as String?,
      arConfig: json['ar_config'] != null
          ? ARConfig.fromJson(json['ar_config'] as Map<String, dynamic>)
          : null,
      heartRateCheck: json['heart_rate_check'] != null
          ? HeartRateCheck.fromJson(json['heart_rate_check'] as Map<String, dynamic>)
          : null,
      timerSeconds: json['timer_seconds'] as int?,
      fallbackNodeId: json['fallback_node_id'] as String?,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => StoryChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isEnding: json['is_ending'] as bool? ?? false,
      endingTitle: json['ending_title'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        text,
        imagePath,
        audioPath,
        sfxPath,
        narrationPath,
        effect,
        arConfig,
        heartRateCheck,
        timerSeconds,
        fallbackNodeId,
        choices,
        isEnding,
        endingTitle,
      ];
}

class StoryChoice extends Equatable {
  final String text;
  final String targetNodeId;
  final Condition? condition;
  final List<StateUpdate>? stateUpdates;

  const StoryChoice({
    required this.text,
    required this.targetNodeId,
    this.condition,
    this.stateUpdates,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'] as String,
      targetNodeId: json['target_node_id'] as String,
      condition: json['condition'] != null
          ? Condition.fromJson(json['condition'] as Map<String, dynamic>)
          : null,
      stateUpdates: (json['state_updates'] as List<dynamic>?)
          ?.map((e) => StateUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [text, targetNodeId, condition, stateUpdates];
}

class Condition extends Equatable {
  final String variable; // e.g. "inventory", "health", "fear"
  final String operator; // e.g. "contains", "not_contains", "==", ">=", "<="
  final dynamic value;

  const Condition({
    required this.variable,
    required this.operator,
    required this.value,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      variable: json['variable'] as String,
      operator: json['operator'] as String,
      value: json['value'],
    );
  }

  @override
  List<Object?> get props => [variable, operator, value];
}

class StateUpdate extends Equatable {
  final String variable; // "health", "fear", "inventory"
  final String operation; // "add", "subtract", "set"
  final dynamic value;

  const StateUpdate({
    required this.variable,
    required this.operation,
    required this.value,
  });

  factory StateUpdate.fromJson(Map<String, dynamic> json) {
    return StateUpdate(
      variable: json['variable'] as String,
      operation: json['operation'] as String,
      value: json['value'],
    );
  }

  @override
  List<Object?> get props => [variable, operation, value];
}

class ARConfig extends Equatable {
  final String modelPath;
  final Map<String, String> promptText; // e.g. {"ar": "...", "en": "..."}
  final String triggerItem;

  const ARConfig({
    required this.modelPath,
    required this.promptText,
    required this.triggerItem,
  });

  factory ARConfig.fromJson(Map<String, dynamic> json) {
    return ARConfig(
      modelPath: json['model_path'] as String,
      promptText: Map<String, String>.from(json['prompt_text'] as Map),
      triggerItem: json['trigger_item'] as String,
    );
  }

  @override
  List<Object?> get props => [modelPath, promptText, triggerItem];
}

class HeartRateCheck extends Equatable {
  final int durationSeconds;
  final String highBpmTargetNodeId;
  final String lowBpmTargetNodeId;

  const HeartRateCheck({
    required this.durationSeconds,
    required this.highBpmTargetNodeId,
    required this.lowBpmTargetNodeId,
  });

  factory HeartRateCheck.fromJson(Map<String, dynamic> json) {
    return HeartRateCheck(
      durationSeconds: json['duration_seconds'] as int,
      highBpmTargetNodeId: json['high_bpm_target_node_id'] as String,
      lowBpmTargetNodeId: json['low_bpm_target_node_id'] as String,
    );
  }

  @override
  List<Object?> get props => [durationSeconds, highBpmTargetNodeId, lowBpmTargetNodeId];
}
