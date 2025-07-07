import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/product.dart';
import '../models/user.dart' as app_user;
import '../services/notification_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Create a new product
  Future<String> createProduct(Product product) async {
    try {
      // Get current user from Firebase Auth
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create product with just the sellerId
      final productData = {...product.toMap(), 'sellerId': currentUser.uid};

      final docRef = await _firestore.collection(_collection).add(productData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Get all products
  Future<List<Product>> getProducts() async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('active', isEqualTo: true)
              .get();

      // Get all products first
      final products =
          snapshot.docs
              .map((doc) => Product.fromMap(doc.id, doc.data()))
              .toList();

      // Fetch current seller information for each product
      final productsWithSellers = await Future.wait(
        products.map((product) async {
          final sellerDoc =
              await _firestore.collection('users').doc(product.sellerId).get();

          app_user.User seller;
          if (!sellerDoc.exists) {
            // Fallback minimal user if not found
            seller = app_user.User(
              uid: product.sellerId,
              name: 'Unknown',
              email: '',
              avatar: 'assets/images/default_avatar.png',
              online: false,
              bio: '',
              phone: '',
              joinedDate: '',
              rating: 0.0,
              reviewCount: 0,
              isEmailVerified: false,
            );
          } else {
            final sellerData = sellerDoc.data()!;
            seller = app_user.User.fromMap(sellerData);
          }

          return Product(
            id: product.id,
            title: product.title,
            price: product.price,
            description: product.description,
            image: product.image,
            images: product.images,
            category: product.category,
            condition: product.condition,
            createdAt: product.createdAt,
            postedDate: product.postedDate,
            sellerId: product.sellerId,
            active: product.active,
            views: product.views,
            seller: seller,
          );
        }),
      );

      // Sort the results in memory after fetching
      productsWithSellers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return productsWithSellers;
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // Get all products including inactive ones (for admin/seller views)
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      // Get all products first
      final products =
          snapshot.docs
              .map((doc) => Product.fromMap(doc.id, doc.data()))
              .toList();

      // Fetch current seller information for each product
      final productsWithSellers = await Future.wait(
        products.map((product) async {
          final sellerDoc =
              await _firestore.collection('users').doc(product.sellerId).get();

          app_user.User seller;
          if (!sellerDoc.exists) {
            // Fallback minimal user if not found
            seller = app_user.User(
              uid: product.sellerId,
              name: 'Unknown',
              email: '',
              avatar: 'assets/images/default_avatar.png',
              online: false,
              bio: '',
              phone: '',
              joinedDate: '',
              rating: 0.0,
              reviewCount: 0,
              isEmailVerified: false,
            );
          } else {
            final sellerData = sellerDoc.data()!;
            seller = app_user.User.fromMap(sellerData);
          }

          return Product(
            id: product.id,
            title: product.title,
            price: product.price,
            description: product.description,
            image: product.image,
            images: product.images,
            category: product.category,
            condition: product.condition,
            createdAt: product.createdAt,
            postedDate: product.postedDate,
            sellerId: product.sellerId,
            active: product.active,
            views: product.views,
            seller: seller,
          );
        }),
      );

      // Sort the results in memory after fetching
      productsWithSellers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return productsWithSellers;
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // Get product by ID
  Future<Product> getProductById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }

      final product = Product.fromMap(doc.id, doc.data()!);

      // Fetch current seller information
      final sellerDoc =
          await _firestore.collection('users').doc(product.sellerId).get();

      if (sellerDoc.exists) {
        final sellerData = sellerDoc.data()!;
        return Product(
          id: product.id,
          title: product.title,
          price: product.price,
          description: product.description,
          image: product.image,
          images: product.images,
          category: product.category,
          condition: product.condition,
          createdAt: product.createdAt,
          postedDate: product.postedDate,
          sellerId: product.sellerId,
          active: product.active,
          views: product.views,
          seller: app_user.User.fromMap(sellerData),
        );
      }

      return product;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Get products by seller ID
  Future<List<Product>> getProductsBySeller(String sellerId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('sellerId', isEqualTo: sellerId)
              .orderBy('createdAt', descending: true)
              .get();

      // Get current seller information
      final sellerDoc =
          await _firestore.collection('users').doc(sellerId).get();
      app_user.User seller;
      if (!sellerDoc.exists) {
        print('Warning: Seller not found for sellerId: $sellerId. Using fallback user.');
        // Fallback minimal user if not found
        seller = app_user.User(
          uid: sellerId,
          name: 'Unknown',
          email: '',
          avatar: 'assets/images/default_avatar.png',
          online: false,
          bio: '',
          phone: '',
          joinedDate: '',
          rating: 0.0,
          reviewCount: 0,
          isEmailVerified: false,
        );
      } else {
        final sellerData = sellerDoc.data()!;
        seller = app_user.User.fromMap(sellerData);
      }

      // Map products with current seller information
      return snapshot.docs.map((doc) {
        final product = Product.fromMap(doc.id, doc.data());
        return Product(
          id: product.id,
          title: product.title,
          price: product.price,
          description: product.description,
          image: product.image,
          images: product.images,
          category: product.category,
          condition: product.condition,
          createdAt: product.createdAt,
          postedDate: product.postedDate,
          sellerId: product.sellerId,
          active: product.active,
          views: product.views,
          seller: seller,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get seller products: $e');
    }
  }

  // Update product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
      // Fetch the updated product
      final updatedDoc = await _firestore.collection(_collection).doc(id).get();
      if (updatedDoc.exists) {
        final updatedProduct = Product.fromMap(updatedDoc.id, updatedDoc.data()!);
        // Notify wishlist users
        await NotificationService().notifyWishlistUsers(updatedProduct, 'product_updated');
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      print('Starting product deletion for ID: $id');

      // First, get all wishlists that contain this product
      print('Fetching wishlists...');
      final wishlistsSnapshot = await _firestore.collection('wishlists').get();
      print('Found ${wishlistsSnapshot.docs.length} wishlists');

      // Delete the product from all wishlists
      print('Deleting product from wishlists...');
      for (var wishlistDoc in wishlistsSnapshot.docs) {
        print('Deleting from wishlist: ${wishlistDoc.id}');
        await wishlistDoc.reference.collection('items').doc(id).delete();
      }
      print('Finished deleting from wishlists');

      // Finally delete the product itself
      print('Deleting product document...');
      await _firestore.collection(_collection).doc(id).delete();
      print('Product deletion completed successfully');
    } catch (e) {
      print('Error during product deletion: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  // Toggle product active status
  Future<void> toggleActive(String id, bool active) async {
    try {
      if (!active) {
        // If making inactive, remove from all wishlists
        final wishlistsSnapshot =
            await _firestore.collection('wishlists').get();

        // Remove the product from all wishlists
        for (var wishlistDoc in wishlistsSnapshot.docs) {
          await wishlistDoc.reference.collection('items').doc(id).delete();
        }
      }

      await _firestore.collection(_collection).doc(id).update({
        'active': active,
      });
    } catch (e) {
      throw Exception('Failed to toggle product status: $e');
    }
  }

  // Increment view count
  Future<void> incrementViews(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment views: $e');
    }
  }

  // Update seller information across all their listings
  Future<void> updateSellerInfo(
    String sellerId,
    Map<String, dynamic> sellerData,
  ) async {
    // No need to update anything in product documents since we only store sellerId
    // and fetch current seller info from Firestore when needed
    return;
  }
}
