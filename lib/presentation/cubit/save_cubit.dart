import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/ads/ad_service.dart';
import '../../core/database/save_service.dart';
import '../../domain/entities/game_state_models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_profile.dart';

class SaveState extends Equatable {
  final PlayerGlobalState globalState;
  final List<SaveSlot> slots;
  final bool isWatchingAd;
  final int adCountdown;

  const SaveState({
    this.globalState = const PlayerGlobalState(),
    this.slots = const [],
    this.isWatchingAd = false,
    this.adCountdown = 0,
  });

  SaveState copyWith({
    PlayerGlobalState? globalState,
    List<SaveSlot>? slots,
    bool? isWatchingAd,
    int? adCountdown,
  }) {
    return SaveState(
      globalState: globalState ?? this.globalState,
      slots: slots ?? this.slots,
      isWatchingAd: isWatchingAd ?? this.isWatchingAd,
      adCountdown: adCountdown ?? this.adCountdown,
    );
  }

  @override
  List<Object?> get props => [globalState, slots, isWatchingAd, adCountdown];
}

class SaveCubit extends Cubit<SaveState> {
  final SaveService saveService;
  final AuthRepository? authRepository;

  SaveCubit({required this.saveService, this.authRepository}) : super(const SaveState());

  void loadGlobalAndSlots() {
    final globalState = saveService.getGlobalState();
    final slots = saveService.getAllSaveSlots();
    emit(SaveState(globalState: globalState, slots: slots));
  }

  Future<void> _syncToCloud() async {
    if (authRepository != null) {
      await authRepository!.updateUserStats(
        state.globalState.tickets,
        state.globalState.coins,
        state.globalState.unlockedChapters,
      );
    }
  }

  Future<void> syncWithCloudProfile(UserProfile profile) async {
    final localChapters = state.globalState.unlockedChapters;
    final cloudChapters = profile.unlockedChapters;
    final Set<String> mergedChapters = {...localChapters, ...cloudChapters};
    
    final tickets = profile.tickets;
    final coins = profile.coins;

    final updatedGlobal = state.globalState.copyWith(
      tickets: tickets,
      coins: coins,
      unlockedChapters: mergedChapters.toList(),
    );
    await saveService.saveGlobalState(updatedGlobal);
    emit(state.copyWith(globalState: updatedGlobal));
  }

  // --- Ad Mob Simulation to Earn Tickets ---
  Future<void> earnTicketWithAd(AdService adService) async {
    if (state.isWatchingAd) return;
    emit(state.copyWith(isWatchingAd: true, adCountdown: 3));

    final success = await adService.showRewardedVideoAd(
      onTick: (countdown) {
        emit(state.copyWith(adCountdown: countdown));
      },
    );

    if (success) {
      final updatedGlobal = state.globalState.copyWith(
        tickets: state.globalState.tickets + 1,
      );
      await saveService.saveGlobalState(updatedGlobal);
      emit(state.copyWith(
        globalState: updatedGlobal,
        isWatchingAd: false,
        adCountdown: 0,
      ));
      await _syncToCloud();
    } else {
      emit(state.copyWith(isWatchingAd: false, adCountdown: 0));
    }
  }

  // --- Spend Ticket ---
  Future<bool> spendTicket({int amount = 1}) async {
    if (state.globalState.tickets < amount) return false;

    final updatedGlobal = state.globalState.copyWith(
      tickets: state.globalState.tickets - amount,
    );
    await saveService.saveGlobalState(updatedGlobal);
    emit(state.copyWith(globalState: updatedGlobal));
    await _syncToCloud();
    return true;
  }

  // --- Unlock Chapters / Premium Stories ---
  Future<bool> unlockChapter(String storyId, {int cost = 3}) async {
    if (state.globalState.unlockedChapters.contains(storyId)) return true;
    if (state.globalState.tickets < cost) return false;
    
    final List<String> updatedChapters = List.from(state.globalState.unlockedChapters)..add(storyId);
    final updatedGlobal = state.globalState.copyWith(
      tickets: state.globalState.tickets - cost,
      unlockedChapters: updatedChapters,
    );
    await saveService.saveGlobalState(updatedGlobal);
    emit(state.copyWith(globalState: updatedGlobal));
    await _syncToCloud();
    return true;
  }

  // --- Unlocking Achievements ---
  Future<void> unlockAchievement(String achievementId) async {
    if (state.globalState.unlockedAchievements.contains(achievementId)) return;

    final List<String> updated = List.from(state.globalState.unlockedAchievements)..add(achievementId);
    final updatedGlobal = state.globalState.copyWith(
      unlockedAchievements: updated,
      coins: state.globalState.coins + 30, // reward 30 coins
    );
    await saveService.saveGlobalState(updatedGlobal);
    emit(state.copyWith(globalState: updatedGlobal));
    await _syncToCloud();
  }

  // --- Unlocking Endings ---
  Future<void> unlockEnding(String storyId, String endingTitle) async {
    final Map<String, List<String>> currentEndings = Map.from(state.globalState.unlockedEndings);
    final List<String> storyEndings = List.from(currentEndings[storyId] ?? []);
    
    if (storyEndings.contains(endingTitle)) return;
    storyEndings.add(endingTitle);
    currentEndings[storyId] = storyEndings;

    // reward 50 coins for the ending
    int coinsReward = 50;
    
    // Check if they unlocked all endings of this story
    int totalEndingsForStory = 3;
    if (storyId == 'history_timetravel') {
      totalEndingsForStory = 2;
    }
    
    List<String> updatedAchievements = List.from(state.globalState.unlockedAchievements);
    if (storyEndings.length >= totalEndingsForStory) {
      if (!updatedAchievements.contains('ach_all_endings')) {
        updatedAchievements.add('ach_all_endings');
        coinsReward += 30; // +30 coins for the achievement
      }
    }

    final PlayerGlobalState updatedGlobal = state.globalState.copyWith(
      unlockedEndings: currentEndings,
      unlockedAchievements: updatedAchievements,
      coins: state.globalState.coins + coinsReward,
    );

    await saveService.saveGlobalState(updatedGlobal);
    emit(state.copyWith(globalState: updatedGlobal));
    await _syncToCloud();
  }

  // --- Save Game to Slot ---
  Future<void> saveGame(String slotId, String storyId, String nodeId, PlayerState playerState, List<String> history) async {
    final newSlot = SaveSlot(
      id: slotId,
      storyId: storyId,
      currentNodeId: nodeId,
      lastPlayed: DateTime.now(),
      playerState: playerState,
      history: history,
    );
    await saveService.saveSaveSlot(newSlot);
    loadGlobalAndSlots(); // Refresh list
  }

  // --- Delete Slot ---
  Future<void> deleteSlot(String slotId) async {
    await saveService.clearSaveSlot(slotId);
    loadGlobalAndSlots(); // Refresh list
  }

  // --- Shop: Buy Tickets with Coins ---
  Future<bool> buyTicketsWithCoins(int ticketCount, int coinCost) async {
    if (state.globalState.coins < coinCost) return false;

    final updatedGlobal = state.globalState.copyWith(
      tickets: state.globalState.tickets + ticketCount,
      coins: state.globalState.coins - coinCost,
    );
    await saveService.saveGlobalState(updatedGlobal);
    emit(state.copyWith(globalState: updatedGlobal));
    await _syncToCloud();
    return true;
  }
}
