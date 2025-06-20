import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'models/user.dart';
import 'models/product.dart';
import 'views/auth/sign_in_screen.dart';
import 'views/home/home_screen.dart';
import 'views/product/product_detail_screen.dart';
import 'views/search/search_screen.dart';
import 'views/create_listing/create_listing_screen.dart';
import 'views/my_listings/my_listings_screen.dart';
import 'views/profile/profile_screen.dart';
import 'views/profile/edit_profile_screen.dart';
import 'views/wishlist/wishlist_screen.dart';
import 'views/messages/messages_screen.dart';
import 'views/messages/chat_screen.dart';
import 'views/notifications/notifications_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/listing_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/wishlist_viewmodel.dart';
import 'viewmodels/messages_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/firestore_test.dart';

// Custom error widget to show more helpful error messages
class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorWidget({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorDetails.exceptionAsString(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Try to restart the app
                runApp(const MyApp());
              },
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  print('Handling background message:  A${message.messageId}');
}

void main() async {
  // Catch any errors that occur during Flutter initialization
  runZonedGuarded(
    () async {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Set custom error widget
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return CustomErrorWidget(errorDetails: details);
      };

      try {
        // Fix for platform channel errors
        await SystemChannels.platform.invokeMethod<void>(
          'SystemChrome.restoreSystemUIOverlays',
        );

        // Initialize Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Initialize Firebase App Check
        await FirebaseAppCheck.instance.activate(
          // Use debug provider for development
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );

        // Pre-initialize ImagePicker to test if it works
        final ImagePicker picker = ImagePicker();
        // Try a quick test access to the plugin
        try {
          // Just access the instance to see if it throws
          picker.toString();
          debugPrint('ImagePicker initialized successfully');
        } catch (e) {
          debugPrint('Warning: ImagePicker test failed: $e');
        }

        // --- FCM SETUP START ---
        // Set up background handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Request notification permissions (iOS & Android)
        await FirebaseMessaging.instance.requestPermission();

        // Get and save FCM token
        final user = await getCurrentUser(); // Implement this to get the current user
        String? token = await FirebaseMessaging.instance.getToken();
        if (user != null && token != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
        }
        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          if (user != null && newToken != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': newToken});
          }
        });

        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message.notification!.title ?? 'Notification'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        });

        // Listen for notification taps
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final data = message.data;
          final context = navigatorKey.currentContext;
          if (context != null && data.isNotEmpty) {
            // Example: Navigate to chat or product screen
            if (data['type'] == 'message' && data['conversationId'] != null) {
              Navigator.pushNamed(context, '/messages/${data['conversationId']}');
            } else if (data['type'] == 'product' && data['productId'] != null) {
              Navigator.pushNamed(context, '/product/${data['productId']}');
            }
          }
        });
        // --- FCM SETUP END ---

        // Test Firestore connection in debug mode
        if (kDebugMode) {
          await FirestoreTest.testConnection();
        }

        // Run the app
        runApp(const MyApp());
      } catch (e, stackTrace) {
        debugPrint('Error during initialization: $e');
        debugPrint('Stack trace: $stackTrace');
        // Show a minimal error app if something goes wrong
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error initializing app: $e')),
            ),
            debugShowCheckedModeBanner: false,
          ),
        );
      }
    },
    (error, stackTrace) {
      // Handle any errors that occur during app execution
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

// Add a global navigator key for navigation from FCM handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Implement this function to get the current user (replace with your auth logic)
Future<User?> getCurrentUser() async {
  // Example: Use FirebaseAuth
  // import 'package:firebase_auth/firebase_auth.dart';
  // return FirebaseAuth.instance.currentUser;
  return null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => ListingViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => WishlistViewModel()),
        ChangeNotifierProvider(create: (_) => MessagesViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
      ],
      child: MaterialApp(
        title: 'campuscart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        initialRoute: '/sign-in',
        routes: {
          '/sign-in': (context) => const SignInScreen(),
          '/home': (context) => const HomeScreen(),
          '/search': (context) => const SearchScreen(),
          '/create-listing': (context) => const CreateListingScreen(),
          '/my-listings': (context) => const MyListingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/profile/edit': (context) => const EditProfileScreen(),
          '/wishlist': (context) => const WishlistScreen(),
          '/messages': (context) => const MessagesScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name?.startsWith('/product/') ?? false) {
            final productId = settings.name!.split('/')[2];
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId),
            );
          }
          return null;
        },
      ),
    );
  }
}
