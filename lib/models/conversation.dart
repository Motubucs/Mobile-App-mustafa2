import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart';
import 'user.dart' as app_user;
import 'product.dart';

class Conversation {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final DateTime createdAt;
  final app_user.User? user;
  final Message? lastMessage;
  final Product? product;

  Conversation({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.createdAt,
    this.user,
    this.lastMessage,
    this.product,
  });

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    return Conversation(
      id: id,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productId: map['productId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      user: map['user'] != null ? app_user.User.fromMap(map['user']) : null,
      lastMessage: map['lastMessage'] != null ? Message.fromMap(map['lastMessageId'] ?? '', map['lastMessage']) : null,
      product: map['product'] != null ? Product.fromMap(map['productId'], map['product']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'createdAt': Timestamp.fromDate(createdAt),
      'user': user?.toMap(),
      'lastMessage': lastMessage?.toMap(),
      'product': product?.toMap(),
    };
  }
}
