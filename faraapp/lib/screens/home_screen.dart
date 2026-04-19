import 'dart:async';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/colors.dart';
import '../widgets/menu_card.dart';
import '../screens/menu_screen.dart';
import '../screens/cart_page.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'food_detail_screen.dart';
import 'verify_email_screen.dart';

// ── Banner Model ─────────────────────────────────────────────────────────────
class _BannerItem {
  final String image;
  final String label;
  final String tag;
  final String? categoryFilter;
  final String? scrollToItem;
  final bool isNetworkImage;

  const _BannerItem({
    required this.image,
    required this.label,
    required this.tag,
    this.categoryFilter,
    this.scrollToItem,
    this.isNetworkImage = false,
  });
}

const List<_BannerItem> _defaultBanners = [
  _BannerItem(
    image: "assets/momo_banner.jpg",
    label: "Steamed Chicken Momos",
    tag: "🔥 Best Seller",
    categoryFilter: "steamed",
    scrollToItem: "Steamed Chicken Momos",
  ),
  _BannerItem(
    image: "assets/fried_veg_momos.jpg",
    label: "Crispy Fried Veg Momos",
    tag: "🌿 Pure Veg",
    categoryFilter: "fried",
    scrollToItem: "Fried Veg Momos",
  ),
  _BannerItem(
    image: "assets/momo_banner.jpg",
    label: "Mega Combo Deals",
    tag: "💰 Save More",
    categoryFilter: "combo",
    scrollToItem: null,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _bannerController;
  int _currentBanner = 0;
  Timer? _bannerTimer;
  List<_BannerItem> _banners = _defaultBanners;

  // ── Location State ─────────────────────────────────────────────────────────
  String _locationTitle = "Fetching location...";
  String _locationSubtitle = "";
  bool _locationLoading = true;

  List<dynamic> _popularFoods = [];
  List<dynamic> _favorites = [];
  List<dynamic> _outlets = [];
  bool _outletsLoading = true;
  bool _foodsLoading = true;
  bool _favoritesLoading = true;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _startAutoSlide();
    _fetchLocation();
    _fetchPopularFoods();
    _fetchOutlets();
    _fetchProfile();
    _fetchFavorites();
  }

  Map<String, dynamic>? _userProfile;
  bool _profileLoading = true;

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = res['data'] ?? res;
          _profileLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final res = await ApiService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = res;
          _favoritesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _favoritesLoading = false);
    }
  }

  Future<void> _fetchOutlets() async {
    try {
      final data = await ApiService.getAllOutlets();
      if (mounted) {
        setState(() {
          _outlets = data;
          _outletsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _outletsLoading = false);
    }
  }

  Future<void> _fetchPopularFoods() async {
    try {
      final data = await ApiService.getAllFoods();
      if (mounted) {
        setState(() {
          final bestSellers = data.where((item) => item['isBestSeller'] == true && item['isAvailable'] == true).toList();
          _popularFoods = bestSellers;
          
          if (bestSellers.isNotEmpty) {
            _banners = bestSellers.take(3).map((food) {
              return _BannerItem(
                image: (food['image'] != null && food['image'].toString().isNotEmpty) 
                    ? food['image'] 
                    : "assets/momo_banner.jpg",
                label: food['name'] ?? '',
                tag: food['isVeg'] == true ? "🌿 Pure Veg" : "🔥 Best Seller",
                categoryFilter: food['category']?.toString().toLowerCase(),
                scrollToItem: food['name'],
                isNetworkImage: (food['image'] != null && food['image'].toString().startsWith('http')),
              );
            }).toList();
            
            // Add a default one if only 1-2 bestsellers
            if (_banners.length < 3 && _banners.isNotEmpty) {
               _banners.add(_defaultBanners.last);
            }
          }
          
          _foodsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _foodsLoading = false);
    }
  }

  // ── GPS Location ────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationTitle = "Location Off";
            _locationSubtitle = "Enable location for nearby stores";
            _locationLoading = false;
          });
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationTitle = "Permission Denied";
              _locationSubtitle = "Allow location access in settings";
              _locationLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationTitle = "Location Blocked";
            _locationSubtitle = "Enable in App Settings";
            _locationLoading = false;
          });
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Reverse geocode to address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final area = p.subLocality?.isNotEmpty == true
            ? p.subLocality!
            : p.locality ?? "Nearby";
        final city = p.locality?.isNotEmpty == true ? p.locality! : p.administrativeArea ?? "";
        final landmark = p.name?.isNotEmpty == true && p.name != p.thoroughfare
            ? p.name!
            : (p.thoroughfare ?? "Nearby Store");

        setState(() {
          _locationTitle = landmark.length > 25
              ? "${landmark.substring(0, 25)}..."
              : landmark;
          _locationSubtitle = "$area, $city";
          _locationLoading = false;
        });

        // Save to CartProvider for checkout
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false)
              .setCustomerLocation("$_locationTitle, $_locationSubtitle");
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _locationTitle = "Nearby Store";
          _locationSubtitle = "Tap to update location";
          _locationLoading = false;
        });
      }
    }
  }

  void _startAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentBanner + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _goToMenu(BuildContext context,
      {String? categoryFilter, String? scrollToItem}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          categoryFilter: categoryFilter,
          scrollToItem: scrollToItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_profileLoading && _userProfile != null && _userProfile!['isVerified'] == false)
                _buildVerificationBanner(),

              // ── Location + Cart ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dynamic Location Widget
                  GestureDetector(
                    onTap: () {
                      setState(() => _locationLoading = true);
                      _fetchLocation();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _locationLoading
                                ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primary,
                              ),
                            )
                                : Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Nearby Store",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _locationLoading
                                  ? "Detecting location..."
                                  : _locationTitle,
                              style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (!_locationLoading && _locationSubtitle.isNotEmpty)
                          Text(
                            _locationSubtitle,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                      ],
                    ),
                  ),

                  // Cart Icon
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200, width: 1),
                          ),
                          child: badges.Badge(
                            showBadge: cart.totalItems > 0,
                            badgeContent: Text(
                              cart.totalItems.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            badgeStyle: badges.BadgeStyle(
                              badgeColor: AppColors.primary,
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                size: 24),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ── Outlet Selector ─────────────────────────────────
              _buildOutletSelector(),

              const SizedBox(height: 20),

              if (!_favoritesLoading && _favorites.isNotEmpty)
                _buildFavoritesSection(),

              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: _banners.length,
                  onPageChanged: (i) => setState(() => _currentBanner = i),
                  itemBuilder: (context, index) {
                    final b = _banners[index];
                    return GestureDetector(
                      onTap: () => _goToMenu(context,
                          categoryFilter: b.categoryFilter,
                          scrollToItem: b.scrollToItem),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: b.isNetworkImage 
                                ? Image.network(
                                    b.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    b.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.65),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              left: 14,
                              right: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(b.tag,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(b.label,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: const [
                                      Text("Order Now",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios_rounded,
                                          color: Colors.white70, size: 10),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentBanner == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentBanner == i
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── What's On Your Mind ─────────────────────────────
              const Text("What's On Your Mind",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 14),

              // ── Category Cards ──────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryCard(
                      emoji: "🥟",
                      label: "Steamed",
                      color: const Color(0xFFFFF3EE),
                      onTap: () => _goToMenu(context, categoryFilter: "steamed"),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      emoji: "🍟",
                      label: "Fried",
                      color: const Color(0xFFFFF8E7),
                      onTap: () => _goToMenu(context, categoryFilter: "fried"),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      emoji: "🌶️",
                      label: "Kurkure",
                      color: const Color(0xFFFFEEEE),
                      onTap: () => _goToMenu(context, categoryFilter: "kurkure"),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      emoji: "🍕",
                      label: "Pizza",
                      color: const Color(0xFFF4F0FF),
                      onTap: () => _goToMenu(context, categoryFilter: "pizza"),
                    ),
                    const SizedBox(width: 12),
                    _CategoryCard(
                      emoji: "☕",
                      label: "Kulhad",
                      color: const Color(0xFFF0FFF4),
                      onTap: () => _goToMenu(context, categoryFilter: "kulhad"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Popular Items ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Popular Items",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => _goToMenu(context),
                    child: Text("See All",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _foodsLoading 
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  : _popularFoods.isEmpty 
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("More popular items coming soon!", style: TextStyle(color: Colors.grey)),
                        )
                      : Column(
                          children: [
                            ..._popularFoods.map((food) => GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FoodDetailScreen(
                                      food: food,
                                      isAdmin: false,
                                    ),
                                  ),
                                );
                              },
                              child: MenuCard(
                                image: (food['image'] != null && food['image'].toString().isNotEmpty) 
                                    ? food['image'] 
                                    : "assets/app_logo.jpg",
                                title: food['name'] ?? '',
                                subtitle: food['description'] ?? '',
                                price: (food['price'] ?? 0).toDouble(),
                                foodId: food['_id'] ?? food['id'],
                                initialIsFavorite: _favorites.any((f) => (f['_id'] ?? f['id']) == (food['_id'] ?? food['id'])),
                              ),
                            )).toList(),
                          ],
                        ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Favorites 💖",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final item = _favorites[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(food: item),
                      ),
                    );
                    _fetchFavorites(); // Refresh in case they un-favorited
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: item['image'] != null && item['image'].isNotEmpty
                            ? (item['image'].startsWith('http')
                                ? Image.network(item['image'], height: 100, width: 140, fit: BoxFit.cover)
                                : Image.asset(item['image'], height: 100, width: 140, fit: BoxFit.cover))
                            : Container(color: Colors.grey.shade200, height: 100, width: 140),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        "₹${item['price']}",
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOutletSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Stall",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _outletsLoading
            ? const Center(child: CircularProgressIndicator())
            : _outlets.isEmpty
                ? const Text("No stalls available", style: TextStyle(color: Colors.grey))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _outlets.map((outlet) {
                        return Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            final isSelected = cart.selectedOutlet?['_id'] == outlet['_id'];
                            return GestureDetector(
                              onTap: () => cart.setSelectedOutlet(outlet),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF8F8F8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        color: isSelected ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      outlet['name'] ?? 'Stall',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
      ],
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9A7B), Color(0xFFFF6B2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B2C).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Verify Your Email",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "Verify your email to secure your account.",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF6B2C),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(0, 32),
            ),
            onPressed: () async {
              await ApiService.sendVerifyEmailOTP();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyEmailScreen(
                    email: _userProfile!['email'],
                    onVerified: () {
                      _fetchProfile(); // Refresh profile after verification
                    },
                  ),
                ),
              );
            },
            child: const Text("Verify", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


// ── Category Card ────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }
}