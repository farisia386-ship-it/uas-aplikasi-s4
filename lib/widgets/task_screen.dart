import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/taks.dart';
import '../database/database_helper.dart';
import '../screens/detail_screen.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const TaskCard({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onRefresh,
  });

  Future<void> _toggleComplete() async {
    task.isCompleted = !task.isCompleted;
    await DatabaseHelper().updateTask(task);
    onRefresh();
  }

  String _getCategoryColor(String category) {
    switch (category) {
      case 'Kuliah':
        return '#FF6B6B';
      case 'Pribadi':
        return '#4ECDC4';
      case 'Kerja':
        return '#45B7D1';
      default:
        return '#96CEB4';
    }
  }

  @override
Widget build(BuildContext context) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(task: task)),
        );
        onRefresh();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) => _toggleComplete(),
              activeColor: Colors.teal,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(int.parse(_getCategoryColor(task.category).substring(1, 7), radix: 16) + 0xFF000000).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(int.parse(_getCategoryColor(task.category).substring(1, 7), radix: 16) + 0xFF000000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(task.deadline),
                        style: TextStyle(
                          fontSize: 12,
                          color: task.deadline.isBefore(DateTime.now()) && !task.isCompleted
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
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    ),
  );
}

}