import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/patients/screens/patients_list_screen.dart';
import '../features/patients/screens/add_patient_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/medications/screens/medications_list_screen.dart';
import '../features/medications/screens/add_medication_screen.dart';
import '../features/medications/screens/medication_detail_screen.dart';
import '../features/caregivers/screens/caregivers_screen.dart';
import '../features/caregivers/screens/invite_caregiver_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/messages/screens/patient_messages_screen.dart';
import '../features/calendar/screens/patient_calendar_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    if (auth.loading) return null;
    final isAuth = auth.isAuthenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register') ||
        state.matchedLocation.startsWith('/forgot-password');
    if (!isAuth && !isAuthRoute) return '/login';
    if (isAuth && isAuthRoute) return '/patients';
    return null;
  },
  refreshListenable: _RouterNotifier(),
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/patients', builder: (_, __) => const PatientsListScreen()),
    GoRoute(path: '/patients/add', builder: (_, __) => const AddPatientScreen()),
    GoRoute(
      path: '/patients/:id/home',
      builder: (_, state) => HomeScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/patients/:id/medications',
      builder: (_, state) => MedicationsListScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/patients/:id/medications/add',
      builder: (_, state) => AddMedicationScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/patients/:id/medications/:medId',
      builder: (_, state) => MedicationDetailScreen(
        patientId: state.pathParameters['id']!,
        medId: state.pathParameters['medId']!,
      ),
    ),
    GoRoute(
      path: '/patients/:id/caregivers',
      builder: (_, state) => CaregiversScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/patients/:id/caregivers/invite',
      builder: (_, state) => InviteCaregiverScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/patients/:id/messages',
      builder: (_, state) => PatientMessagesScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/patients/:id/calendar',
      builder: (_, state) => PatientCalendarScreen(patientId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  ],
);

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier();
}
