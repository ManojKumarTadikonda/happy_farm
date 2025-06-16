import 'dart:async';
import 'package:happy_farm/main.dart';
import 'package:happy_farm/models/cart_model.dart';
import 'package:happy_farm/screens/cart_screen.dart';
import 'package:happy_farm/service/banner_service.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/screens/filtered_products_screen.dart';
import 'package:happy_farm/screens/productdetails_screen.dart';
import 'package:happy_farm/service/cart_service.dart';
import 'package:happy_farm/widgets/shimmer_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../models/banner_model.dart';
import 'package:happy_farm/service/search_service.dart';
import 'package:happy_farm/service/category_service.dart';
import 'package:happy_farm/service/product_service.dart';

enum HomePageView { home, menu, filtered }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomePageView _currentPage = HomePageView.home;

  void _onMenuTap() {
    setState(() {
      _currentPage = HomePageView.menu;
    });
  }

  void _onCloseMenu() {
    setState(() {
      _currentPage = HomePageView.home;
      _filteredProducts = [];
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<FeaturedProduct> _featuredProducts = [];
  List<AllProduct> _allProducts = [];
  List<CategoryModel> _categories = [];
  List<FilterProducts> _filteredProducts = [];
  int _visibleFeaturedCount = 2;
  int _visibleAllCount = 2;
  int _visibleFilteredCount = 10;
  String selectedCatId = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool isSearch = false;
  final _searchService = SearchService();
  final _productService = ProductService();
  bool isLoadingSearch = false;
  String? userId;
  int cartItemCount = 0;
  @override
  void initState() {
    super.initState();
    fetchAllProducts();
    fetchFeaturedProducts();
    fetchCategories();
    _loadUser();
    loadCartItemCount();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  void _onSearchChanged(String query) async {
    setState(() {
      isSearch = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      setState(() {
        isLoadingSearch = true;
      });
      final results = await _searchService.searchProducts(query: query);
      setState(() {
        _searchResults = results as List;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      isLoadingSearch = false;
    }
  }

  Future<void> loadCartItemCount() async {
    try {
      final List<CartItem> cartItems = await CartService.fetchCart();
      setState(() {
        cartItemCount = cartItems.length;
      });
    } catch (e) {
      print("Error fetching cart item count: $e");
      setState(() {
        cartItemCount = 0;
      });
    }
  }

  Future<void> fetchCategories() async {
    try {
      final categories = await CategoryService.fetchCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _fetchProductsByRating({
    int? rating,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getProductsByRating(
        catId: selectedCatId,
        rating: rating,
      );
      if (products.isNotEmpty) {
        setState(() {
          _filteredProducts = products;
          _currentPage = HomePageView.filtered;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No filtered products found.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching filtered products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductsByPrice({
    int? minPrice,
    int? maxPrice,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.filterByPrice(
        catId: selectedCatId,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      if (products.isNotEmpty) {
        setState(() {
          _filteredProducts = products;
          _currentPage = HomePageView.filtered;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No filtered products found.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching filtered products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      final products = await _productService.getFeaturedProducts();
      setState(() {
        _featuredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchProductsByCategory(String catName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getProductsByCatName(catName);
      setState(() {
        _filteredProducts = products;
      });
    } catch (e) {
      debugPrint('Error fetching category products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAllProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching all products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to MainScreen instead of going back
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false, // remove all previous routes
        );
        return false; // prevent default back behavior
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1, // Small shadow to separate AppBar from body
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Menu or Close
              IconButton(
                icon: Icon(
                  _currentPage == HomePageView.menu ? Icons.close : Icons.menu,
                  color: Colors.black87,
                ),
                onPressed: _currentPage == HomePageView.menu
                    ? _onCloseMenu
                    : _onMenuTap,
              ),

              // Center: Icon + Text
              Row(
                children: const [
                  Icon(Icons.agriculture, color: Color(0xFF4CAF50)),
                  SizedBox(width: 6),
                  Text(
                    'SabbaFarm',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Right: Cart Icon with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.black87),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(userId: userId!),
                        ),
                      );
                    },
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: isSearch ? _buildSearchResults() : _buildBodyContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const ShimmerHomeScreen();
  }

  Widget _buildSearchResults() {
    if (isLoadingSearch) {
      return const Center(child: Text('Loading...'));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final imageUrl =
            (product['images'] != null && product['images'].isNotEmpty)
                ? product['images'][0]
                : null;
        final priceInfo =
            (product['prices'] != null && product['prices'].isNotEmpty)
                ? product['prices'][0]
                : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            leading: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  )
                : const Icon(Icons.image_not_supported),
            title: Text(product['name'] ?? 'Unnamed Product'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (priceInfo != null)
                  Text(
                    'Price: ₹${priceInfo['actualPrice']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                if (product['catName'] != null)
                  Text('Category: ${product['catName']}'),
              ],
            ),
            onTap: () {
              final productInstance = AllProduct.fromJson(product);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (builder) =>
                      ProductDetails(product: productInstance),
                ),
              );
              // Navigate to product details screen with product['_id']
            },
          ),
        );
      },
    );
  }

  Widget _buildBodyContent() {
    switch (_currentPage) {
      case HomePageView.menu:
        return _buildFilterScreen();
      case HomePageView.home:
        return _isLoading
            ? _buildLoadingView()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildContentView(),
              );
      case HomePageView.filtered:
        return FilteredProductsScreen(products: _filteredProducts);
    }
  }

  Widget _buildFilterScreen() {
    RangeValues _priceRange = const RangeValues(1, 60000);
    double _minPrice = 1;
    double _maxPrice = 60000;
    int _selectedRating = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Filter",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // CATEGORY FILTER
                const Text("FILTER BY CATEGORY",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _categories.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = category.id == selectedCatId;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCatId = category.id;
                                  });
                                  _fetchProductsByCategory(category.name);
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 70,
                                            width: 70,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                    category.imageUrl),
                                                fit: BoxFit.cover,
                                                colorFilter: isSelected
                                                    ? ColorFilter.mode(
                                                        Colors.blue
                                                            .withOpacity(0.6),
                                                        BlendMode.srcATop,
                                                      )
                                                    : null,
                                              ),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        category.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                const SizedBox(height: 30),

                // PRICE FILTER
                const Text("FILTER BY PRICE",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                RangeSlider(
                  values: _priceRange,
                  min: _minPrice,
                  max: _maxPrice,
                  divisions:
                      (_maxPrice - _minPrice).toInt(), // smoother divisions
                  activeColor: Colors.green,
                  inactiveColor: Colors.green.shade100,
                  labels: RangeLabels(
                    'Rs: ${_priceRange.start.round()}',
                    'Rs: ${_priceRange.end.round()}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                  onChangeEnd: (RangeValues values) {
                    Future.delayed(const Duration(milliseconds: 2000), () {
                      // Only call backend when user finishes dragging
                      if (selectedCatId.isNotEmpty) {
                        _fetchProductsByPrice(
                          minPrice: values.start.round(),
                          maxPrice: values.end.round(),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Please select a category first.')),
                        );
                      }
                    });
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('From: Rs: ${_priceRange.start.round()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('To: Rs: ${_priceRange.end.round()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 30),

                // RATING FILTER
                const Text("FILTER BY RATING",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Column(
                  children: List.generate(5, (index) {
                    int stars = 5 - index;
                    bool isSelected = _selectedRating == stars;

                    return InkWell(
                      onTap: () {
                        if (selectedCatId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Please select a category first.')),
                          );
                          return;
                        }

                        setState(() {
                          _selectedRating = stars;
                        });

                        _fetchProductsByRating(rating: _selectedRating);

                        // Auto-remove checkmark after 2 seconds
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _selectedRating = 0;
                            });
                          }
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < stars ? Icons.star : Icons.star_border,
                                color: i < stars ? Colors.orange : Colors.grey,
                                size: 28,
                              );
                            }),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentView() {
    return Stack(
      children: [
        // Main scrollable content (banners, featured, all)
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoScrollBanner(),
              _buildSectionTitle('Featured Categories'),
              _buildCategorySection(),
              _buildSectionTitle('Featured Products'),
              _buildFeaturedProducts(),
              SizedBox(
                height: 20,
              ),
              _buildSectionTitle('All Products'),
              _buildAllProducts(),
            ],
          ),
        ),

        // Overlay full screen filtered products view (except appbar/bottom nav)
        if (_filteredProducts.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.white, // Background for clarity
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filtered Products",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filteredProducts = [];
                            });
                          },
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildFilteredProducts(_filteredProducts)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection() {
    if (_categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return GestureDetector(
              onTap: () {
                _fetchProductsByCategory(category.name);
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                            category.color.replaceFirst('#', '0xff'))),
                        shape: BoxShape.circle,
                        border:
                            Border.all(width: 0, color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: NetworkImage(category.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    if (_featuredProducts.isEmpty) {
      return const Center(child: Text('No featured products available.'));
    }

    final visibleProducts =
        _featuredProducts.take(_visibleFeaturedCount).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.60,
            ),
            itemCount: visibleProducts.length,
            itemBuilder: (context, index) {
              final product = visibleProducts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetails(product: product),
                    ),
                  );
                },
                child: UniversalProductCard(product: product),
              );
            },
          ),
          if (_visibleFeaturedCount < _featuredProducts.length)
            TextButton(
              onPressed: () {
                setState(() {
                  _visibleFeaturedCount += 5;
                  if (_visibleFeaturedCount > _featuredProducts.length) {
                    _visibleFeaturedCount = _featuredProducts.length;
                  }
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 1, 140, 255),
              ),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }

  Widget _buildAllProducts() {
    if (_allProducts.isEmpty) {
      return const Center(child: Text('No products available.'));
    }

    final visibleProducts = _allProducts.take(_visibleAllCount).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Keep aspect ratio consistent
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 0.60,
                  ),
                  itemCount: visibleProducts.length,
                  itemBuilder: (context, index) {
                    final product = visibleProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetails(product: product),
                          ),
                        );
                      },
                      child: UniversalProductCard(product: product),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            if (_visibleAllCount < _allProducts.length)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _visibleAllCount += 5;
                      if (_visibleAllCount > _allProducts.length) {
                        _visibleAllCount = _allProducts.length;
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 1, 140, 255),
                  ),
                  child: const Text('View All'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredProducts(List<FilterProducts> filteredProducts) {
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          "No products found.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    final visibleFilteredProducts =
        filteredProducts.take(_visibleFilteredCount).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleFilteredProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.60,
            ),
            itemBuilder: (context, index) {
              final product = visibleFilteredProducts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetails(product: product),
                    ),
                  );
                },
                child: UniversalProductCard(product: product),
              );
            },
          ),
        ),
        if (_visibleFilteredCount < filteredProducts.length)
          TextButton(
            onPressed: () {
              setState(() {
                _visibleFilteredCount += 5;
                if (_visibleFilteredCount > filteredProducts.length) {
                  _visibleFilteredCount = filteredProducts.length;
                }
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 1, 140, 255),
            ),
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}

class AutoScrollBanner extends StatefulWidget {
  const AutoScrollBanner({Key? key}) : super(key: key);

  @override
  _AutoScrollBannerState createState() => _AutoScrollBannerState();
}

class _AutoScrollBannerState extends State<AutoScrollBanner> {
  List<BannerModel> _banners = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  final _bannerService = BannerService();

  @override
  void initState() {
    super.initState();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    setState(() {});

    try {
      final banners = await _bannerService.fetchMainBanners();
      if (!mounted) return;
      setState(() {
        _banners = banners;
      });
      _startAutoScroll();
    } catch (e) {
      print('Error fetching banners: $e');
      if (!mounted) return;
      setState(() {});
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_banners.isEmpty) return;

      int nextPage = _currentIndex + 1;
      if (nextPage >= _banners.length) {
        _pageController.jumpToPage(0);
        _currentIndex = 0;
      } else {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _currentIndex = nextPage;
      }
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
    return SizedBox(
      height: 180.0,
      child: _banners.isEmpty
          ? const Center(child: Text('No banners available'))
          : PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    image: DecorationImage(
                      image: NetworkImage(_banners[index].images.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
