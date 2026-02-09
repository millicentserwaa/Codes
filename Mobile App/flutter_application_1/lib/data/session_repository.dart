import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../models/session_record.dart';
import 'hive_boxes.dart';

class SessionRepository {
  Future<UserProfile?> getProfile() async {
    final box = await Hive.openBox<UserProfile>(HiveBoxes.profileBox);
    return box.get('local');
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final box = await Hive.openBox<UserProfile>(HiveBoxes.profileBox);
    await box.put('local', profile);
  }

  Future<List<SessionRecord>> getAllSessions({bool newestFirst = true}) async {
    final box = await Hive.openBox<SessionRecord>(HiveBoxes.sessionsBox);
    final sessions = box.values.toList();
    sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (newestFirst) {
      return sessions.reversed.toList();
    }
    return sessions;
  }

  Future<void> addSession(SessionRecord record) async {
    final box = await Hive.openBox<SessionRecord>(HiveBoxes.sessionsBox);
    await box.put(record.sessionId, record);
  }

  Future<void> deleteAllSessions() async {
    final box = await Hive.openBox<SessionRecord>(HiveBoxes.sessionsBox);
    await box.clear();
  }

  Future<List<SessionRecord>> getLastNSessions(int n) async {
    final all = await getAllSessions(newestFirst: true);
    return all.take(n).toList();
  }
}
