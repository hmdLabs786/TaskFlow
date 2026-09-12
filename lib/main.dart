import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/task.dart';
import 'models/task_template.dart';
import 'providers/task_provider.dart';
import 'theme/theme_controller.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(RecurrenceTypeAdapter());
  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Task>('tasks_box');
  await TaskTemplate.init();
  await NotificationService.init();

  final themeController = ThemeController();
  await themeController.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const TaskFlowApp(),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          title: 'TaskFlow',
          debugShowCheckedModeBanner: false,
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
