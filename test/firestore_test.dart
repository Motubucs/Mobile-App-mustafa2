import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../lib/firebase_options.dart';

void main() {
  group('Firestore Connection Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Firestore connection test', () async {
      final firestore = FirebaseFirestore.instance;
      
      // Test write operation
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'connected'
      });
      
      // Test read operation
      final doc = await firestore.collection('test').doc('connection').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['status'], 'connected');
      
      // Clean up
      await firestore.collection('test').doc('connection').delete();
    });

    test('Required collections accessibility test', () async {
      final firestore = FirebaseFirestore.instance;
      
      // Test conversations collection
      final conversationsSnapshot = await firestore.collection('conversations').limit(1).get();
      expect(conversationsSnapshot, isNotNull);
      
      // Test users collection
      final usersSnapshot = await firestore.collection('users').limit(1).get();
      expect(usersSnapshot, isNotNull);
      
      // Test products collection
      final productsSnapshot = await firestore.collection('products').limit(1).get();
      expect(productsSnapshot, isNotNull);
    });
  });
} 