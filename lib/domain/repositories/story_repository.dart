import '../entities/story_models.dart';

abstract class StoryRepository {
  Future<List<Story>> getStoriesList(String languageCode);
  Future<StoryDetails> getStoryDetails(String storyId, String languageCode);
}
