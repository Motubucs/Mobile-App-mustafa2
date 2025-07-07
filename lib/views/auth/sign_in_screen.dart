import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../models/user.dart' as app_models;

class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color background = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color googleButtonBackground = Colors.white;
  static const Color googleButtonText = Color(0xFF333333);
  static const Color googleButtonBorder = Color(0xFFE0E0E0);
  static const Color adminIconColor = Colors.black54;
  static const Color cardBackground = Color.fromARGB(255, 255, 255, 255);
  static const Color cardBorder = Color.fromARGB(255, 224, 224, 224);
}

// Define the list of items for the carousel
final List<Map<String, String>> carouselItemsData = [
  {'name': 'Books', 'imageUrl': 'assets/images/books.png'},
  {'name': 'Accessories', 'imageUrl': 'assets/images/watches.png'}, // Watch
  {'name': 'Home Decor', 'imageUrl': 'assets/images/home-decor.png'}, // Armchair
  {'name': 'Clothing', 'imageUrl': 'assets/images/shirt.png'}, // Hoodie
  {'name': 'Appliances', 'imageUrl': 'assets/images/microwave.png'}, // Microwave
  {'name': 'Electronics', 'imageUrl': 'assets/images/laptop.png'}, // Laptop
  {'name': 'Audio', 'imageUrl': 'assets/images/headset.png'}, // Headphones
  {'name': 'Footwear', 'imageUrl': 'assets/images/sneaker.png'}, // Sneakers
];

