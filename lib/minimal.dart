import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MinimalHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MinimalHome extends StatefulWidget {
  const MinimalHome({super.key});

  @override
  State<MinimalHome> createState() => _MinimalHomeState();
}

class _MinimalHomeState extends State<MinimalHome> {
  // Data contoh
  List<Map<String, dynamic>> items = [
    {'id': 1, 'title': 'Belajar Flutter', 'completed': false},
    {'id': 2, 'title': 'Test Hapus', 'completed': false},
  ];

  // FUNGSI HAPUS
  void hapusItem(int id) {
    print("DEBUG: Hapus item dengan ID: $id");
    setState(() {
      items.removeWhere((item) => item['id'] == id);
    });
    print("DEBUG: Sisa item: ${items.length}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item berhasil dihapus!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Hapus - Klik Tong Sampah')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item['title']),
            leading: Checkbox(
              value: item['completed'],
              onChanged: (value) {
                setState(() {
                  item['completed'] = value ?? false;
                });
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                hapusItem(item['id']);
              },
            ),
          );
        },
      ),
    );
  }
}