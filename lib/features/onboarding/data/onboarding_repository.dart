import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  const OnboardingRepository();

  static const _completedKey = 'labelwise_onboarding_completed';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  // Debug helper if we ever need to reset onboarding locally:
  // await prefs.remove(_completedKey);
}
