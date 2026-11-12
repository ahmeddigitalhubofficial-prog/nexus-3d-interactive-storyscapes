import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_story_app/domain/entities/story_models.dart';
import 'package:interactive_story_app/presentation/cubit/story_cubit.dart';

void main() {
  group('StoryCubit tests', () {
    late StoryCubit storyCubit;
    late StoryDetails mockDetails;

    setUp(() {
      storyCubit = StoryCubit();
      mockDetails = const StoryDetails(
        storyTitle: 'Test Story',
        startNodeId: 'intro',
        nodes: {
          'intro': StoryNode(
            id: 'intro',
            text: 'Intro text',
            imagePath: 'assets/images/intro.png',
            choices: [
              StoryChoice(
                text: 'Go to node A',
                targetNodeId: 'node_a',
                stateUpdates: [
                  StateUpdate(variable: 'fear', operation: 'add', value: 10),
                ],
              ),
              StoryChoice(
                text: 'Go to locked node',
                targetNodeId: 'node_b',
                condition: Condition(variable: 'inventory', operator: 'contains', value: 'key'),
              ),
            ],
          ),
          'node_a': StoryNode(
            id: 'node_a',
            text: 'Node A text',
            imagePath: 'assets/images/node_a.png',
            choices: [],
            isEnding: true,
            endingTitle: 'Ending A',
          ),
          'node_b': StoryNode(
            id: 'node_b',
            text: 'Node B text',
            imagePath: 'assets/images/node_b.png',
            choices: [],
          ),
        },
      );
    });

    tearDown(() {
      storyCubit.close();
    });

    test('Initial state should be empty', () {
      expect(storyCubit.state.status, StoryStatus.initial);
      expect(storyCubit.state.currentNode, isNull);
    });

    test('Starting a new story navigates to start node and resets state', () {
      storyCubit.startNewStory(mockDetails, 'test_story');

      expect(storyCubit.state.status, StoryStatus.playing);
      expect(storyCubit.state.storyId, 'test_story');
      expect(storyCubit.state.currentNode?.id, 'intro');
      expect(storyCubit.state.playerState.health, 100);
      expect(storyCubit.state.playerState.fear, 0);
    });

    test('Selecting a choice updates player state variables and history', () {
      storyCubit.startNewStory(mockDetails, 'test_story');
      final choice = storyCubit.state.currentNode!.choices[0];
      
      storyCubit.selectChoice(choice);

      expect(storyCubit.state.currentNode?.id, 'node_a');
      expect(storyCubit.state.playerState.fear, 10);
      expect(storyCubit.state.history, ['intro']);
      // Checkpoint must be registered for 'intro' node
      expect(storyCubit.state.playerState.checkpoints.containsKey('intro'), true);
      expect(storyCubit.state.playerState.checkpoints['intro']?.fear, 0);
    });

    test('Locked choice condition prevents selection', () {
      storyCubit.startNewStory(mockDetails, 'test_story');
      final lockedChoice = storyCubit.state.currentNode!.choices[1];

      // Try selecting choice without having the key item
      storyCubit.selectChoice(lockedChoice);

      // Node should remain 'intro'
      expect(storyCubit.state.currentNode?.id, 'intro');
    });

    test('Rewinding to checkpoint restores stats and history', () {
      storyCubit.startNewStory(mockDetails, 'test_story');
      final choice = storyCubit.state.currentNode!.choices[0];
      
      storyCubit.selectChoice(choice);
      expect(storyCubit.state.currentNode?.id, 'node_a');
      expect(storyCubit.state.playerState.fear, 10);

      // Rewind back to 'intro'
      final success = storyCubit.rewindToCheckpoint('intro');

      expect(success, true);
      expect(storyCubit.state.currentNode?.id, 'intro');
      expect(storyCubit.state.playerState.fear, 0); // Restored
      expect(storyCubit.state.history, <String>[]); // Cleared
    });
  });
}
