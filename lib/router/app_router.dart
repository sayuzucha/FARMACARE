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
import '../features/patients/screens/join_patient_screen.dart';

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
    GoRoute(
      path: '/login',
      pageBuilder: (_, state) => NoTransitionPage(child: LoginScreen(extra: state.extra as Map<String, dynamic>?)),
    ),
    GoRoute(path: '/register', pageBuilder: (_, __) => const NoTransitionPage(child: RegisterScreen())),
    GoRoute(path: '/forgot-password', pageBuilder: (_, __) => const NoTransitionPage(child: ForgotPasswordScreen())),
    GoRoute(path: '/patients', pageBuilder: (_, __) => const NoTransitionPage(child: PatientsListScreen())),
    GoRoute(path: '/patients/add', pageBuilder: (_, __) => const NoTransitionPage(child: AddPatientScreen())),
    GoRoute(path: '/patients/join', pageBuilder: (_, __) => const NoTransitionPage(child: JoinPatientScreen())),
    GoRoute(
      path: '/patients/:id/home',
      pageBuilder: (_, state) => NoTransitionPage(child: HomeScreen(patientId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/patients/:id/medications',
      pageBuilder: (_, state) => NoTransitionPage(child: MedicationsListScreen(patientId: state.pathParameters['id']!)),
      routes: [
        GoRoute(
          path: 'add',
          pageBuilder: (_, state) => NoTransitionPage(child: AddMedicationScreen(patientId: state.pathParameters['id']!)),
        ),
        GoRoute(
          path: ':medId',
          pageBuilder: (_, state) => NoTransitionPage(child: MedicationDetailScreen(
            patientId: state.pathParameters['id']!,
            medId: state.pathParameters['medId']!,
          )),
        ),
      ],
    ),
    GoRoute(
      path: '/patients/:id/caregivers',
      pageBuilder: (_, state) => NoTransitionPage(child: CaregiversScreen(patientId: state.pathParameters['id']!)),
      routes: [
        GoRoute(
          path: 'invite',
          pageBuilder: (_, state) => NoTransitionPage(child: InviteCaregiverScreen(patientId: state.pathParameters['id']!)),
        ),
      ],
    ),
    GoRoute(
      path: '/patients/:id/messages',
      pageBuilder: (_, state) => NoTransitionPage(child: PatientMessagesScreen(patientId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/patients/:id/calendar',
      pageBuilder: (_, state) => NoTransitionPage(child: PatientCalendarScreen(patientId: state.pathParameters['id']!)),
    ),
    GoRoute(path: '/reports', pageBuilder: (_, __) => const NoTransitionPage(child: ReportsScreen())),
    GoRoute(path: '/notifications', pageBuilder: (_, __) => const NoTransitionPage(child: NotificationsScreen())),
    GoRoute(path: '/profile', pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen())),
  ],
);

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier();
}
