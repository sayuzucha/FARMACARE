import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/dose_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/caregiver_provider.dart';
import 'providers/report_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/message_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

void main() {
  // Ping en background para despertar Render antes de que el usuario haga login
  AuthProvider.warmUp();
  FlutterError.onError = (FlutterErrorDetails details) {
    final summary = details.summary.toString();
    if (summary.contains('Cannot hit test a render box that has never been laid out') ||
        summary.contains('!_debugDuringDeviceUpdate') ||
        summary.contains('box.dart:2251') ||
        summary.contains('RenderBox was not laid out') ||
        (details.library == 'rendering library' && summary.contains('Assertion failed') && summary.contains('box.dart'))) {
      debugPrint('[FlutterWeb-known] ${details.summary}');
      return;
    }
    debugPrint('══ FlutterError ══════════════════════════════');
    debugPrint('Summary: ${details.summary}');
    debugPrint('Library: ${details.library}');
    // Print additional context (includes widget where error originated)
    if (details.context != null) debugPrint('Context: ${details.context}');
    // Print informationCollector (contains widget tree path)
    if (details.informationCollector != null) {
      for (final info in details.informationCollector!()) {
        debugPrint('Info: $info');
      }
    }
    // Print stack - filter to only app + framework relevant lines
    int stackLine = 0;
    for (final f in details.stack.toString().split('\n')) {
      if (f.trim().isNotEmpty) {
        debugPrint(f);
        if (++stackLine >= 20) break; // cap at 20 lines
      }
    }
    debugPrint('══════════════════════════════════════════════');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error');
    return false;
  };

  runApp(const FarmacareApp());
}

class FarmacareApp extends StatelessWidget {
  const FarmacareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => DoseProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => CaregiverProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: MaterialApp.router(
        title: 'Farmacare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
