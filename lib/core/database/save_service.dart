import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/game_state_models.dart';

class SaveService {
  static const String _globalStateKey = 'global_player_state';
  static const String _slotPrefix = 'save_slot_';

  final SharedPreferences prefs;

  SaveService({required this.prefs});

  // --- Global State ---
  PlayerGlobalState getGlobalState() {
    final jsonString = prefs.getString(_globalStateKey);
    if (jsonString == null) {
      return const PlayerGlobalState();
    }
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return PlayerGlobalState.fromJson(jsonMap);
    } catch (e) {
      return const PlayerGlobalState();
    }
  }

  Future<void> saveGlobalState(PlayerGlobalState state) async {
    final jsonString = json.encode(state.toJson());
    await prefs.setString(_globalStateKey, jsonString);
  }

  // --- Save Slots ---
  SaveSlot? getSaveSlot(String slotId) {
    final jsonString = prefs.getString('$_slotPrefix$slotId');
    if (jsonString == null) {
      return null;
    }
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return SaveSlot.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSaveSlot(SaveSlot slot) async {
    final jsonString = json.encode(slot.toJson());
    await prefs.setString('$_slotPrefix${slot.id}', jsonString);
  }

  Future<void> clearSaveSlot(String slotId) async {
    await prefs.remove('$_slotPrefix$slotId');
  }

  List<SaveSlot> getAllSaveSlots() {
    final List<SaveSlot> slots = [];
    // We support 3 slots: "1", "2", "3"
    for (var id in ['1', '2', '3']) {
      final slot = getSaveSlot(id);
      if (slot != null) {
        slots.add(slot);
      } else {
        slots.add(SaveSlot(id: id, lastPlayed: DateTime.fromMillisecondsSinceEpoch(0)));
      }
    }
    return slots;
  }
}
