import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/satellite_analysis_screen.dart';
import 'screens/farm_boundary_screen.dart';
import 'screens/fertilizer_screen.dart';
import 'screens/climate_screen.dart';
import 'screens/sell_carbon_screen.dart';
import 'screens/carbon_report_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sensor_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/seasonal_comparison_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/app_strings.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.loadFromPrefs();
  runApp(const AgriCarbonApp());
}

final _shellKey = GlobalKey<NavigatorState>();

// Stores profile state after login so redirect stays synchronous
bool _profileChecked = false;
bool _hasProfile     = false;

/// Called by RegisterScreen after profile save, and reset on logout
void setProfileChecked(bool hasProfile) {
  _profileChecked = true;
  _hasProfile     = hasProfile;
}

final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: AuthService.instance,
  redirect: (context, state) {
    final loggedIn = AuthService.instance.isLoggedIn;
    final loc      = state.matchedLocation;

    if (!loggedIn) {
      _profileChecked = false;
      _hasProfile     = false;
      if (loc == '/login' || loc == '/') return null;
      return '/login';
    }

    // Logged in but profile not yet checked → go to a loading route
    if (!_profileChecked) {
      // kick off the check without blocking
      if (loc != '/_checking') {
        FirestoreService.instance.profileExists().then((exists) {
          _profileChecked = true;
          _hasProfile     = exists;
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          AuthService.instance.notifyListeners();
        });
        return '/_checking';
      }
      return null;
    }

    if (loc == '/' || loc == '/login' || loc == '/_checking') {
      return _hasProfile ? '/dashboard' : '/register';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/',          builder: (ctx, st) => const SplashScreen()),
    GoRoute(path: '/login',     builder: (ctx, st) => const LoginScreen()),
    GoRoute(path: '/register',  builder: (ctx, st) => const RegisterScreen()),
    GoRoute(
      path: '/_checking',
      builder: (ctx, st) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    ),
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => _Shell(
        location: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(path: '/dashboard',  builder: (ctx, st) => const DashboardScreen()),
        GoRoute(path: '/scan',       builder: (ctx, st) => const SatelliteAnalysisScreen()),
        GoRoute(path: '/carbon',     builder: (ctx, st) => const CarbonReportScreen()),
        GoRoute(path: '/fertilizer', builder: (ctx, st) => const FertilizerScreen()),
        GoRoute(path: '/climate',    builder: (ctx, st) => const ClimateScreen()),
        GoRoute(path: '/sell',       builder: (ctx, st) => const SellCarbonScreen()),
        GoRoute(path: '/reports',    builder: (ctx, st) => const ReportsScreen()),
        GoRoute(path: '/profile',    builder: (ctx, st) => const ProfileScreen()),
        GoRoute(path: '/sensors',    builder: (ctx, st) => const SensorScreen()),
        GoRoute(path: '/boundary',   builder: (ctx, st) => const FarmBoundaryScreen()),
      ],
    ),
    GoRoute(
      path: '/payment',
      builder: (ctx, st) {
        final extra = st.extra as Map<String, dynamic>? ?? {};
        return PaymentScreen(
          creditId: extra['creditId'] as String? ?? '',
          amount: (extra['amount'] as num?)?.toDouble() ?? 0.0,
          creditsCount: (extra['creditsCount'] as num?)?.toDouble() ?? 0.0,
        );
      },
    ),
    GoRoute(path: '/seasonal', builder: (ctx, st) => const SeasonalComparisonScreen()),
    GoRoute(path: '/camera',   builder: (ctx, st) => const CameraScreen()),
  ],
);

class AgriCarbonApp extends StatefulWidget {
  const AgriCarbonApp({super.key});
  @override
  State<AgriCarbonApp> createState() => _AgriCarbonAppState();
}

class _AgriCarbonAppState extends State<AgriCarbonApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.init(router: _router);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LangProvider(
      child: MaterialApp.router(
        title: 'CROP+',
        theme: appTheme(),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ── Bottom Navigation Shell ───────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  final Widget child;
  final String location;
  const _Shell({required this.child, required this.location});

  static const _tabs = [
    _Tab('/dashboard', Icons.home_outlined,         Icons.home_rounded,         'Home'),
    _Tab('/scan',      Icons.satellite_alt_outlined, Icons.satellite_alt_rounded, 'Satellite'),
    _Tab('/carbon',    Icons.eco_outlined,           Icons.eco_rounded,          'Carbon'),
    _Tab('/reports',   Icons.bar_chart_outlined,     Icons.bar_chart_rounded,    'Reports'),
    _Tab('/profile',   Icons.person_outline_rounded, Icons.person_rounded,       'Profile'),
  ];

  int get _idx {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final tabLabels = [t.navHome, t.navSatellite, t.navCarbon, t.navReports, t.navProfile];
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface1,
          border: Border(top: BorderSide(color: kBorder, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _idx,
          backgroundColor: kSurface1,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: kGreenTint,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => context.go(_tabs[i].route),
          destinations: _tabs.asMap().entries
              .map((e) => NavigationDestination(
                    icon: Icon(e.value.outline, size: 22),
                    selectedIcon: Icon(e.value.filled, color: kGreen, size: 22),
                    label: tabLabels[e.key],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Tab {
  final String route, label;
  final IconData outline, filled;
  const _Tab(this.route, this.outline, this.filled, this.label);
}
