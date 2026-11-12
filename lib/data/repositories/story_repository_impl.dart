import '../../domain/entities/story_models.dart';
import '../../domain/repositories/story_repository.dart';
import '../datasources/story_local_datasource.dart';
import '../datasources/story_remote_datasource.dart';

class StoryRepositoryImpl implements StoryRepository {
  final StoryLocalDataSource localDataSource;
  final StoryRemoteDataSource remoteDataSource;

  StoryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Story>> getStoriesList(String languageCode) async {
    final localStories = await localDataSource.getStoriesList(languageCode);
    try {
      final remoteStories = await remoteDataSource.getRemoteStoriesList(languageCode);
      
      final Map<String, Story> mergedStories = {};
      for (final story in localStories) {
        mergedStories[story.id] = story;
      }
      for (final story in remoteStories) {
        mergedStories[story.id] = story;
      }
      return mergedStories.values.toList();
    } catch (e) {
      // Offline fallback: return only local stories if remote fetch fails
      return localStories;
    }
  }

  @override
  Future<StoryDetails> getStoryDetails(String storyId, String languageCode) async {
    try {
      return await localDataSource.getStoryDetails(storyId, languageCode);
    } catch (_) {
      return await remoteDataSource.getRemoteStoryDetails(storyId, languageCode);
    }
  }
}
