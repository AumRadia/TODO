import 'package:flutter/material.dart';
import 'package:flutter_internals/keys/checkable_todo_item.dart';

class Todo {
  const Todo(this.text, this.priority);

  final String text;
  final Priority priority;
}

class Keys extends StatefulWidget {
  const Keys({super.key});

  @override
  State<Keys> createState() => _KeysState();
}

class _KeysState extends State<Keys> {
  var _order = 'asc';
  final _todos = <Todo>[];
  final _controller = TextEditingController();
  var _selectedPriority = Priority.normal;

  List<Todo> get _orderedTodos {
    final sortedTodos = List.of(_todos);
    sortedTodos.sort((a, b) {
      final bComesAfterA = a.text.compareTo(b.text);
      return _order == 'asc' ? bComesAfterA : -bComesAfterA;
    });
    return sortedTodos;
  }

  void _changeOrder() {
    setState(() {
      _order = _order == 'asc' ? 'desc' : 'asc';
    });
  }

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _todos.add(Todo(text, _selectedPriority));
      _controller.clear(); // Clear input after adding
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sort button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _changeOrder,
            icon: Icon(
              _order == 'asc' ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            label: Text('Sort ${_order == 'asc' ? 'Descending' : 'Ascending'}'),
          ),
        ),

        // Input row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'New Task'),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<Priority>(
                value: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
                items: Priority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name.toUpperCase()),
                  );
                }).toList(),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addTodo,
                child: const Text('Add'),
              ),
            ],
          ),
        ),

        // List of todos
        Expanded(
          child: ListView(
            children: [
              for (final todo in _orderedTodos)
                CheckableTodoItem(
                  key: ObjectKey(todo),
                  todo.text,
                  todo.priority,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
