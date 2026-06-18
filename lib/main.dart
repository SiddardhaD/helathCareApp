import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/mock_auth_repository.dart';
import 'features/documents/data/datasources/document_local_datasource.dart';
import 'features/medications/data/datasources/medication_local_datasource.dart';
import 'features/reminders/data/datasources/reminder_local_datasource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Future.wait([
    MockAuthRepository.ensureBoxOpen(),
    MedicationLocalDataSource.ensureBoxesOpen(),
    ReminderLocalDataSource.ensureBoxOpen(),
    DocumentLocalDataSource.ensureBoxOpen(),
  ]);

  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  runApp(const ProviderScope(child: HealthCompanionApp()));
}

class HealthCompanionApp extends ConsumerWidget {
  const HealthCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Health Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
