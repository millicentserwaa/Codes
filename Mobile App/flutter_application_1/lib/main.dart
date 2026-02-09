import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/user_profile.dart';
import 'models/session_record.dart';
import 'screens/app_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register generated adapters
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AgeGroupAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserProfileAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AfResultAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(SessionRecordAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AF Screening Companion',
      theme: ThemeData(useMaterial3: true),
      home: const AppEntry(),
    );
  }
}
