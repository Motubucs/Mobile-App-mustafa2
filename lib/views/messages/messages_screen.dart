import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/messages_viewmodel.dart';
import '../messages/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import '../../models/user.dart';

// Global navigator key for safe navigation
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final int _currentIndex = 0; // Home tab
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Load conversations when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        Provider.of<MessagesViewModel>(
          context,
          listen: false,
        ).loadConversations();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    
    // Check if widget is still mounted and not disposed before navigating
    if (!mounted || _isDisposed) return;

    // Store context reference
    final currentContext = context;

    switch (index) {
      case 0:
        try {
          Navigator.pushReplacementNamed(currentContext, '/home');
        } catch (e) {
          print('Navigation error: $e');
        }
        break;
      case 1:
        try {
          Navigator.pushReplacementNamed(currentContext, '/search');
        } catch (e) {
          print('Navigation error: $e');
        }
        break;
      case 2:
        try {
          Navigator.pushNamed(currentContext, '/create-listing');
        } catch (e) {
          print('Navigation error: $e');
        }
        break;
      case 3:
        try {
          Navigator.pushReplacementNamed(currentContext, '/wishlist');
        } catch (e) {
          print('Navigation error: $e');
        }
        break;
      case 4:
        try {
          Navigator.pushReplacementNamed(currentContext, '/profile');
        } catch (e) {
          print('Navigation error: $e');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Messages'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (mounted && !_isDisposed) {
                  try {
                    Navigator.pop(context);
                  } catch (e) {
                    print('Back navigation error: $e');
                  }
                }
              },
            ),
          ),
          body:
              viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.error.isNotEmpty
                  ? Center(child: Text(viewModel.error))
                  : viewModel.conversations.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When you contact a seller or receive messages, they\'ll appear here',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: viewModel.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = viewModel.conversations[index];
                      final isUnread = conversation.lastMessage?.sender != 'You';

                      return InkWell(
                        onTap: () {
                          // Check if widget is being disposed
                          if (_isDisposed) return;
                          
                          // Use a safer navigation approach without async operations in onTap
                          _handleChatNavigation(conversation);
                        },
                        child: Container(
                          color:
                              isUnread
                                  ? AppColors.accent.withOpacity(0.1)
                                  : null,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User Avatar with Online Indicator
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: _getImageProvider(
                                            conversation.user?.avatar ?? 'assets/images/placeholder.png',
                                          ),
                                          onBackgroundImageError: (exception, stackTrace) {
                                            // Handle image loading error
                                            debugPrint('Failed to load user avatar: $exception');
                                          },
                                        ),
                                        if (conversation.user?.online == true)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),

                                    // Message Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // User Name and Time
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                conversation.user?.name ?? '',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          isUnread
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                              ),
                                              Text(
                                                _formatTime(
                                                  conversation.lastMessage?.time ?? DateTime.now(),
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      isUnread
                                                          ? AppColors.primary
                                                          : Colors.grey,
                                                  fontWeight:
                                                      isUnread
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // Last Message
                                          Text(
                                            '${conversation.lastMessage?.sender == "You" ? "You: " : ""}${conversation.lastMessage?.text ?? ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color:
                                                  isUnread
                                                      ? Colors.black
                                                      : Colors.grey[600],
                                              fontWeight:
                                                  isUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Product Info
                                          Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image(
                                                  width: 40,
                                                  height: 40,
                                                  image: _getImageProvider(
                                                    conversation.product?.image ?? 'assets/images/placeholder.png',
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(4),
                                                        color: Colors.grey[300],
                                                      ),
                                                      child: const Icon(
                                                        Icons.image_not_supported,
                                                        size: 20,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      conversation.product?.title ?? '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall,
                                                    ),
                                                    Text(
                                                      'RM ${conversation.product?.price?.toStringAsFixed(2) ?? ''}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavBarTap,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else {
      // Fallback to placeholder image
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  void _handleChatNavigation(Conversation conversation) {
    // Check if widget is being disposed
    if (_isDisposed) return;
    
    // Store the conversation data for navigation
    final conversationId = conversation.id;
    final user = conversation.user;
    final product = conversation.product;
    final sellerId = conversation.sellerId;
    final productId = conversation.productId;
    
    // Use a post-frame callback to ensure the widget is still active
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if widget is still mounted and not disposed
      if (!mounted || _isDisposed) return;
      
      try {
        // Set current conversation ID
        await viewModel.loadMessages(conversationId);
        
        // Debug: Print conversation data
        print('Conversation ID: $conversationId');
        print('User: ${user?.name ?? 'null'}');
        print('Product: ${product?.title ?? 'null'}');
        
        // Check again if widget is still mounted and not disposed
        if (!mounted || _isDisposed) return;
        
        if (user != null && product != null) {
          // Navigate with existing data
          _safeNavigateToChat(conversationId, user, product);
        } else {
          // Load missing data and navigate
          await _loadAndNavigateToChat(conversationId, sellerId, productId);
        }
      } catch (e) {
        print('Error in chat navigation: $e');
        if (mounted && !_isDisposed) {
          _showErrorSnackBar('Failed to load conversation: ${e.toString()}');
        }
      }
    });
  }
  
  void _safeNavigateToChat(String conversationId, User user, Product product) {
    if (!mounted || _isDisposed) return;
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            user: user,
            product: product,
          ),
        ),
      );
    } catch (e) {
      print('Navigation error: $e');
    }
  }
  
  Future<void> _loadAndNavigateToChat(String conversationId, String sellerId, String productId) async {
    if (!mounted || _isDisposed) return;
    
    try {
      final messagesViewModel = Provider.of<MessagesViewModel>(context, listen: false);
      final user = await messagesViewModel.getUserById(sellerId);
      
      if (!mounted || _isDisposed) return;
      
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      
      if (!mounted || _isDisposed) return;
      
      if (productDoc.exists) {
        final product = Product.fromMap(productDoc.id, productDoc.data()!);
        _safeNavigateToChat(conversationId, user, product);
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      print('Error loading chat data: $e');
      if (mounted && !_isDisposed) {
        _showErrorSnackBar('Unable to load conversation details: ${e.toString()}');
        
        // Try to navigate with placeholder data
        _safeNavigateToChat(
          conversationId,
          User(
            uid: sellerId,
            name: 'Unknown User',
            email: '',
            avatar: 'assets/images/placeholder.png',
            online: false,
          ),
          Product(
            id: productId,
            title: 'Unknown Product',
            price: 0,
            description: '',
            image: 'assets/images/placeholder.png',
            images: ['assets/images/placeholder.png'],
            category: '',
            condition: '',
            createdAt: DateTime.now(),
            sellerId: sellerId,
            active: true,
            views: 0,
          ),
        );
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted || _isDisposed) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Snackbar error: $e');
    }
  }
}
