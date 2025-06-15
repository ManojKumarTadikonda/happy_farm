import 'package:flutter/material.dart';
import 'package:happy_farm/main.dart';
import 'package:happy_farm/models/product_model.dart';
import 'package:happy_farm/screens/productdetails_screen.dart';
import 'package:happy_farm/widgets/product_card.dart';

class FilteredProductsScreen extends StatefulWidget {
  final List<FilterProducts> products;

  const FilteredProductsScreen({super.key, required this.products});

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
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filtered Products",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
