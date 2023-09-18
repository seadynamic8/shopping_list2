import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list2/data/categories.dart';
import 'package:shopping_list2/models/grocery_item.dart';
import 'package:shopping_list2/models/category.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.dairy];

  void _saveItem() async {
    late String newId;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        newId = await _saveToBackend();
      } catch (error) {
        _showError('Something went wrong!. Please try again later.');
        return;
      }

      if (newId.isEmpty) {
        _showError('Failed to save item! Please try again later.');
        return;
      }
      if (!context.mounted) return;
      // Return the newly created item to grocery list
      Navigator.of(context).pop(
        GroceryItem(
          id: newId,
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory!,
        ),
      );
    }
  }

  Future<String> _saveToBackend() async {
    final url = Uri.https('flutter-prep-20574-default-rtdb.firebaseio.com',
        'shopping-list-2.json');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _enteredName,
        'quantity': _enteredQuantity,
        'category': _selectedCategory!.title,
      }),
    );

    if (response.statusCode >= 400) {
      _showError('Failed to save item. Please try again later.');
      return '';
    }

    final resData = json.decode(response.body);

    return resData['name'];
  }

  void _showError(String errorMessage) {
    if (!context.mounted) return;

    final sMessenger = ScaffoldMessenger.of(context);
    sMessenger.clearSnackBars();
    sMessenger.showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                autofocus: true,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters';
                  }
                  return null;
                },
                onSaved: (newValue) => _enteredName = newValue!,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(label: Text('Amount')),
                      initialValue: '1',
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid, positive number.';
                        }
                        return null;
                      },
                      onSaved: (newValue) =>
                          _enteredQuantity = int.parse(newValue!),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(category.value.title)
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _formKey.currentState!.reset(),
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _saveItem,
                    child: const Text('Add Item'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
