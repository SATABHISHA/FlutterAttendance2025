import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'blocs/blocs.dart';
import 'services/services.dart';
import 'screens/screens.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options (handle already initialized case)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, ignore
    if (e.toString().contains('duplicate-app')) {
      // Already initialized, continue
    } else {
      rethrow;
    }
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        RepositoryProvider<BiometricService>(
          create: (_) => BiometricService(),
        ),
        RepositoryProvider<CompanyService>(
          create: (_) => CompanyService(),
        ),
        RepositoryProvider<AttendanceService>(
          create: (_) => AttendanceService(),
        ),
        RepositoryProvider<TaskService>(
          create: (_) => TaskService(),
        ),
        RepositoryProvider<LocationService>(
          create: (_) => LocationService(),
        ),
        RepositoryProvider<StorageService>(
          create: (_) => StorageService(),
        ),
        RepositoryProvider<ProjectService>(
          create: (_) => ProjectService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authService: context.read<AuthService>(),
              biometricService: context.read<BiometricService>(),
              storageService: context.read<StorageService>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<CompanyBloc>(
            create: (context) => CompanyBloc(
              companyService: context.read<CompanyService>(),
            ),
          ),
          BlocProvider<AttendanceBloc>(
            create: (context) => AttendanceBloc(
              attendanceService: context.read<AttendanceService>(),
              locationService: context.read<LocationService>(),
            ),
          ),
          BlocProvider<TaskBloc>(
            create: (context) => TaskBloc(
              taskService: context.read<TaskService>(),
            ),
          ),
          BlocProvider<ProjectBloc>(
            create: (context) => ProjectBloc(
              projectService: context.read<ProjectService>(),
            ),
          ),
        ],
        child: const AttendanceApp(),
      ),
    );
  }
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.authenticated && state.user != null) {
            if (state.user!.isAdmin) {
              return const AdminDashboardScreen();
            }
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-register': (context) => const AdminRegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/attendance-history': (context) => const AttendanceHistoryScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/assign-task': (context) => const AssignTaskScreen(),
        '/team-attendance': (context) => const TeamAttendanceScreen(),
        '/daily-report': (context) => const DailyReportScreen(),
        '/task-statistics': (context) => const TaskStatisticsScreen(),
        '/subordinate-tasks': (context) => const SubordinateTasksScreen(),
        '/team-reports': (context) => const TeamReportsScreen(),
        '/project-allocation': (context) => const ProjectAllocationScreen(),
        '/task-performance': (context) => const TaskPerformanceScreen(),
        '/attendance-export': (context) => const AttendanceExportScreen(),
      },
    );
  }
}
