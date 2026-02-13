import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  static const String boxName = 'user_profile_box';
  static const String keyProfile = 'profile';

  Future<Box<UserProfile>> _box() async {
    return await Hive.openBox<UserProfile>(boxName);
  }

  Future<UserProfile?> getProfile() async {
    final box = await _box();
    return box.get(keyProfile);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = await _box();
    await box.put(keyProfile, profile);
  }
}