// Define gradient color combinations for animation
final List<List<Color>> gradientColors = [
  [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple to Purple
  [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink to Red
  [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue to Cyan
  [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green to Teal
  [const Color(0xFFfa709a), const Color(0xFFfee140)], // Pink to Yellow
  [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // Light Blue to Pink
  [const Color(0xFFff9a9e), const Color(0xFFfecfef)], // Light Pink to Pink
  [const Color(0xFFffecd2), const Color(0xFFfcb69f)], // Cream to Orange
];

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    forceCodeForRefreshToken: true,
    signInOption: SignInOption.standard,
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isAutoLoginAttempted = false;
  
  // Animation controllers
  late AnimationController _gradientController;
  late AnimationController _rotationController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _rotationAnimation;
  
  int _currentGradientIndex = 0;
  int _nextGradientIndex = 1;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    // Create animations
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Start animations
    _startGradientAnimation();
    _rotationController.repeat();
    
    _attemptAutoLogin();
  }

  void _startGradientAnimation() {
    _gradientController.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentGradientIndex = _nextGradientIndex;
          _nextGradientIndex = (_nextGradientIndex + 1) % gradientColors.length;
        });
        _gradientController.reset();
        _startGradientAnimation();
      }
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoLogin() async {
    if (_isAutoLoginAttempted) return;
    
    setState(() {
      _isAutoLoginAttempted = true;
      _isLoading = true;
    });

    try {
      // Check if user is already signed in with Google
      final bool isSignedIn = await _googleSignIn.isSignedIn();
      
      if (isSignedIn) {
        // Try to get the last signed in account
        final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
        
        if (googleUser != null) {
          // User is already signed in, proceed with authentication
          await _authenticateWithGoogle(googleUser);
          return;
        }
      }
      
      // Check if Firebase user is already authenticated
      if (_auth.currentUser != null) {
        final app_models.User appUser = app_models.User.fromFirebaseUser(_auth.currentUser!);
        final ProfileViewModel profileViewModel = Provider.of<ProfileViewModel>(
          context,
          listen: false,
        );
        profileViewModel.initializeWithUser(appUser);
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }
    } catch (error) {
      print("Auto-login error: $error");
      // Continue to manual sign-in if auto-login fails
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _authenticateWithGoogle(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final app_models.User appUser = app_models.User.fromFirebaseUser(firebaseUser);
        final ProfileViewModel profileViewModel = Provider.of<ProfileViewModel>(
          context,
          listen: false,
        );
        profileViewModel.initializeWithUser(appUser);

        print("Auto-signed in with Google: ${appUser.email}");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (error) {
      print("Error during auto-authentication: $error");
      // If auto-authentication fails, allow manual sign-in
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      await _authenticateWithGoogle(googleUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in successfully as ${googleUser.displayName}'),
          ),
        );
      }
    } catch (error) {
      print("Error signing in with Google: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign in with Google. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_gradientAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    gradientColors[_currentGradientIndex][0],
                    gradientColors[_nextGradientIndex][0],
                    _gradientAnimation.value,
                  )!,
                  Color.lerp(
                    gradientColors[_currentGradientIndex][1],
                    gradientColors[_nextGradientIndex][1],
                    _gradientAnimation.value,
                  )!,
                ],
                stops: const [0.0, 1.0],
                transform: GradientRotation(_rotationAnimation.value * 2 * 3.14159),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: <Widget>[
                    // AppBar with transparent background
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin');
                            },
                            tooltip: 'Admin Dashboard (Dev Mode)',
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Logo with white background for better visibility
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/LogoImage.png',
                                  width: 120,
                                  height: 120,
                                ),
                                const SizedBox(height: 16),
                                Image.asset('assets/images/LogoText.png', width: 220),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Buy and sell items within your campus community.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),

                    _InfiniteItemsCarousel(
                      items: carouselItemsData,
                      height: 200,
                    ),

                    Expanded(
                      flex: 2,
                      child: Container(),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                icon: Image.network(
                                  'https://img.icons8.com/color/48/google-logo.png',
                                  height: 26,
                                  width: 26,
                                ),
                                label: const Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    color: AppColors.googleButtonText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.googleButtonBackground,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    side: const BorderSide(
                                      color: AppColors.googleButtonBorder,
                                    ),
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.black.withOpacity(0.2),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfiniteItemsCarousel extends StatefulWidget {
  final List<Map<String, String>> items;
  final double height;

  const _InfiniteItemsCarousel({required this.items, this.height = 200.0});

  @override
  _InfiniteItemsCarouselState createState() => _InfiniteItemsCarouselState();
}

class _InfiniteItemsCarouselState extends State<_InfiniteItemsCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.4, // Increased from 0.3 to make cards bigger
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuint,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        padEnds: true,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final itemIndex = index % widget.items.length;
          final itemData = widget.items[itemIndex];

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              Matrix4 matrix = Matrix4.identity();
              bool isActive = false;

              if (_pageController.position.haveDimensions) {
                double currentPageValue =
                    _pageController.page ?? _initialPage.toDouble();
                double pageOffset = index - currentPageValue;

                // Determine if this is the active (center) card
                isActive = pageOffset.abs() < 0.2;

                // Parameters for Cover Flow effect
                const double perspectiveFactor = 0.003; // Increased perspective
                const double rotationFactor =
                    1.2; // Increased rotation for side cards
                const double zTranslationFactor =
                    60.0; // Increased z-translation

                // Greater scale difference - active cards much larger
                double scale = isActive ? 1.5 : 0.7;

                double rotationY = pageOffset * -rotationFactor;

                // Move side cards more to the sides
                double translationX = pageOffset * 8.0;

                // Z-space movement - push side cards back more
                double translationZ = -pageOffset.abs() * zTranslationFactor;

                matrix.setEntry(3, 2, perspectiveFactor);
                matrix.translate(translationX, 0, translationZ);
                matrix.rotateY(rotationY);
                matrix.scale(scale, scale);
              }

              return Center(
                child: Transform(
                  transform: matrix,
                  alignment: Alignment.center,
                  child:
                      isActive
                          ? _buildActiveCarouselItem(
                            itemData['imageUrl']!,
                            itemData['name']!,
                          )
                          : _buildCarouselItem(
                            itemData['imageUrl']!,
                            itemData['name']!,
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Regular card for non-active items
  Widget _buildCarouselItem(String imageUrl, String itemName) {
    return Container(
      width: 120, // Set explicit width
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      padding: const EdgeInsets.all(1.0), // Increased padding
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(1.0),
            Colors.white.withOpacity(0.92),
          ],
        ),
      ),
      child: _buildCardContent(imageUrl, itemName),
    );
  }

  // Active card with enhanced glow
  Widget _buildActiveCarouselItem(String imageUrl, String itemName) {
    return Container(
      width: 160, // Set explicit width - larger than inactive cards
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 8.0,
      ), // Less vertical margin
      padding: const EdgeInsets.all(5.0), // More padding for active card
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          // Enhanced primary glow for active card
          BoxShadow(
            color: Colors.blue.withOpacity(0.35),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
          // Secondary inner glow
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
          // Bottom shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withOpacity(0.96)],
        ),
      ),
      child: _buildCardContent(imageUrl, itemName),
    );
  }

  // Common card content to avoid duplication
  Widget _buildCardContent(String imageUrl, String itemName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print(
                      "Error loading image $imageUrl: $error \n$stackTrace",
                    );
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                itemName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      blurRadius: 1.0,
                      color: Colors.white,
                      offset: Offset(0.5, 0.5),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
