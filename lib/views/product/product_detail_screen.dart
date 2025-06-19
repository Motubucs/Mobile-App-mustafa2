import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/wishlist_viewmodel.dart';
import '../../viewmodels/messages_viewmodel.dart';
import '../messages/chat_screen.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch product details when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductViewModel>(
        context,
        listen: false,
      ).loadProduct(widget.productId);
    });
  }

  void _toggleWishlist() async {
    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );
    final wishlistViewModel = Provider.of<WishlistViewModel>(
      context,
      listen: false,
    );

    if (productViewModel.product != null) {
      final product = productViewModel.product!;
      final isInWishlist = wishlistViewModel.isInWishlist(product.id);

      final success =
          isInWishlist
              ? await wishlistViewModel.removeFromWishlist(product.id)
              : await wishlistViewModel.addToWishlist(product);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInWishlist ? 'Removed from wishlist' : 'Added to wishlist',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareProduct() async {
    final productViewModel = Provider.of<ProductViewModel>(
      context,
      listen: false,
    );
    final success = await productViewModel.shareProduct();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Product shared successfully'
            : 'Failed to share product. Please try again.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reportListing() {
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

  void _startChatWithSeller() async {
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    final product = productViewModel.product;
    
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product information not available'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Show sign-in prompt
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign In Required'),
          content: const Text('You need to sign in to message the seller.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
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
      builder: (context) => const Center(
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
      if (mounted) Navigator.pop(context);
      
      // Navigate to chat screen
      if (mounted) {
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
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
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
    return Consumer2<ProductViewModel, WishlistViewModel>(
      builder: (context, productViewModel, wishlistViewModel, child) {
        if (productViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (productViewModel.error.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(productViewModel.error)),
          );
        }

        if (productViewModel.product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Not Found')),
            body: const Center(
              child: Text('The requested product could not be found'),
            ),
          );
        }

        final product = productViewModel.product!;
        final isInWishlist = wishlistViewModel.isInWishlist(product.id);
        final currentUser = FirebaseAuth.instance.currentUser;
        final isSelfPosted =
            currentUser != null && product.sellerId == currentUser.uid;

        // Use actual product images
        final List<String> images = product.images;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Product Details'),
            actions: [
              if (!isSelfPosted)
                IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? AppColors.primary : null,
                  ),
                  onPressed: _toggleWishlist,
                ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareProduct,
              ),
            ],
          ),
          floatingActionButton: !isSelfPosted && productViewModel.product != null ? FloatingActionButton.extended(
            onPressed: _startChatWithSeller,
            icon: const Icon(Icons.message),
            label: const Text('Message Seller'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ) : null,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Images
                AspectRatio(
                  aspectRatio: 1,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://placehold.co/600x400/png?text=No+Image',
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    },
                  ),
                ),

                // Image Indicators
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == index
                                    ? AppColors.primary
                                    : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Product Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                          Text(
                            'RM ${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Category and Posted Date
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(product.category),
                            backgroundColor: AppColors.secondary.withOpacity(
                              0.2,
                            ),
                          ),
                          Text(
                            product.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Seller Information
                      if (product.seller != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          product.seller!.avatar.startsWith(
                                                'http',
                                              )
                                              ? NetworkImage(
                                                product.seller!.avatar,
                                              )
                                              : AssetImage(
                                                    product.seller!.avatar,
                                                  )
                                                  as ImageProvider,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              StreamBuilder<DocumentSnapshot>(
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
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;
                                                    return Text(
                                                      userData['name'] ??
                                                          product.seller!.name,
                                                      style:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .titleMedium,
                                                    );
                                                  }
                                                  return Text(
                                                    product.seller!.name,
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.titleMedium,
                                                  );
                                                },
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    product.seller!.rating
                                                        .toString(),
                                                    style:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Member since ${product.seller!.joinedDate}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if (!isSelfPosted)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _startChatWithSeller,
                                          icon: const Icon(Icons.chat),
                                          label: const Text('Chat with Seller'),
                                        ),
                                      ),
                                    if (!isSelfPosted) const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _reportListing,
                                      icon: const Icon(Icons.flag_outlined),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
