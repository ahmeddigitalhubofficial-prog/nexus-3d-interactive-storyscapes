import 'package:equatable/equatable.dart';

class PlayerStateSnapshot extends Equatable {
  final int health;
  final int fear;
  final List<String> inventory;

  const PlayerStateSnapshot({
    required this.health,
    required this.fear,
    required this.inventory,
  });

  factory PlayerStateSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerStateSnapshot(
      health: json['health'] as int,
      fear: json['fear'] as int,
      inventory: List<String>.from(json['inventory'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'health': health,
      'fear': fear,
      'inventory': inventory,
    };
  }

  @override
  List<Object?> get props => [health, fear, inventory];
}

class PlayerState extends Equatable {
  final int health;
  final int fear;
  final List<String> inventory;
  final Map<String, PlayerStateSnapshot> checkpoints; // maps nodeId to PlayerStateSnapshot

  const PlayerState({
    this.health = 100,
    this.fear = 0,
    this.inventory = const [],
    this.checkpoints = const {},
  });

  PlayerState copyWith({
    int? health,
    int? fear,
    List<String>? inventory,
    Map<String, PlayerStateSnapshot>? checkpoints,
  }) {
    return PlayerState(
      health: health ?? this.health,
      fear: fear ?? this.fear,
      inventory: inventory ?? this.inventory,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    final checkpointsMap = json['checkpoints'] as Map<String, dynamic>? ?? {};
    final parsedCheckpoints = checkpointsMap.map(
      (key, value) => MapEntry(key, PlayerStateSnapshot.fromJson(value as Map<String, dynamic>)),
    );
    return PlayerState(
      health: json['health'] as int? ?? 100,
      fear: json['fear'] as int? ?? 0,
      inventory: List<String>.from(json['inventory'] as List? ?? []),
      checkpoints: parsedCheckpoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'health': health,
      'fear': fear,
      'inventory': inventory,
      'checkpoints': checkpoints.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  @override
  List<Object?> get props => [health, fear, inventory, checkpoints];
}

class PlayerGlobalState extends Equatable {
  final int tickets;
  final int coins;
  final List<String> unlockedChapters; // story ids
  final List<String> unlockedAchievements; // achievement ids
  final Map<String, List<String>> unlockedEndings; // storyId -> list of unlocked endingIds/titles

  const PlayerGlobalState({
    this.tickets = 5,
    this.coins = 100,
    this.unlockedChapters = const [],
    this.unlockedAchievements = const [],
    this.unlockedEndings = const {},
  });

  PlayerGlobalState copyWith({
    int? tickets,
    int? coins,
    List<String>? unlockedChapters,
    List<String>? unlockedAchievements,
    Map<String, List<String>>? unlockedEndings,
  }) {
    return PlayerGlobalState(
      tickets: tickets ?? this.tickets,
      coins: coins ?? this.coins,
      unlockedChapters: unlockedChapters ?? this.unlockedChapters,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      unlockedEndings: unlockedEndings ?? this.unlockedEndings,
    );
  }

  factory PlayerGlobalState.fromJson(Map<String, dynamic> json) {
    final endingsMap = json['unlocked_endings'] as Map<String, dynamic>? ?? {};
    final parsedEndings = endingsMap.map(
      (key, value) => MapEntry(key, List<String>.from(value as List)),
    );
    return PlayerGlobalState(
      tickets: json['tickets'] as int? ?? 5,
      coins: json['coins'] as int? ?? 100,
      unlockedChapters: List<String>.from(json['unlocked_chapters'] as List? ?? []),
      unlockedAchievements: List<String>.from(json['unlocked_achievements'] as List? ?? []),
      unlockedEndings: parsedEndings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tickets': tickets,
      'coins': coins,
      'unlocked_chapters': unlockedChapters,
      'unlocked_achievements': unlockedAchievements,
      'unlocked_endings': unlockedEndings,
    };
  }

  @override
  List<Object?> get props => [tickets, coins, unlockedChapters, unlockedAchievements, unlockedEndings];
}

class SaveSlot extends Equatable {
  final String id;
  final String? storyId;
  final String? currentNodeId;
  final DateTime lastPlayed;
  final PlayerState? playerState;
  final List<String> history;

  const SaveSlot({
    required this.id,
    this.storyId,
    this.currentNodeId,
    required this.lastPlayed,
    this.playerState,
    this.history = const [],
  });

  SaveSlot copyWith({
    String? storyId,
    String? currentNodeId,
    DateTime? lastPlayed,
    PlayerState? playerState,
    List<String>? history,
  }) {
    return SaveSlot(
      id: id,
      storyId: storyId ?? this.storyId,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playerState: playerState ?? this.playerState,
      history: history ?? this.history,
    );
  }

  factory SaveSlot.fromJson(Map<String, dynamic> json) {
    return SaveSlot(
      id: json['id'] as String,
      storyId: json['story_id'] as String?,
      currentNodeId: json['current_node_id'] as String?,
      lastPlayed: DateTime.parse(json['last_played'] as String),
      playerState: json['player_state'] != null
          ? PlayerState.fromJson(json['player_state'] as Map<String, dynamic>)
          : null,
      history: List<String>.from(json['history'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'current_node_id': currentNodeId,
      'last_played': lastPlayed.toIso8601String(),
      'player_state': playerState?.toJson(),
      'history': history,
    };
  }

  @override
  List<Object?> get props => [id, storyId, currentNodeId, lastPlayed, playerState, history];
}

class Achievement extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;

  const Achievement({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
  });

  @override
  List<Object?> get props => [id, titleAr, titleEn, descriptionAr, descriptionEn];
}

class CodexEntry extends Equatable {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;

  const CodexEntry({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
  });

  @override
  List<Object?> get props => [id, titleAr, titleEn, descriptionAr, descriptionEn];
}
