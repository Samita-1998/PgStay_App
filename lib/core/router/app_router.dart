import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/widgets/main_layout.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/auth/screens/login_screen.dart';
import 'package:pgstay/features/auth/screens/register_screen.dart';
import 'package:pgstay/features/auth/screens/splash_screen.dart';
import 'package:pgstay/features/auth/screens/forgot_password_screen.dart';
import 'package:pgstay/features/auth/screens/otp_verification_screen.dart';
import 'package:pgstay/features/pg_listing/screens/home_screen.dart';
import 'package:pgstay/features/pg_listing/screens/pg_details_screen.dart';
import 'package:pgstay/features/pg_listing/screens/my_pgs_screen.dart';
import 'package:pgstay/features/enquiries/screens/enquiries_screen.dart';
import 'package:pgstay/features/profile/screens/profile_screen.dart';
import 'package:pgstay/features/enquiries/screens/owner_enquiries_screen.dart';
import 'package:pgstay/features/manager/screens/manager_dashboard_screen.dart';
import 'package:pgstay/features/staff/screens/staff_dashboard_screen.dart';
import 'package:pgstay/features/booking/screens/booking_flow_screen.dart';
import 'package:pgstay/features/booking/screens/booking_success_screen.dart';
import 'package:pgstay/features/complaints/screens/complaints_list_screen.dart';
import 'package:pgstay/features/complaints/screens/create_complaint_screen.dart';
import 'package:pgstay/features/notifications/screens/notifications_screen.dart';
import 'package:pgstay/features/pg_listing/screens/vacancy_posts_screen.dart';
import 'package:pgstay/features/rent/screens/rent_tracker_screen.dart';
import 'package:pgstay/features/rent/screens/owner_rent_screen.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref.read(authProvider.notifier).stream),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      if (authState.isLoading) {
        return null;
      }

      final user = authState.valueOrNull;
      final currentLoc = state.matchedLocation;
      
      final isAuthFlow = currentLoc == '/login' || 
                         currentLoc == '/register' || 
                         currentLoc == '/forgot-password' || 
                         currentLoc == '/otp' ||
                         currentLoc == '/splash';

      if (user == null) {
        if (!isAuthFlow) {
          return '/splash';
        }
      } else {
        if (isAuthFlow) {
          // Route user to appropriate landing dashboard based on role
          final role = user.role.toLowerCase();
          if (role == 'owner') {
            return '/home';
          } else if (role == 'manager') {
            return '/manager/dashboard';
          } else if (role == 'employee' || role == 'staff') {
            return '/staff/dashboard';
          } else {
            return '/home'; // Default user/tenant discover page
          }
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/otp',
        builder: (context, state) {
          final email = state.extra as String? ?? 'your email';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pg-details/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PgDetailsScreen(postId: postId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking-flow',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BookingFlowScreen(
            pgId: extra['pgId'] ?? '',
            pgName: extra['pgName'] ?? 'PG Name',
            roomId: extra['roomId'] ?? '',
            roomType: extra['roomType'] ?? 'Standard Room',
            pricePerMonth: extra['pricePerMonth'] ?? 0.0,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/booking-success',
        builder: (context, state) => const BookingSuccessScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/complaints',
        builder: (context, state) => const ComplaintsListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/complaints/create',
        builder: (context, state) => const CreateComplaintScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/my-pgs',
            builder: (context, state) => const MyPgsScreen(),
          ),
          GoRoute(
            path: '/vacancies',
            builder: (context, state) => const VacancyPostsScreen(),
          ),
          GoRoute(
            path: '/enquiries',
            builder: (context, state) => const EnquiriesScreen(),
          ),
          GoRoute(
            path: '/rent',
            builder: (context, state) => const RentTrackerScreen(),
          ),
          GoRoute(
            path: '/owner-rent',
            builder: (context, state) => const OwnerRentScreen(),
          ),
          GoRoute(
            path: '/owner-enquiries',
            builder: (context, state) => const OwnerEnquiriesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/manager/dashboard',
            builder: (context, state) => const ManagerDashboardScreen(),
          ),
          GoRoute(
            path: '/staff/dashboard',
            builder: (context, state) => const StaffDashboardScreen(),
          ),
        ],
      ),
    ],
  );
});
