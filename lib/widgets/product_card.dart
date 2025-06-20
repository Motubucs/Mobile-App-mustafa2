import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../viewmodels/messages_viewmodel.dart';
import '../views/messages/chat_screen.dart';
import '../theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Report Listing'),
            content: const Text(
              'Are you sure you want to report this listing?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing reported'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Report'),
              ),
            ],
          ),
    );
  }

  void _startChatWithSeller(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Show sign-in prompt
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sign In Required'),
          content: const Text('You need to sign in to message the seller.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(context, '/sign-in');
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      return;
    }

    // Check if user is trying to message themselves
    if (user.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final buyerId = user.uid;
      final sellerId = product.sellerId;
      final productId = product.id;
      final messagesViewModel = Provider.of<MessagesViewModel>(context, listen: false);
      
      // Get or create conversation
      final conversationId = await messagesViewModel.getOrCreateConversation(buyerId, sellerId, productId);
      
      // Get seller information
      final seller = await messagesViewModel.getUserById(sellerId);
      
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              user: seller,
              product: product,
            ),
          ),
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat opened with seller'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistViewModel = Provider.of<WishlistViewModel>(context);
    final isInWishlist = wishlistViewModel.isInWishlist(product.id);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSelfPosted =
        currentUser != null && product.sellerId == currentUser.uid;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate appropriate height based on available width
          final cardWidth = constraints.maxWidth;
          final imageHeight =
              cardWidth * 0.85; // Image takes 85% of width for aspect ratio

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image section
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child:
                            product.image.startsWith('http')
                                ? Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      'https://placehold.co/600x400/png?text=No+Image',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                                : Image.asset(
                                  product.image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      'https://placehold.co/600x400/png?text=No+Image',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                      ),
                      if (!isSelfPosted)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              if (isInWishlist) {
                                wishlistViewModel.removeFromWishlist(
                                  product.id,
                                );
                              } else {
                                wishlistViewModel.addToWishlist(product);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isInWishlist
                                        ? AppColors.primary
                                        : Colors.grey.shade600,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      if (!isSelfPosted)
                        Positioned(
                          top: 8,
                          right: 50, // Position to the left of wishlist button
                          child: InkWell(
                            onTap: () => _startChatWithSeller(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.message,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Product Details - Fixed height content
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 9.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product title with limited height
                      SizedBox(
                        height: 38,
                        child: Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Seller name
                      SizedBox(
                        height: 18,
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: StreamBuilder<DocumentSnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(product.sellerId)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data!.exists) {
                                    final userData =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>;
                                    return Text(
                                      userData['name'] ?? 'Unknown Seller',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                  return Text(
                                    'Unknown Seller',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Price and menu row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price and Timestamp
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RM ${product.price.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  product.timeAgo,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // Kebab Menu
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () => _showReportDialog(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
