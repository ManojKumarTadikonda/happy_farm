import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/main_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/product_card.dart';
import 'package:happy_farm/utils/app_theme.dart';

class FilteredProductsScreen extends StatefulWidget {
  final List<FilterProducts> products;
  final String categoryName;
  final int? minPrice;
  final int? maxPrice;
  final int? rating;

  const FilteredProductsScreen({
    super.key,
    required this.products,
    required this.categoryName,
    this.minPrice,
    this.maxPrice,
    this.rating,
  });

  @override
  State<FilteredProductsScreen> createState() => _FilteredProductsScreenState();
}

class _FilteredProductsScreenState extends State<FilteredProductsScreen> {
  int _visibleFilteredCount = 5;
  @override
  Widget build(BuildContext context) {
    final visibleFilteredProducts =
        widget.products.take(_visibleFilteredCount).toList();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Applied Filters + X icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Applied Filters",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Applied Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(widget.categoryName),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: const TextStyle(color: Colors.blue),
                ),
                if (widget.minPrice != null && widget.maxPrice != null)
                  Chip(
                    label: Text("₹${widget.minPrice} - ₹${widget.maxPrice}"),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: const TextStyle(color:  AppTheme.primaryColor),
                  ),
                if (widget.rating != null && widget.rating! > 0)
                  Chip(
                    label: Text("${widget.rating}★ & above"),
                    backgroundColor: Colors.orange.shade50,
                    labelStyle: const TextStyle(color: Colors.orange),
                  ),
              ],
            ),
          ),

          // Filtered Products Heading
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Filtered Products",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Product Grid
          Expanded(
            child: widget.products.isEmpty
                ? const Center(
                    child: Text(
                      "No products found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GridView.builder(
                            itemCount: visibleFilteredProducts.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.65,
                            ),
                            itemBuilder: (context, index) {
                              final product = visibleFilteredProducts[index];
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
                          ),
                        ),
                      ),

                      // View All Button
                      if (_visibleFilteredCount < widget.products.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _visibleFilteredCount += 5;
                                if (_visibleFilteredCount >
                                    widget.products.length) {
                                  _visibleFilteredCount =
                                      widget.products.length;
                                }
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  const Color.fromARGB(255, 1, 140, 255),
                            ),
                            child: const Text('View All'),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
