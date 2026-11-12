import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/story_models.dart';

abstract class StoryLocalDataSource {
  Future<List<Story>> getStoriesList(String languageCode);
  Future<StoryDetails> getStoryDetails(String storyId, String languageCode);
}

class StoryLocalDataSourceImpl implements StoryLocalDataSource {
  @override
  Future<List<Story>> getStoriesList(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/stories/$languageCode/stories_list.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Story.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load stories list for language $languageCode: $e');
    }
  }

  @override
  Future<StoryDetails> getStoryDetails(String storyId, String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/stories/$languageCode/$storyId.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return StoryDetails.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to load story details for $storyId ($languageCode): $e');
    }
  }
}
