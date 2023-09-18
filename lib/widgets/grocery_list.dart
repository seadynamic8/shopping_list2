import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list2/data/dummy_data.dart';
import 'package:shopping_list2/data/categories.dart';
import 'package:shopping_list2/widgets/new_item.dart';
import 'package:shopping_list2/models/grocery_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _error = '';
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('flutter-prep-20574-default-rtdb.firebaseio.com',
        'shopping-list-2.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to load items. Please try again later';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = listData.entries.map((item) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;

        return GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        );
      }).toList();

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Failed to load items. Please try again later';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => const NewItem()),
    );

    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) {
    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          background: Container(
            color: Colors.red[300],
          ),
          onDismissed: (direction) => _removeItem(_groceryItems[index]),
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            title: Text(_groceryItems[index].name),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      content = Center(child: Text(_error));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
