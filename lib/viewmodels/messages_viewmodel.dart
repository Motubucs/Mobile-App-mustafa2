import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/product.dart';
import '../models/user.dart' as app_user;
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesViewModel extends ChangeNotifier {
  final MessagingService _messagingService = MessagingService();

  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  String? _currentConversationId;
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _conversations = await _messagingService.getConversations();
    } catch (e) {
      _error = 'Failed to load conversations: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load messages for a specific conversation
  Future<void> loadMessages(String conversationId) async {
    _currentConversationId = conversationId;
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _messages = await _messagingService.getMessages(conversationId);
    } catch (e) {
      _error = 'Failed to load messages: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message in the current conversation
  Future<void> sendMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _messagingService.sendMessage(conversationId, text);
      await loadMessages(conversationId); // Reload messages to show the new one

      // --- Notification logic ---
      // Fetch conversation details
      final firestore = FirebaseFirestore.instance;
      final conversationDoc = await firestore.collection('conversations').doc(conversationId).get();
      if (!conversationDoc.exists) return;
      final data = conversationDoc.data()!;
      final buyerId = data['buyerId'] as String;
      final sellerId = data['sellerId'] as String;
      final productId = data['productId'] as String;
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      final senderId = currentUser.uid;
      // Only notify if sender is the seller
      if (senderId == sellerId) {
        // Get buyer user info
        final buyerDoc = await firestore.collection('users').doc(buyerId).get();
        final buyer = app_user.User.fromMap(buyerDoc.data()!);
        // Get seller user info
        final sellerDoc = await firestore.collection('users').doc(sellerId).get();
        final seller = app_user.User.fromMap(sellerDoc.data()!);
        // Get product info
        final productDoc = await firestore.collection('products').doc(productId).get();
        final product = Product.fromMap(productDoc.id, productDoc.data()!);
        // Send notification to buyer
        await NotificationService().sendMessageNotification(
          toUserId: buyerId,
          fromUserName: seller.name,
          productTitle: product.title,
          conversationId: conversationId,
        );
      }
      // --- End notification logic ---
    } catch (e) {
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get or create a conversation between buyer and seller for a product
  Future<String> getOrCreateConversation(String buyerId, String sellerId, String productId) async {
    return await _messagingService.getOrCreateConversation(buyerId, sellerId, productId);
  }

  // Get user by ID
  Future<app_user.User> getUserById(String userId) async {
    return await _messagingService.getUserById(userId);
  }
}
