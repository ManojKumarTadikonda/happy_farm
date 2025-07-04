import 'dart:async';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';

class UniversalProductCard extends StatefulWidget {
  final BaseProduct product;
  final double imageHeight;

  const UniversalProductCard({
    super.key,
    required this.product,
    this.imageHeight = 140, // Optimized for better ratio
  });

  @override
  State<UniversalProductCard> createState() => _UniversalProductCardState();
}

class _UniversalProductCardState extends State<UniversalProductCard> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.product.images.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < widget.product.images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
    if (widget.product.prices.isEmpty) return const SizedBox();

    final price = widget.product.prices[0];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          Expanded(
            flex: 2, // Takes 3/4 of available space
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    child: widget.product.images.isEmpty
                        ? const Center(child: Icon(Icons.image_not_supported))
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: widget.product.images.length,
                            itemBuilder: (context, index) => Image.network(
                              widget.product.images[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                if (price.discount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${price.discount.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            flex: 1, // Takes 2/4 of available space
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  // Price and Stock Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹${price.actualPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (price.oldPrice > price.actualPrice)
                            Text(
                              '₹${price.oldPrice.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      Text(
                        price.countInStock > 0 ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: price.countInStock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized GridView Widget
class OptimizedProductGrid extends StatelessWidget {
  final List<BaseProduct> visibleProducts;
  final Widget Function(BaseProduct) onProductTap;

  const OptimizedProductGrid({
    super.key,
    required this.visibleProducts,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75, // Fixed optimal ratio
      ),
      itemCount: visibleProducts.length,
      itemBuilder: (context, index) {
        final product = visibleProducts[index];
        return GestureDetector(
          onTap: () => onProductTap(product),
          child: UniversalProductCard(product: product),
        );
      },
    );
  }
}

// Usage Example (replace your existing GridView.builder with this):
/*
OptimizedProductGrid(
  visibleProducts: visibleProducts,
  onProductTap: (product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetails(product: product),
      ),
    );
  },
)
*/

// Alternative: If you want to keep using GridView.builder directly, use this configuration:
/*
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 0.75, // Fixed optimal ratio
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
)
*/