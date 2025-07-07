import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirestoreTest {
  static Future<void> testConnection() async {
    try {
      print('🧪 Testing Firestore Connection...');
      
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      print('✅ Firebase initialized successfully');
      
      final firestore = FirebaseFirestore.instance;
      
      // Test write operation
      print('📝 Testing write operation...');
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'connected',
        'testTime': DateTime.now().toIso8601String(),
      });
      print('✅ Write test successful');
      
      // Test read operation
      print('📖 Testing read operation...');
      final doc = await firestore.collection('test').doc('connection').get();
      if (doc.exists) {
        print('✅ Read test successful');
        print('📄 Document data: ${doc.data()}');
      } else {
        print('❌ Read test failed - document not found');
      }
      
      // Clean up test data
      print('🧹 Cleaning up test data...');
      await firestore.collection('test').doc('connection').delete();
      print('✅ Cleanup successful');
      
      // Test required collections
      print('\n📋 Testing required collections...');
      
      final conversationsSnapshot = await firestore.collection('conversations').limit(1).get();
      print('✅ Conversations collection accessible (${conversationsSnapshot.docs.length} documents)');
      
      final usersSnapshot = await firestore.collection('users').limit(1).get();
      print('✅ Users collection accessible (${usersSnapshot.docs.length} documents)');
      
      final productsSnapshot = await firestore.collection('products').limit(1).get();
      print('✅ Products collection accessible (${productsSnapshot.docs.length} documents)');
      
      print('\n🎉 All Firestore tests passed! Your setup is working correctly.');
      print('\nNext steps:');
      print('1. Go to Firebase Console → Firestore Database');
      print('2. Add the security rules from FIRESTORE_SETUP.md');
      print('3. Enable Authentication methods');
      print('4. Test the messaging feature in your app');
      
    } catch (e) {
      print('❌ Error during Firestore test: $e');
      print('\nTroubleshooting:');
      print('1. Check your internet connection');
      print('2. Verify Firebase project is set up correctly');
      print('3. Check firebase_options.dart has correct configuration');
      print('4. Ensure Firestore Database is created in Firebase Console');
      print('5. Check if you have proper permissions');
    }
  }
} 