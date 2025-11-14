import 'package:flutter/material.dart';
import '../student_home.dart';
import '../parent_home.dart';
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
  static const String parentHome = '/parent-home';
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
        return MaterialPageRoute(builder: (_) => const CampusSplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case studentHome:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
      case parentHome:
        return MaterialPageRoute(builder: (_) => const ParentHomeScreen());
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      case mentorHome:
        return MaterialPageRoute(builder: (_) => const MentorHomeScreen());
      case alumniHome:
        return MaterialPageRoute(builder: (_) => const AlumniMainScreen());
      case placementHome:
        return MaterialPageRoute(builder: (_) => const PlacementMainScreen());
      case libraryAdminHome:
        return MaterialPageRoute(builder: (_) => const LibraryAdminScreen());
      // Student routes
      case studentResumeBuilder:
        return MaterialPageRoute(builder: (_) => const StudentResumeBuilderScreen());
      case studentLibrary:
        return MaterialPageRoute(builder: (_) => const StudentLibraryScreen());
      case studentPlacements:
        return MaterialPageRoute(builder: (_) => const StudentPlacementsScreen());
      case studentMarketplace:
        return MaterialPageRoute(builder: (_) => const StudentMarketplaceScreen());
      case studentClubs:
        return MaterialPageRoute(builder: (_) => const StudentClubsScreen());
      case studentAttendanceAnalytics:
        return MaterialPageRoute(builder: (_) => const StudentAttendanceAnalyticsScreen());
      case studentPeerGroup:
        return MaterialPageRoute(builder: (_) => const StudentPeerGroupScreen());
      case studentCareerGuidance:
        return MaterialPageRoute(builder: (_) => const StudentCareerGuidanceScreen());
      case studentAlumni:
        return MaterialPageRoute(builder: (_) => const AlumniMainScreen());
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
      case 'parent':
        routeName = parentHome;
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

// Custom page transition
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
           const curve = Curves.easeInOut;

           var tween = Tween(
             begin: begin,
             end: end,
           ).chain(CurveTween(curve: curve));

           return SlideTransition(
             position: animation.drive(tween),
             child: child,
           );
         },
         transitionDuration: const Duration(milliseconds: 300),
       );
}

// Fade page transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child, RouteSettings? settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, _) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}
