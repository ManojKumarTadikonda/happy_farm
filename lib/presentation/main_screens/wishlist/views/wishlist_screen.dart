import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart'
    show CartService;
import 'package:happy_farm/presentation/main_screens/wishlist/services/whislist_service.dart';
import 'package:happy_farm/presentation/main_screens/wishlist/widgets/wishListShimmer.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Map<String, dynamic>> wishlist = [];
  late Future<void> wishlistFuture;
  bool _isAddingAllToCart = false;
  Set<String> _removingProductIds = {};

  // Enhanced color scheme
  static const Color accentGreen = Color(0xFF4CAF50);

  static const Color veryLightGreen = Color(0xFFE8F5E8);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF546E7A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    wishlistFuture = loadWishlist();
  }

  Future<void> loadWishlist() async {
    final data = await WishlistService.fetchWishlist();
    setState(() {
      wishlist = data;
      _controller.forward(); // Animate once after data loads
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        title: const Text('My Wishlist'),
        backgroundColor: Colors.green.shade700,
        automaticallyImplyLeading: false,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${wishlist.length} items',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: WishlistShimmer());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return wishlist.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: veryLightGreen,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            size: 60,
                            color: accentGreen,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Your wishlist is empty",
                          style: TextStyle(
                            fontSize: 20,
                            color: textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start adding your favorite products",
                          style: TextStyle(
                            fontSize: 16,
                            color: textMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: wishlist.length,
                    itemBuilder: (context, index) {
                      final item = wishlist[index];
                      final product = item['productId'];
                      final wishlistId = item['_id']; // <-- used to remove

                      final title = product['name'];
                      final rating = product['rating'];
                      final image = (product['images'] != null &&
                              product['images'].isNotEmpty)
                          ? product['images'][0]
                          : null;

                      final prices = product['prices'];
                      final priceObj = (prices != null && prices.isNotEmpty)
                          ? prices[0]
                          : null;

                      final priceValue =
                          priceObj != null ? priceObj['actualPrice'] : null;

                      final animation = Tween<double>(begin: 0.0, end: 1.0)
                          .animate(CurvedAnimation(
                        parent: _controller,
                        curve: Interval(
                          (1 / wishlist.length) * index,
                          1.0,
                          curve: Curves.fastOutSlowIn,
                        ),
                      ));

                      return FadeTransition(
                        opacity: animation,
                        child: GestureDetector(
                          onTap: () {
                            final productInstance =
                                AllProduct.fromJson(product);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (builder) => ProductDetails(
                                  product: productInstance,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      color: Colors.green[50],
                                      image: image != null
                                          ? DecorationImage(
                                              image: NetworkImage(image),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            _removingProductIds.contains(
                                                    product['_id'])
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.red,
                                                    ),
                                                  )
                                                : InkWell(
                                                    onTap: () async {
                                                      final id =
                                                          product['_id'];
                                                
                                                      // Prevent double‑taps
                                                      if (_removingProductIds
                                                          .contains(id))
                                                        return;
                                                
                                                      setState(() =>
                                                          _removingProductIds
                                                              .add(id));
                                                
                                                      try {
                                                        final msg =
                                                            await WishlistService
                                                                .removeFromWishlist(
                                                                    id);
                                                
                                                        if (mounted) {
                                                          setState(() {
                                                            wishlist.removeAt(
                                                                index); // remove row after success
                                                            _removingProductIds
                                                                .remove(
                                                                    id); // stop the spinner
                                                          });
                                                          showCustomToast(
                                                            context:
                                                                context,
                                                            title:
                                                                'Success',
                                                            message: msg,
                                                            isError: false,
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          _removingProductIds
                                                              .remove(
                                                                  id); // stop the spinner only
                                                          showCustomToast(
                                                            context:
                                                                context,
                                                            title: 'Error',
                                                            message: e
                                                                .toString()
                                                                .replaceFirst(
                                                                    'Exception: ',
                                                                    ''),
                                                            isError: true,
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Icon(
                                                        Icons.favorite,
                                                        color: Colors
                                                            .red[400]),
                                                  )
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '₹$priceValue',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            ...List.generate(
                                              5,
                                              (i) => Icon(
                                                i < rating.floor()
                                                    ? Icons.star
                                                    : i < rating
                                                        ? Icons.star_half
                                                        : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$rating',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
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
                          ),
                        ),
                      );
                    },
                  );
          }
        },
      ),
      floatingActionButton: wishlist.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isAddingAllToCart
                  ? null
                  : () async {
                      setState(() {
                        _isAddingAllToCart = true;
                      });
                      bool allSuccess = true;

                      for (var item in wishlist) {
                        final product = item['productId'];
                        final prices = product['prices'];

                        if (prices != null && prices.isNotEmpty) {
                          final priceObj = prices[0];
                          final productId = product['_id'];
                          final priceId = priceObj['_id'];

                          bool success = await CartService.addToCart(
                            productId: productId,
                            priceId: priceId,
                            quantity: 1,
                          );

                          if (!success) {
                            allSuccess = false;
                          }
                        }
                      }

                      setState(() {
                        _isAddingAllToCart = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(allSuccess
                              ? 'All items added to cart successfully'
                              : 'Some items could not be added'),
                        ),
                      );
                    },
              backgroundColor:
                  _isAddingAllToCart ? Colors.grey : Colors.green[800],
              icon: _isAddingAllToCart
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shopping_cart),
              label: Text(_isAddingAllToCart ? 'Adding...' : 'Add All to Cart'),
            )
          : null,
    );
  }
}
