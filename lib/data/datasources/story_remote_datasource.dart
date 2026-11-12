import '../../domain/entities/story_models.dart';

abstract class StoryRemoteDataSource {
  Future<List<Story>> getRemoteStoriesList(String languageCode);
  Future<StoryDetails> getRemoteStoryDetails(String storyId, String languageCode);
}

class StoryRemoteDataSourceImpl implements StoryRemoteDataSource {
  @override
  Future<List<Story>> getRemoteStoriesList(String languageCode) async {
    return [];
  }

  @override
  Future<StoryDetails> getRemoteStoryDetails(String storyId, String languageCode) async {
    throw Exception('Remote story details disabled (offline mode)');
  }
}
