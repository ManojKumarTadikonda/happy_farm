import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart' show CartService;
import 'package:happy_farm/presentation/main_screens/wishlist/services/whislist_service.dart';
import 'package:happy_farm/presentation/main_screens/wishlist/widgets/wishListShimmer.dart';

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
                ? const Center(child: Text('Your wishlist is empty'))
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
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.5, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: Dismissible(
                            key: ValueKey(wishlistId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (direction) async {
                              final removedItem = wishlist[index];
                              setState(() {
                                wishlist.removeAt(index);
                              });

                              await WishlistService.removeFromWishlist(
                                  product['_id']);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$title removed from wishlist'),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () {
                                      setState(() {
                                        wishlist.insert(index, removedItem);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
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
                                                InkWell(
                                                  onTap: () async {
                                                    await WishlistService
                                                        .removeFromWishlist(
                                                            product['_id']);
                                                    setState(() {
                                                      wishlist.removeAt(index);
                                                    });
                                                  },
                                                  child: Icon(Icons.favorite,
                                                      color: Colors.red[400]),
                                                ),
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
              onPressed: () async {
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

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(allSuccess
                        ? 'All items added to cart successfully'
                        : 'Some items could not be added'),
                  ),
                );
              },
              backgroundColor: Colors.green[800],
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add All to Cart'),
            )
          : null,
    );
  }
}
