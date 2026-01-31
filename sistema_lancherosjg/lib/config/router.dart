import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/dispatch_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/guardia_screen.dart';
import '../screens/choferes_apoyo_screen.dart';

/// Configuración de rutas de la aplicación
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/tabla',
      name: 'tabla',
      builder: (context, state) => const DispatchScreen(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminScreen(),
    ),
    GoRoute(
      path: '/guardia',
      name: 'guardia',
      builder: (context, state) => const GuardiaScreen(),
    ),
    GoRoute(
      path: '/apoyos',
      name: 'apoyos',
      builder: (context, state) => const ChoferesApoyoScreen(),
    ),
  ],
);
