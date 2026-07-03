import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart' deferred as onboarding_screen;
import '../screens/dashboard/dashboard_screen.dart' deferred as dashboard;
import '../screens/settings/settings_screen.dart' deferred as settings;
import '../screens/invoices/invoices_screen.dart' deferred as invoices;
import '../screens/quotations/quotations_screen.dart' deferred as quotations;
import '../screens/quotations/create_quotation_screen.dart' deferred as create_quotation_screen;
import '../screens/products/products_screen.dart' deferred as products;
import '../screens/clients/clients_screen.dart' deferred as clients;
import '../screens/clients/add_client_screen.dart' deferred as add_client_screen;
import '../screens/products/add_product_screen.dart' deferred as add_product_screen;
import '../screens/invoices/create_invoice_screen.dart' deferred as create_invoice_screen;
import '../screens/invoices/invoice_detail_screen.dart' deferred as invoice_detail_screen;
import '../screens/invoices/return_items_screen.dart' deferred as return_items_screen;
import '../screens/reports/reports_screen.dart' deferred as reports;
import '../screens/vendors/vendors_screen.dart' deferred as vendors;
import '../screens/vendors/add_vendor_screen.dart' deferred as add_vendor_screen;
import '../screens/purchases/purchase_orders_screen.dart' deferred as purchase_orders;
import '../screens/purchases/create_purchase_order_screen.dart' deferred as create_purchase_order;
import 'app_routes.dart';

part 'app_router.g.dart';

class DeferredWidget extends StatefulWidget {
  const DeferredWidget({
    super.key,
    required this.load,
    required this.builder,
  });

  final Future<void> Function() load;
  final WidgetBuilder builder;

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  Future<void>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error loading page: ${snapshot.error}'),
              ),
            );
          }
          return widget.builder(context);
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xff7C3AED),
            ),
          ),
        );
      },
    );
  }
}

/// ─── appRouterProvider ────────────────────────────────────────────────────────
/// Riverpod-generated provider that vends the [GoRouter] instance.
///
/// Key behaviours:
/// • Watches [authProvider] so the router reacts instantly to login / logout.
/// • Protects all routes under [AppRoutes._protectedRoutes] — unauthenticated
///   users are redirected to [AppRoutes.login].
/// • Authenticated users are redirected away from auth screens to
///   [AppRoutes.dashboard].
/// ─────────────────────────────────────────────────────────────────────────────
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // ── Global Redirect ────────────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final hasCompletedOnboarding = authState.hasCompletedOnboarding;
      final location = state.matchedLocation;

      // Rule 1: Always allow Splash Screen and Dashboard (so they can see the buttons)
      if (location == AppRoutes.splash || location == AppRoutes.dashboard) {
        return null;
      }

      // Rule 2: If trying to access anything else and HAS NOT completed onboarding, intercept!
      if (!hasCompletedOnboarding && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      // Rule 3: If HAS completed onboarding and trying to access onboarding, send to dashboard
      if (hasCompletedOnboarding && location == AppRoutes.onboarding) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    // ── Routes ────────────────────────────────────────────────────────────────
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: onboarding_screen.loadLibrary,
            builder: (context) => onboarding_screen.OnboardingScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Main App ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: dashboard.loadLibrary,
            builder: (context) => dashboard.DashboardScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // The screens below will be implemented in later modules.
      // They use DashboardScreen as a placeholder until dedicated screens exist.

      // ── Invoices (with nested sub-routes) ───────────────────────────────────
      GoRoute(
        path: AppRoutes.invoices,
        name: 'invoices',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: invoices.loadLibrary,
            builder: (context) => invoices.InvoicesScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-invoice',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: create_invoice_screen.loadLibrary,
                builder: (context) => create_invoice_screen.CreateInvoiceScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'invoice-detail',
            pageBuilder: (context, state) {
              final invoiceId = state.pathParameters['id'] ?? '';
              return CustomTransitionPage(
                key: state.pageKey,
                child: DeferredWidget(
                  load: invoice_detail_screen.loadLibrary,
                  builder: (context) =>
                      invoice_detail_screen.InvoiceDetailScreen(invoiceId: invoiceId),
                ),
                transitionsBuilder: _slideTransition,
              );
            },
            routes: [
              GoRoute(
                path: 'return',
                name: 'return-items',
                pageBuilder: (context, state) {
                  final invoiceId = state.pathParameters['id'] ?? '';
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: DeferredWidget(
                      load: return_items_screen.loadLibrary,
                      builder: (context) =>
                          return_items_screen.ReturnItemsScreen(invoiceId: invoiceId),
                    ),
                    transitionsBuilder: _slideTransition,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // ── Quotations (with nested sub-routes) ─────────────────────────────────
      GoRoute(
        path: AppRoutes.quotations,
        name: 'quotations',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: quotations.loadLibrary,
            builder: (context) => quotations.QuotationsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-quotation',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: create_quotation_screen.loadLibrary,
                builder: (context) => create_quotation_screen.CreateQuotationScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),

      // ── Purchase Orders (with nested sub-routes) ─────────────────────────────
      GoRoute(
        path: AppRoutes.purchaseOrders,
        name: 'purchase-orders',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: purchase_orders.loadLibrary,
            builder: (context) => purchase_orders.PurchaseOrdersScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-purchase-order',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: create_purchase_order.loadLibrary,
                builder: (context) => create_purchase_order.CreatePurchaseOrderScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),

      // ── Vendors ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.vendors,
        name: 'vendors',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: vendors.loadLibrary,
            builder: (context) => vendors.VendorsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-vendor',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: add_vendor_screen.loadLibrary,
                builder: (context) => add_vendor_screen.AddVendorScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),

      // ── Clients (with nested sub-routes) ────────────────────────────────────
      GoRoute(
        path: AppRoutes.clients,
        name: 'clients',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: clients.loadLibrary,
            builder: (context) => clients.ClientsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-client',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: add_client_screen.loadLibrary,
                builder: (context) => add_client_screen.AddClientScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),

      // ── Products (with nested sub-routes) ───────────────────────────────────
      GoRoute(
        path: AppRoutes.products,
        name: 'products',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: products.loadLibrary,
            builder: (context) => products.ProductsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-product',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DeferredWidget(
                load: add_product_screen.loadLibrary,
                builder: (context) => add_product_screen.AddProductScreen(),
              ),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),

      // ── History / Reports ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: reports.loadLibrary,
            builder: (context) => reports.ReportsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Settings ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: DeferredWidget(
            load: settings.loadLibrary,
            builder: (context) => settings.SettingsScreen(),
          ),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Misc placeholder routes ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.sendReminder,
        name: 'send-reminder',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'Send Reminder'),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        name: 'expenses',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'Expenses'),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.leads,
        name: 'leads',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'Leads'),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.newLead,
        name: 'new-lead',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _PlaceholderScreen(title: 'New Lead'),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],

    // ── 404 Error Page ────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF6D28D9)),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Shared transition builder ──────────────────────────────────────────────────
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}

/// Slide-from-right transition used for push (drill-down) navigation.
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
    child: child,
  );
}

// ── Temporary Placeholder Screen ───────────────────────────────────────────────
/// Used as a stub for routes that don't have a dedicated screen yet.
/// Will be replaced module by module.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — Coming soon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
