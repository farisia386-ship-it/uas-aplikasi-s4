class Task {
  int? id;
  String title;
  String description;
  String category;
  DateTime deadline;
  bool isCompleted;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      deadline: DateTime.parse(map['deadline']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}