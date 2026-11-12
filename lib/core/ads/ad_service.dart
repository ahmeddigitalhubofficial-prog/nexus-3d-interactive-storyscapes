abstract class AdService {
  Future<void> initialize();
  Future<bool> showRewardedVideoAd({required void Function(int countdown) onTick});
}

class MockAdServiceImpl implements AdService {
  @override
  Future<void> initialize() async {
    // Simulate initialisation delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<bool> showRewardedVideoAd({required void Function(int countdown) onTick}) async {
    // Simulate a 3-second rewarded video ad countdown
    for (int i = 3; i >= 0; i--) {
      onTick(i);
      await Future.delayed(const Duration(seconds: 1));
    }
    return true; // Successfully watched
  }
}
