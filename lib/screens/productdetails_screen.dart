import 'package:flutter/material.dart';
import 'package:happy_farm/main.dart';
import 'package:happy_farm/models/product_model.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/screens/cart_screen.dart';
import 'package:happy_farm/service/cart_service.dart';
import 'package:happy_farm/service/review_service.dart';
import 'package:happy_farm/service/whislist_service.dart';
import 'package:happy_farm/widgets/snackbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetails extends StatefulWidget {
  final dynamic
      product; // Can be FeaturedProduct, AllProduct, or FilterProducts

  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int selectedPriceIndex = 0;
  int quantity = 1;
  int reviewRating = 1;
  final TextEditingController reviewController = TextEditingController();
  List<dynamic> reviews = [];
  bool isLoadingReviews = true;
  bool isExpanded = false;
  bool isExpanded1 = false;
  bool isSubmitting = false;
  bool isWish = false;
  bool isCart = false;
  bool isLoadingWish = false;
  bool isLoadingCart = false;
  String? userId;
  @override
  void initState() {
    super.initState();
    fetchReviews();
    isWish = getIsWishList();
    isCart = getIsCart();
    checkWishlistStatus();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  String getProductId() {
    return widget.product.id;
  }

  String getProductName() {
    return widget.product.name;
  }

  String? getProductDescription() {
    if (widget.product is FeaturedProduct || widget.product is AllProduct) {
      return widget.product.description;
    } else if (widget.product is FilterProducts) {
      return widget.product.description;
    }
    return null;
  }

  List<String> getProductImages() {
    return widget.product.images;
  }

  String getCategoryName() {
    if (widget.product is AllProduct) {
      return widget.product.catName;
    } else if (widget.product is FilterProducts) {
      return widget.product.catName;
    } else {
      return widget.product.category ?? 'Unknown';
    }
  }

  String? getSubCategoryName() {
    if (widget.product is AllProduct) {
      return widget.product.subCatName;
    } else if (widget.product is FilterProducts) {
      return widget.product.subCatName;
    } else {
      return widget.product.subCategory ?? 'Unkown';
    }
  }

  bool getIsWishList() {
    return widget.product.isAddedToWishlist ?? false;
  }

  bool getIsCart() {
    return widget.product.isAddedToCart ?? false;
  }

  List<dynamic> getProductPrices() {
    return widget.product.prices;
  }

  Future<void> checkWishlistStatus() async {
    try {
      final wishlist = await WishlistService.fetchWishlist();

      final matchedItem = wishlist.firstWhere(
        (item) => item['productId']['_id'] == getProductId(),
        orElse: () => <String, dynamic>{}, // return an empty map
      );

      final found = matchedItem.isNotEmpty;
    } catch (e) {
      print('Error checking wishlist status: $e');
    }
  }

  Future<void> fetchReviews() async {
    setState(() {
      isLoadingReviews = true;
    });

    try {
      final response =
          await ReviewService().getReviews(productId: getProductId());

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          reviews = response['data'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? "Failed to load reviews")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading reviews: $e")),
      );
    } finally {
      setState(() {
        isLoadingReviews = false;
      });
    }
  }

  Future<void> addWishList() async {
    final productId = getProductId();

    try {
      setState(() {
        isLoadingWish = true;
      });
      final String id = await WishlistService.addToMyList(productId);
      setState(() {
        isWish = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to wishlist")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to wishlist: $e")),
      );
    } finally {
      isLoadingWish = false;
    }
  }

  Future<void> removeWishlist() async {
    try {
      setState(() {
        isLoadingWish = true;
      });
      final success = await WishlistService.removeFromWishlist(
        getProductId(),
      );
      if (success) {
        setState(() {
          isWish = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from wishlist')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove item')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      isLoadingWish = false;
    }
  }

  Future<void> addToCart() async {
    final productId = getProductId();
    final price = getProductPrices()[selectedPriceIndex];
    setState(() {
      isLoadingCart = true;
    });
    final success = await CartService.addToCart(
      productId: productId,
      priceId: price.id,
      quantity: quantity,
    );

    if (success) {
      setState(() {
        isCart = true;
        isLoadingCart = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Item added to cart"),
          action: SnackBarAction(
            label: "GO TO CART",
            textColor: Colors.amber,
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CartScreen(userId: userId!)));
            },
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      setState(() {
        isLoadingCart = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add to cart")),
      );
    }
  }

  Future<void> submitReview() async {
    final reviewText = reviewController.text.trim();

    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add a Review"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false).user;

    setState(() {
      isSubmitting = true;
    });

    try {
      final result = await ReviewService.addReview(
        productId: getProductId(),
        reviewText: reviewText,
        customerRating: reviewRating,
        customerName: user.username,
      );

      if (result['success'] == true) {
        reviewController.clear();
        setState(() {
          reviewRating = 1;
        });

        // Fetch updated reviews
        fetchReviews();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully!")),
        );
      } else {
        throw Exception(result['message'] ?? "Failed to submit review");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prices = getProductPrices();
    final price = prices[selectedPriceIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Product Image Gallery with Wishlist Button
            _buildProductImageGallery(),

            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title
                  Text(
                    getProductName(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Variant/Size Selector
                  _buildVariantSelector(),
                  const SizedBox(height: 10),

                  // Price Information
                  _buildPriceInfo(price),
                  const SizedBox(height: 8),

                  // Quantity and Unit
                  Text('${price.quantity} ${price.type}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),

                  // Stock Availability
                  Text(
                    price.countInStock > 0 ? 'IN STOCK' : 'OUT OF STOCK',
                    style: TextStyle(
                        color:
                            price.countInStock > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Quantity Selector and Add to Cart Button
                  _buildQuantityAndCartSection(userId!),
                  const SizedBox(height: 24),

                  // Product Information Cards
                  _buildInfoCards(),
                  const SizedBox(height: 20),

                  // Reviews Section
                  _buildReviewsSection(),
                  const Divider(),

                  // Write Review Section
                  _buildWriteReviewSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImageGallery() {
    return Stack(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            itemCount: getProductImages().length,
            itemBuilder: (context, index) => Image.network(
              getProductImages()[index],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('Image could not be loaded',
                      style: TextStyle(color: Colors.grey)),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              isWish ? removeWishlist() : addWishList();
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white60,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: isLoadingWish
                    ? SizedBox(
                        key: ValueKey('loading'),
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.redAccent),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                              scale: animation, child: child);
                        },
                        child: AnimatedScale(
                          scale: isWish ? 1.2 : 1.0,
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Icon(
                            isWish ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isWish),
                            color: Colors.redAccent,
                            size: 26,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantSelector() {
    final prices = getProductPrices();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(prices.length, (index) {
          final variant = prices[index];
          final isSelected = index == selectedPriceIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text('${variant.quantity} ${variant.type}'),
              selected: isSelected,
              selectedColor: Colors.green.shade700,
              onSelected: (_) {
                setState(() {
                  selectedPriceIndex = index;
                });
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPriceInfo(dynamic price) {
    return Row(
      children: [
        Text(
          '₹${price.actualPrice.toStringAsFixed(2)}',
          style: const TextStyle(
              fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${price.oldPrice.toStringAsFixed(2)}',
          style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough),
        ),
        const SizedBox(width: 8),
        Text(
          '${price.discount}% OFF',
          style: const TextStyle(
              color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuantityAndCartSection(String userId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Quantity Selector
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  if (quantity > 1) quantity--;
                });
              },
            ),
            Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  quantity++;
                });
              },
            ),
          ],
        ),

        // Add to Cart Button
        ElevatedButton.icon(
          onPressed: () {
            isCart
                ? Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (builder) => CartScreen(
                        userId: userId,
                      ),
                    ),
                  )
                : addToCart();
          },
          icon: const Icon(
            Icons.shopping_cart,
            color: Colors.white,
          ),
          label: Text(isCart
              ? "Go to Cart"
              : isLoadingCart
                  ? "Adding..."
                  : "Add To Cart"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        // Description Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isExpanded1
                ? const BorderSide(color: Colors.transparent, width: 0)
                : BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              onExpansionChanged: (value) {
                setState(() {
                  isExpanded1 = value;
                });
              },
              leading: const Icon(Icons.description_outlined,
                  color: Colors.deepPurple),
              initiallyExpanded: true,
              title: const Text(
                "Description",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    getProductDescription()?.trim().isNotEmpty == true
                        ? getProductDescription()!
                        : "No description available.",
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Additional Information Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isExpanded
                ? const BorderSide(color: Colors.transparent, width: 0)
                : BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              onExpansionChanged: (value) {
                setState(() {
                  isExpanded = value;
                });
              },
              leading:
                  const Icon(Icons.info_outline_rounded, color: Colors.teal),
              title: const Text(
                "Additional Information",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${getCategoryName()}'),
                      if (getSubCategoryName() != null)
                        Text('Sub-category: ${getSubCategoryName()}'),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Customer Reviews",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        isLoadingReviews
            ? const Center(child: CircularProgressIndicator())
            : reviews.isEmpty
                ? const Text("No reviews yet.",
                    style: TextStyle(color: Colors.grey))
                : Column(
                    children: reviews.map((review) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 18,
                                  color: i < review['customerRating']
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                review['customerName'] ?? 'Anonymous',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(review['review'] ?? ''),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildWriteReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Write a Review",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: reviewController,
          decoration: InputDecoration(
            hintText: "Your review...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(Icons.star,
                  color: index < reviewRating ? Colors.orange : Colors.grey),
              onPressed: () {
                setState(() {
                  reviewRating = index + 1;
                });
              },
            );
          }),
        ),
        ElevatedButton(
          onPressed: submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: isSubmitting
              ? const Text('Submitting...')
              : const Text("Submit Review"),
        ),
      ],
    );
  }
}