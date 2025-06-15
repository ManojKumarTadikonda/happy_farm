import 'dart:async';
import 'package:flutter/material.dart';
import 'package:happy_farm/models/product_model.dart';

class UniversalProductCard extends StatefulWidget {
  final BaseProduct product;
  final double imageHeight;

  const UniversalProductCard({
    super.key,
    required this.product,
    this.imageHeight = 180, // default image height
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),side: BorderSide(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: widget.imageHeight,
                  width: double.infinity,
                  child: widget.product.images.isEmpty
                      ? const Center(child: Icon(Icons.image_not_supported))
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: widget.product.images.length,
                          itemBuilder: (context, index) => Image.network(
                            widget.product.images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              if (price.discount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          Padding(
            padding: const EdgeInsets.only(left: 10,right: 10, top: 10,),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '₹${price.actualPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '₹${price.oldPrice.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price.countInStock > 0 ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            price.countInStock > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
