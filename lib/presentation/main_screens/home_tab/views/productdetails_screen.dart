import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/cart_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/review_service.dart';
import 'package:happy_farm/presentation/main_screens/wishlist/services/whislist_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetails extends StatefulWidget {
  final dynamic product;

  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int selectedPriceIndex = 0;
  int quantity = 1;
  List<dynamic> reviews = [];
  bool isLoadingReviews = true;
  bool isExpanded = false;
  bool isExpanded1 = false;
  bool isWish = false;
  bool isCart = false;
  bool isLoadingWish = false;
  bool isLoadingCart = false;
  bool isSubmittingReview = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchReviews();
    checkWishlistStatus();
    isCart = getIsCart();
    _loadUser();
  }

  void _showLimitDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            )
          ],
        );
      },
    );
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
      setState(() {
        isLoadingWish = true;
      });
      final wishlist = await WishlistService.fetchWishlist();
      final isProductInWishlist = wishlist.any(
        (item) => item['productId']['_id'] == getProductId(),
      );
      setState(() {
        isWish = isProductInWishlist;
      });
      setState(() {
        isLoadingWish = false;
      });
    } catch (e) {
      setState(() {
        isLoadingWish = false;
      });
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
    try {
      setState(() {
        isLoadingWish = true;
      });
      await WishlistService.addToMyList(getProductId());
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
      setState(() {
        isLoadingWish = false;
      });
    }
  }

  Future<void> removeWishlist() async {
    try {
      setState(() {
        isLoadingWish = true;
      });await WishlistService.removeFromWishlist(getProductId());
      setState(() {
        isWish = false;
      });
      showCustomToast(
        context: context,
        title: "Sucess",
        message: 'Item Removed from the wishlist',
        isError: false,
      );
    } catch (e) {
      showCustomToast(
        context: context,
        title: "Error",
        message: '$e',
        isError: true,
      );
    } finally {
      setState(() {
        isLoadingWish = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final prices = getProductPrices();
    final price = prices[selectedPriceIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProductImageGallery(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getProductName(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildVariantSelector(),
                  const SizedBox(height: 10),
                  _buildPriceInfo(price),
                  const SizedBox(height: 8),
                  Text('${price.quantity} ${price.type}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    price.countInStock > 0 ? 'IN STOCK' : 'OUT OF STOCK',
                    style: TextStyle(
                        color: price.countInStock > 0
                            ? AppTheme.primaryColor
                            : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildQuantityAndCartSection(userId!, price),
                  const SizedBox(height: 24),
                  _buildInfoCards(),
                  const SizedBox(height: 20),
                  _buildReviewsSection(),
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
              checkmarkColor: Colors.white,
              selectedColor: AppTheme.primaryColor,
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
              fontSize: 20,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold),
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

  Widget _buildQuantityAndCartSection(String userId, dynamic price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: quantity <= 1 ? Colors.grey : Colors.deepOrange,
              ),
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
              icon: Icon(Icons.add_circle_outline),
              color: quantity == price.countInStock
                  ? Colors.grey
                  : AppTheme.primaryColor,
              onPressed: () {
                if (quantity == price.countInStock) {
                  _showLimitDialog(context, "Stock limit reached",
                      "Cannot add more than available stock.");
                } else {
                  setState(() {
                    quantity++;
                  });
                }
              },
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            isCart
                ? Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (builder) => CartScreen(userId: userId),
                    ),
                  )
                : addToCart();
          },
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: Text(isCart
              ? "Go to Cart"
              : isLoadingCart
                  ? "Adding..."
                  : "Add To Cart"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
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
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                  child: getProductDescription()?.trim().isNotEmpty == true
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: getProductDescription()!
                              .split('\n')
                              .where((line) => line.trim().isNotEmpty)
                              .map((line) {
                            if (line.toLowerCase().contains("features") ||
                                line.toLowerCase().contains("benefits") ||
                                line.toLowerCase().contains("crops") ||
                                line.toLowerCase().contains("target pest") ||
                                line.toLowerCase().contains("dosage") ||
                                line.toLowerCase().contains("mode of action") ||
                                line.toLowerCase().contains("application")) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 12.0, bottom: 6),
                                child: Text(
                                  line.trim(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  line.trim(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              );
                            }
                          }).toList(),
                        )
                      : const Text(
                          "No description available.",
                          style: TextStyle(fontSize: 15, color: Colors.black87),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Customer Reviews",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: _showWriteReviewModal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "Write Review",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildProfileAvatar(
                                      review['customerName'] ?? 'Anonymous'),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review['customerName'] ?? 'Anonymous',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Row(
                                              children: List.generate(5, (i) {
                                                return Icon(
                                                  i < (review['customerRating'] ?? 0)
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 18,
                                                  color: i <
                                                          (review['customerRating'] ??
                                                              0)
                                                      ? Colors.amber
                                                      : Colors.grey[400],
                                                );
                                              }),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${review['customerRating'] ?? 0}/5',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                review['review'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildProfileAvatar(String name) {
    String? profileImageUrl = null;
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(profileImageUrl),
        backgroundColor: Colors.grey[300],
      );
    } else {
      String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
      Color backgroundColor = _getAvatarColor(name);
      return CircleAvatar(
        radius: 24,
        backgroundColor: backgroundColor,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Color _getAvatarColor(String name) {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
    ];
    int index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  void _showWriteReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWriteReviewModal(),
    );
  }

  Widget _buildWriteReviewModal() {
    final TextEditingController reviewController = TextEditingController();
    int selectedRating = 5;
    bool isSubmittingReview = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // important to wrap height
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Write a Review",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Rating",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setModalState(() {
                          selectedRating = index + 1;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.star,
                            size: 32,
                            color: index < selectedRating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Your Review",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: "Share your experience...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmittingReview
                          ? null
                          : () async {
                              final reviewText = reviewController.text.trim();
                              if (reviewText.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please enter a review."),
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isSubmittingReview = true;
                              });

                              await _submitReview(reviewText, selectedRating);

                              setModalState(() {
                                isSubmittingReview = false;
                              });

                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmittingReview
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "Submitting...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              "Submit Review",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Future<void> _submitReview(String reviewText, int rating) async {
    if (reviewText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add a review"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false).user;

    setState(() {
      isSubmittingReview = true;
    });

    try {
      final result = await ReviewService.addReview(
        productId: getProductId(),
        reviewText: reviewText,
        customerRating: rating,
        customerName: user.username,
      );

      if (result['success'] == true) {
        fetchReviews();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Review submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message'] ?? "Failed to submit review");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmittingReview = false;
      });
    }
  }
}
