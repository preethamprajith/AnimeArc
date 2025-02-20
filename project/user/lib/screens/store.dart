import 'package:flutter/material.dart';

class Store extends StatefulWidget {
  const Store({super.key});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  // List of anime merchandise items
  final List<Map<String, String>> merchandise = [
    {"title": "Naruto Hoodie", "price": "\$39.99"},
    {"title": "Attack on Titan Cap", "price": "\$19.99"},
    {"title": "One Piece T-Shirt", "price": "\$24.99"},
    {"title": "Demon Slayer Keychain", "price": "\$9.99"},
    {"title": "Jujutsu Kaisen Mug", "price": "\$14.99"},
    {"title": "Bleach Wristband", "price": "\$7.99"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Anime Store", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: merchandise.length,
          itemBuilder: (context, index) {
            return _buildMerchCard(merchandise[index]);
          },
        ),
      ),
    );
  }

  Widget _buildMerchCard(Map<String, String> item) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          item["title"]!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          item["price"]!,
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Buy Now", style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
