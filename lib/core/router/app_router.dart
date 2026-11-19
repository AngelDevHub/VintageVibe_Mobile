/// VintageVibe Mobile — App Router (GoRouter)
/// Declarative routing with auth-aware redirects.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/publish/presentation/screens/publish_screen.dart';
import '../../features/publish/presentation/screens/my_listings_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cart/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../shared/widgets/vv_shell.dart';

// Route names
class AppRoutes {
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const home = 'home';
  static const productDetail = 'product-detail';
  static const publish = 'publish';
  static const myListings = 'my-listings';
  static const cart = 'cart';
  static const checkout = 'checkout';
  static const orders = 'orders';
  static const profile = 'profile';
  static const favorites = 'favorites';
  static const settings = 'settings';
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        // Solo notificar al router si el estado de autenticación cambió realmente
        // (evita resetear la navegación cuando hay errores de validación o loading)
        if (previous?.isAuthenticated != next.isAuthenticated ||
            previous?.status == AuthStatus.initial) {
          notifyListeners();
        }
      },
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isInitial = authState.status == AuthStatus.initial;
    final currentPath = state.uri.path;

    // While checking session, stay on splash
    if (isInitial) {
      return currentPath == '/' ? null : '/';
    }

    // If we are on the splash screen and initialization is done, navigate away
    if (currentPath == '/') {
      return isAuthenticated ? '/home' : '/login';
    }

    // Auth pages — redirect to home if already logged in
    final isAuthPage = currentPath == '/login' || currentPath == '/register';
    if (isAuthenticated && isAuthPage) return '/home';

    // Protected pages — redirect to login if not authenticated
    final protectedPaths = ['/publish', '/my-listings', '/cart', '/checkout', '/orders', '/profile', '/favorites', '/settings'];
    final isProtected = protectedPaths.any((p) => currentPath.startsWith(p));
    if (!isAuthenticated && isProtected) return '/login';

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => VVShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            builder: (context, state) => const CatalogScreen(),
          ),
          GoRoute(
            path: '/publish',
            name: AppRoutes.publish,
            builder: (context, state) => const PublishScreen(),
          ),
          GoRoute(
            path: '/cart',
            name: AppRoutes.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Detail pages (no bottom nav)
      GoRoute(
        path: '/product/:id',
        name: AppRoutes.productDetail,
        builder: (context, state) => ProductDetailScreen(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/my-listings',
        name: AppRoutes.myListings,
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/orders',
        name: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/favorites',
        name: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
