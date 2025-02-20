import 'package:flutter/material.dart';
import 'package:listviewbuilder/mock_data.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Product Lists'),
          leading: Icon(Icons.production_quantity_limits_outlined),
          backgroundColor: const Color.fromARGB(255, 113, 191, 228),
        ),
        body: ListView.builder(
          itemCount: mockProducts.length,
          itemBuilder: (context, index) {
            final product = mockProducts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductList(),
                    ));
              },
              child: (Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 198, 208, 213),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      product['imageUrl'],
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        product['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        product['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('\$${product['price'].toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              )),
            );
          },
        ));
  }
}