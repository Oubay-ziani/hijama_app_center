import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// Import Screen classes
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/customers/screens/customer_list_screen.dart';
import '../../features/customers/screens/customer_profile_screen.dart';
import '../../features/customers/screens/customer_form_screen.dart';
import '../../features/sessions/screens/session_list_screen.dart';
import '../../features/sessions/screens/session_form_screen.dart';
import '../../features/sessions/screens/session_detail_screen.dart';
import '../../features/appointments/screens/appointment_calendar_screen.dart';
import '../../features/appointments/screens/appointment_form_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/inventory/screens/inventory_list_screen.dart';
import '../../features/inventory/screens/restock_form_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/employees/screens/employee_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final goingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn) {
        return goingToAuth ? null : '/login';
      }
      if (goingToAuth) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/sessions',
        builder: (context, state) => const SessionListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) {
              final customerId = state.uri.queryParameters['customerId'];
              return SessionFormScreen(customerId: customerId);
            },
          ),
          GoRoute(
            path: 'details/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SessionDetailScreen(sessionId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerFormScreen(customerId: id);
            },
          ),
          GoRoute(
            path: 'profile/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerProfileScreen(customerId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const StatisticsScreen(),
        routes: [
          GoRoute(
            path: 'export',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const AppointmentCalendarScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const AppointmentFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AppointmentFormScreen(appointmentId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryListScreen(),
        routes: [
          GoRoute(
            path: 'restock',
            builder: (context, state) => const RestockFormScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/employees',
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
