import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TodoApp());
}

enum Priority { high, medium, low }

class Todo {
  final String text;
  final Priority priority;
  final bool isDone;

  Todo({
    required this.text,
    required this.priority,
    this.isDone = false,
  });

  Todo copyWith({String? text, Priority? priority, bool? isDone}) {
    return Todo(
      text: text ?? this.text,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'priority': priority.name,
      'isDone': isDone,
    };
  }

  static Todo fromMap(Map<String, dynamic> map) {
    return Todo(
      text: map['text'],
      priority: Priority.values.firstWhere((e) => e.name == map['priority']),
      isDone: map['isDone'],
    );
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const TodoHome(),
    );
  }
}

class TodoHome extends StatefulWidget {
  const TodoHome({super.key});

  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  final List<Todo> _todos = [];
  final _controller = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('todos');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      setState(() {
        _todos.addAll(decoded.map((e) => Todo.fromMap(e)));
        _sortTodos();
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_todos.map((e) => e.toMap()).toList());
    await prefs.setString('todos', encoded);
  }

  void _addTodo() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Task'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Priority>(
              value: _selectedPriority,
              items: Priority.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (val) => _selectedPriority = val!,
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                final todo = Todo(text: text, priority: _selectedPriority);
                setState(() {
                  _todos.add(todo);
                  _sortTodos();
                });
                _saveTodos();
                _controller.clear();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDone(int index) {
    setState(() {
      _todos[index] = _todos[index].copyWith(isDone: !_todos[index].isDone);
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  void _deleteCompletedTasks() {
    setState(() {
      _todos.removeWhere((todo) => todo.isDone);
    });
    _saveTodos();
  }

  void _sortTodos() {
    setState(() {
      _todos.sort((a, b) {
        if (_isAscending) {
          return a.priority.index.compareTo(b.priority.index);
        } else {
          return b.priority.index.compareTo(a.priority.index);
        }
      });
    });
  }

  IconData _getIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Icons.priority_high;
      case Priority.medium:
        return Icons.trending_up;
      case Priority.low:
        return Icons.low_priority;
    }
  }

  Color _getPriorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return Colors.redAccent;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  bool get _hasCompletedTasks => _todos.any((todo) => todo.isDone);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
                _sortTodos();
              });
            },
            icon: Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            tooltip: _isAscending
                ? 'Sort: Low to High Priority'
                : 'Sort: High to Low Priority',
          ),
          if (_hasCompletedTasks)
            IconButton(
              onPressed: _deleteCompletedTasks,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Delete checked tasks',
            ),
          IconButton(
            onPressed: _addTodo,
            icon: const Icon(Icons.add_task),
            tooltip: 'Add Task',
          ),
        ],
      ),
      body: _todos.isEmpty
          ? const Center(child: Text("No tasks yet. Add some!"))
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (ctx, index) {
                final todo = _todos[index];
                return Dismissible(
                  key: Key(todo.text + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteTodo(index),
                  child: ListTile(
                    leading: Icon(
                      _getIcon(todo.priority),
                      color: _getPriorityColor(todo.priority),
                    ),
                    title: Text(
                      todo.text,
                      style: TextStyle(
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: todo.isDone ? Colors.grey : Colors.white,
                      ),
                    ),
                    trailing: Checkbox(
                      value: todo.isDone,
                      onChanged: (_) => _toggleDone(index),
                    ),
                    tileColor: Colors.black12,
                  ),
                );
              },
            ),
    );
  }
}
