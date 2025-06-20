import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class ListingViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _error = '';
  List<Product> _myListings = [];

  // Form data
  String _title = '';
  String _description = '';
  double _price = 0.0;
  String _category = '';
  String _condition = '';
  List<String> _imageUrls = [];

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  List<Product> get myListings => _myListings;

  String get title => _title;
  String get description => _description;
  double get price => _price;
  String get category => _category;
  String get condition => _condition;
  List<String> get imageUrls => _imageUrls;

  // Setters
  set title(String value) {
    _title = value;
    notifyListeners();
  }

  set description(String value) {
    _description = value;
    notifyListeners();
  }

  set price(double value) {
    _price = value;
    notifyListeners();
  }

  set category(String value) {
    _category = value;
    notifyListeners();
  }

  set condition(String value) {
    _condition = value;
    notifyListeners();
  }

  set imageUrls(List<String> value) {
    _imageUrls = value;
    notifyListeners();
  }

  // Load user's listings
  Future<void> loadMyListings() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      _myListings = await _productService.getProductsBySeller(currentUser.uid);
    } catch (e) {
      _error = 'Failed to load listings: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new listing
  Future<bool> createListing() async {
    if (_title.isEmpty ||
        _price <= 0 ||
        _category.isEmpty ||
        _imageUrls.isEmpty) {
      _error = 'Please fill all required fields and add at least one image';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Ensure user document exists
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'name': currentUser.displayName ?? 'Unknown',
          'email': currentUser.email ?? '',
          'avatar': currentUser.photoURL ?? 'assets/images/default_avatar.png',
          'joinedDate': DateTime.now(),
        });
      }

      // Create product with the image URLs
      final newProduct = Product(
        id: '', // Will be set by Firestore
        title: _title,
        price: _price,
        description: _description,
        image: _imageUrls.first, // Use first image as primary
        images: _imageUrls, // Store all images
        category: _category,
        condition: _condition,
        createdAt: DateTime.now(),
        sellerId: currentUser.uid,
        active: true,
        views: 0,
      );

      // Save product to database
      final productId = await _productService.createProduct(newProduct);
      if (productId != null) {
        // Clear form data
        _resetForm();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to create listing: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a listing
  Future<bool> deleteListing(String productId) async {
    print('=== LISTING VIEWMODEL DELETE START ===');
    print('Deleting listing with ID: $productId');

    _isLoading = true;
    notifyListeners();

    try {
      print('Calling product service to delete product...');
      await _productService.deleteProduct(productId);
      print('Product service deletion completed');

      // Remove from local list
      print('Removing from local list...');
      _myListings.removeWhere((product) => product.id == productId);
      print('Removed from local list');

      print('=== LISTING VIEWMODEL DELETE END ===');
      return true;
    } catch (e) {
      print('Error in deleteListing: $e');
      _error = 'Failed to delete listing: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle listing active status
  Future<bool> toggleActive(String productId, bool active) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _productService.toggleActive(productId, active);
      // Update local list
      final index = _myListings.indexWhere(
        (product) => product.id == productId,
      );
      if (index != -1) {
        final product = _myListings[index];
        _myListings[index] = Product(
          id: product.id,
          title: product.title,
          price: product.price,
          description: product.description,
          image: product.image,
          images: product.images,
          category: product.category,
          condition: product.condition,
          createdAt: product.createdAt,
          sellerId: product.sellerId,
          active: active,
          views: product.views,
        );
      }
      return true;
    } catch (e) {
      _error = 'Failed to toggle listing status: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset form data
  void _resetForm() {
    _title = '';
    _description = '';
    _price = 0.0;
    _category = '';
    _condition = '';
    _imageUrls = [];
    notifyListeners();
  }

  // Create a new product
  Future<String?> createProduct(Product product) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final productId = await _productService.createProduct(product);
      if (productId != null) {
        // Add to local list
        _myListings.add(product);
        notifyListeners();
      }
      return productId;
    } catch (e) {
      _error = 'Failed to create product: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing listing
  Future<bool> updateListing(Product product) async {
    print('=== LISTING VIEWMODEL UPDATE START ===');
    print('Updating product: ${product.id}');
    print('New title: ${product.title}');
    print('New price: ${product.price}');

    _isLoading = true;
    notifyListeners();

    try {
      print('Updating product in Firestore...');
      // Update the product in Firestore
      await _productService.updateProduct(product.id, product.toMap());
      print('Product updated in Firestore successfully');

      // Update local list
      final index = _myListings.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        print('Updating product in local list at index $index');
        _myListings[index] = product;
      }

      print('Sending notifications to wishlist users...');
      // Send notifications to users who have this in their wishlist
      await _notificationService.notifyWishlistUsers(
        product,
        'product_updated',
      );
      print('Notifications sent successfully');

      print('=== LISTING VIEWMODEL UPDATE END ===');
      return true;
    } catch (e) {
      print('Error updating listing: $e');
      print('Stack trace: ${StackTrace.current}');
      _error = 'Failed to update listing: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
