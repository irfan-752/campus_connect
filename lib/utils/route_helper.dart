import 'package:flutter/material.dart';
import '../student_home.dart';
import '../admin_home.dart';
import '../login.dart';
import '../register.dart';
import '../splash.dart';
import '../screens/mentor/mentor_main_screen.dart';
import '../screens/student/student_resume_builder.dart';
import '../screens/student/student_library.dart';
import '../screens/student/student_placements.dart';
import '../screens/student/student_marketplace.dart';
import '../screens/student/student_clubs.dart';
import '../screens/student/student_attendance_analytics.dart';
import '../screens/student/student_peer_group.dart';
import '../screens/student/student_career_guidance.dart';
import '../screens/alumni/alumni_main_screen.dart';
import '../screens/placement/placement_main_screen.dart';
import '../screens/library/library_admin_screen.dart';

class RouteHelper {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String studentHome = '/student-home';
  static const String adminHome = '/admin-home';
  static const String mentorHome = '/mentor-home';
  static const String alumniHome = '/alumni-home';
  static const String placementHome = '/placement-home';
  static const String libraryAdminHome = '/library-admin-home';

  // Student routes
  static const String studentResumeBuilder = '/student/resume-builder';
  static const String studentLibrary = '/student/library';
  static const String studentPlacements = '/student/placements';
  static const String studentMarketplace = '/student/marketplace';
  static const String studentClubs = '/student/clubs';
  static const String studentAttendanceAnalytics = '/student/attendance-analytics';
  static const String studentPeerGroup = '/student/peer-group';
  static const String studentCareerGuidance = '/student/career-guidance';
  static const String studentAlumni = '/student/alumni';

  // Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return FadePageRoute(child: const CampusSplashScreen());
      case login:
        return ScalePageRoute(child: const LoginPage());
      case register:
        return SlidePageRoute(child: const RegisterScreen(), direction: AxisDirection.up);
      case studentHome:
        return FadePageRoute(child: const StudentHomeScreen());
      case adminHome:
        return FadePageRoute(child: const AdminHomeScreen());
      case mentorHome:
        return SlidePageRoute(child: const MentorHomeScreen());
      case alumniHome:
        return SlidePageRoute(child: const AlumniMainScreen());
      case placementHome:
        return SlidePageRoute(child: const PlacementMainScreen());
      case libraryAdminHome:
        return SlidePageRoute(child: const LibraryAdminScreen());
      // Student routes
      case studentResumeBuilder:
        return FadePageRoute(child: const StudentResumeBuilderScreen());
      case studentLibrary:
        return SlidePageRoute(child: const StudentLibraryScreen());
      case studentPlacements:
        return SlidePageRoute(child: const StudentPlacementsScreen());
      case studentMarketplace:
        return SlidePageRoute(child: const StudentMarketplaceScreen());
      case studentClubs:
        return SlidePageRoute(child: const StudentClubsScreen());
      case studentAttendanceAnalytics:
        return FadePageRoute(child: const StudentAttendanceAnalyticsScreen());
      case studentPeerGroup:
        return SlidePageRoute(child: const StudentPeerGroupScreen());
      case studentCareerGuidance:
        return FadePageRoute(child: const StudentCareerGuidanceScreen());
      case studentAlumni:
        return SlidePageRoute(child: const AlumniMainScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  // Navigation helper methods
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  static void navigateToHome(BuildContext context, String role) {
    String routeName;
    switch (role.toLowerCase()) {
      case 'student':
        routeName = studentHome;
        break;
      case 'teacher':
      case 'mentor':
        routeName = mentorHome;
        break;
      case 'alumni':
        routeName = alumniHome;
        break;
      case 'admin':
        routeName = adminHome;
        break;
      default:
        routeName = login;
    }
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }

  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }
}

// Enhanced slide page transition with fade
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final AxisDirection direction;

  SlidePageRoute({
    required this.child,
    this.direction = AxisDirection.left,
    RouteSettings? settings,
  }) : super(
         settings: settings,
         pageBuilder: (context, animation, _) => child,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           Offset begin;
           switch (direction) {
             case AxisDirection.up:
               begin = const Offset(0.0, 1.0);
               break;
             case AxisDirection.down:
               begin = const Offset(0.0, -1.0);
               break;
             case AxisDirection.right:
               begin = const Offset(-1.0, 0.0);
               break;
             case AxisDirection.left:
               begin = const Offset(1.0, 0.0);
               break;
           }

           const end = Offset.zero;
           const curve = Curves.easeInOutCubic;

           var slideTween = Tween(begin: begin, end: end)
               .chain(CurveTween(curve: curve));
           var fadeTween = Tween(begin: 0.0, end: 1.0)
               .chain(CurveTween(curve: curve));
           var scaleTween = Tween(begin: 0.95, end: 1.0)
               .chain(CurveTween(curve: curve));

           return SlideTransition(
             position: animation.drive(slideTween),
             child: FadeTransition(
               opacity: animation.drive(fadeTween),
               child: ScaleTransition(
                 scale: animation.drive(scaleTween),
                 child: child,
               ),
             ),
           );
         },
         transitionDuration: const Duration(milliseconds: 400),
         reverseTransitionDuration: const Duration(milliseconds: 300),
       );
}

// Enhanced fade page transition with scale
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child, RouteSettings? settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, _) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeTween = Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOutCubic));
          var scaleTween = Tween(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic));

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      );
}

// Scale and fade transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  ScalePageRoute({required this.child, RouteSettings? settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, _) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var scaleTween = Tween(begin: 0.8, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          var fadeTween = Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn));

          return ScaleTransition(
            scale: animation.drive(scaleTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}
