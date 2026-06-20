import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
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
import 'router/app_router.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (_) => const FarmacareApp(),
    ),
  );
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
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
      ),
    );
  }
}
