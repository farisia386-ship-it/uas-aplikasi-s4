import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/taks.dart';
import 'edit_task_screen.dart';

class DetailScreen extends StatelessWidget {
  final Task task;

  const DetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTaskScreen(task: task),
                ),
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Judul Tugas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description.isEmpty ? '-' : task.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(task.category),
                      backgroundColor: Colors.teal.shade100,
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Deadline',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: task.deadline.isBefore(DateTime.now()) && !task.isCompleted
                              ? Colors.red
                              : Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id').format(task.deadline),
                          style: TextStyle(
                            fontSize: 16,
                            color: task.deadline.isBefore(DateTime.now()) && !task.isCompleted
                                ? Colors.red
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(task.isCompleted ? 'Selesai' : 'Belum Selesai'),
                      backgroundColor: task.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                      avatar: Icon(
                        task.isCompleted ? Icons.check_circle : Icons.pending,
                        size: 18,
                        color: task.isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}