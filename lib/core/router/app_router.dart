import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/products/product_detail_page.dart';
import '../../presentation/pages/products/create_product_page.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/messages/messages_page.dart';
import '../../presentation/pages/messages/chat_page.dart';
import '../../presentation/pages/payment/payment_page.dart';
import '../../presentation/pages/shipping/shipping_tracking_page.dart';
import '../../presentation/pages/dispute/dispute_page.dart';
import '../../presentation/pages/security/security_dashboard_page.dart';
import '../../core/utils/jwt_service.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      // Check if user is authenticated for protected routes
      final isAuthenticated = await JwtService.isAuthenticated();
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isGoingToSplash = state.matchedLocation == '/splash';

      // If not authenticated and trying to access protected route, redirect to login
      if (!isAuthenticated && !isGoingToAuth && !isGoingToSplash) {
        return '/login';
      }

      // If authenticated and trying to access auth pages, redirect to home
      if (isAuthenticated && isGoingToAuth) {
        return '/home';
      }

      return null; // No redirect needed
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Authentication routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainAppShell(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),

          // Search tab
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchPage(),
          ),

          // Messages tab
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesPage(),
          ),

          // Profile tab
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // Product details (outside of shell for full-screen)
      GoRoute(
        path: '/product/:productId',
        name: 'productDetail',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductDetailPage(productId: productId);
        },
      ),

      // Create product (outside of shell for full-screen)
      GoRoute(
        path: '/create-product',
        name: 'createProduct',
        builder: (context, state) => const CreateProductPage(),
      ),

      // Chat page (outside of shell for full-screen)
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatPage(chatId: chatId);
        },
      ),

      // Payment page
      GoRoute(
        path: '/payment/:productId',
        name: 'payment',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          final sellerId = state.uri.queryParameters['sellerId']!;
          final amount = double.parse(state.uri.queryParameters['amount']!);
          // TODO: Get product from repository
          return PaymentPage(
            product: null, // TODO: Load product
            sellerId: sellerId,
            totalAmount: amount,
          );
        },
      ),

      // Shipping tracking
      GoRoute(
        path: '/shipping/:shippingId',
        name: 'shippingTracking',
        builder: (context, state) {
          final shippingId = state.pathParameters['shippingId']!;
          return ShippingTrackingPage(shippingId: shippingId);
        },
      ),

      // Dispute resolution
      GoRoute(
        path: '/dispute/:disputeId',
        name: 'dispute',
        builder: (context, state) {
          final disputeId = state.pathParameters['disputeId']!;
          return DisputePage(disputeId: disputeId);
        },
      ),

      // Security dashboard
      GoRoute(
        path: '/security',
        name: 'security',
        builder: (context, state) => const SecurityDashboardPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('The page "${state.matchedLocation}" was not found.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-product'),
        child: const Icon(Icons.add),
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/home':
        return 0;
      case '/search':
        return 1;
      case '/messages':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/messages');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}