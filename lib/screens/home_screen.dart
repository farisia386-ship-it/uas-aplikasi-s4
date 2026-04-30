import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _tasks = [];
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Kuliah';
  DateTime _selectedDeadline = DateTime.now();
  final List<String> _categories = ['Kuliah', 'Pribadi', 'Kerja', 'Lainnya'];

  void _addTask() {
    if (_titleController.text.isEmpty) return;

    setState(() {
      _tasks.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory,
        'deadline': _selectedDeadline,
        'isCompleted': false,
      });
    });

    _titleController.clear();
    _descController.clear();
    Navigator.pop(context);
  }

  void _deleteTask(int id) {
    setState(() {
      _tasks.removeWhere((task) => task['id'] == id);
    });
  }

  void _toggleComplete(int id) {
    setState(() {
      final index = _tasks.indexWhere((task) => task['id'] == id);
      if (index != -1) {
        _tasks[index]['isCompleted'] = !_tasks[index]['isCompleted'];
      }
    });
  }

  Future<void> _selectDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Tugas Baru'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDeadline,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Deadline',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year} ${_selectedDeadline.hour}:${_selectedDeadline.minute}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskMate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Belum ada tugas', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Tekan tombol + untuk menambah tugas',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: task['isCompleted'],
                          onChanged: (_) => _toggleComplete(task['id']),
                          activeColor: Colors.teal,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  decoration: task['isCompleted']
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (task['description'].isNotEmpty)
                                Text(task['description'],
                                    style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(task['category'],
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${task['deadline'].day}/${task['deadline'].month}/${task['deadline'].year} ${task['deadline'].hour}:${task['deadline'].minute}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: task['deadline'].isBefore(DateTime.now())
                                          ? Colors.red
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteTask(task['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}