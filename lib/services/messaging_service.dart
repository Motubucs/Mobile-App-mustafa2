import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _conversationsCollection = 'conversations';
  final String _messagesCollection = 'messages';

  // Get conversations for a user
  Future<List<Conversation>> getConversations() async {
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      final currentUserId = currentUser.uid;

      final snapshot =
          await _firestore
              .collection(_conversationsCollection)
              .where('participants', arrayContains: currentUserId)
              .orderBy('lastMessageTime', descending: true)
              .get();

      return await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();

          // Get the other participant's user data
          final otherUserId =
              (data['participants'] as List).firstWhere(
                    (id) => id != currentUserId,
                  )
                  as String;
          
          User? user;
          try {
            final userDoc = await _firestore.collection('users').doc(otherUserId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              user = User.fromMap(userData);
            }
          } catch (e) {
            print('Failed to load user $otherUserId: $e');
          }

          // Get the product data
          Product? product;
          try {
            final productDoc = await _firestore
                .collection('products')
                .doc(data['productId'])
                .get();
            if (productDoc.exists) {
              final productData = productDoc.data()!;
              product = Product.fromMap(productDoc.id, productData);
            }
          } catch (e) {
            print('Failed to load product ${data['productId']}: $e');
          }

          return Conversation(
            id: doc.id,
            buyerId: data['buyerId'] ?? '',
            sellerId: data['sellerId'] ?? '',
            productId: data['productId'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            user: user,
            lastMessage: (data['lastMessageId'] != null && data['lastMessageSender'] != null && data['lastMessageText'] != null && data['lastMessageTime'] != null)
              ? Message(
                  id: data['lastMessageId'],
                  sender: data['lastMessageSender'],
                  text: data['lastMessageText'],
                  time: (data['lastMessageTime'] as Timestamp).toDate(),
                )
              : null,
            product: product,
          );
        }),
      );
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_conversationsCollection)
              .doc(conversationId)
              .collection(_messagesCollection)
              .orderBy('timestamp', descending: false)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          sender: data['sender'] as String,
          text: data['text'] as String,
          time: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // Send a message
  Future<bool> sendMessage(String conversationId, String text) async {
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      final currentUserId = currentUser.uid;

      final message = {
        'sender': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final messageRef = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .add(message);

      // Update conversation with last message
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
            'lastMessageId': messageRef.id,
            'lastMessageText': text,
            'lastMessageTime': message['timestamp'],
            'lastMessageSender': currentUserId,
          });

      return true;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get or create a conversation between buyer and seller for a product
  Future<String> getOrCreateConversation(String buyerId, String sellerId, String productId) async {
    try {
      // Check if conversation exists
      final query = await _firestore
        .collection(_conversationsCollection)
        .where('buyerId', isEqualTo: buyerId)
        .where('sellerId', isEqualTo: sellerId)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      // Create new conversation
      final conversation = {
        'buyerId': buyerId,
        'sellerId': sellerId,
        'productId': productId,
        'participants': [buyerId, sellerId],
        'createdAt': FieldValue.serverTimestamp(),
      };
      final docRef = await _firestore.collection(_conversationsCollection).add(conversation);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  // Get user by ID
  Future<User> getUserById(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    return User.fromMap(userDoc.data()!);
  }

  // Update createConversation to use buyerId and sellerId
  Future<String> createConversation(String buyerId, String sellerId, String productId) async {
    try {
      final conversation = {
        'buyerId': buyerId,
        'sellerId': sellerId,
        'productId': productId,
        'participants': [buyerId, sellerId],
        'createdAt': FieldValue.serverTimestamp(),
      };
      final docRef = await _firestore.collection(_conversationsCollection).add(conversation);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Convenience method to start a chat with a seller
  Future<Map<String, dynamic>> startChatWithSeller(String buyerId, String sellerId, String productId) async {
    try {
      // Get or create conversation
      final conversationId = await getOrCreateConversation(buyerId, sellerId, productId);
      
      // Get seller information
      final seller = await getUserById(sellerId);
      
      // Get product information
      final productDoc = await _firestore.collection('products').doc(productId).get();
      final product = Product.fromMap(productDoc.id, productDoc.data()!);
      
      return {
        'conversationId': conversationId,
        'seller': seller,
        'product': product,
      };
    } catch (e) {
      throw Exception('Failed to start chat with seller: $e');
    }
  }
}
