import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Inisialisasi plugin notifikasi
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi timezone (WIB/Asia/Jakarta)
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  
  // Konfigurasi notifikasi untuk Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Request izin notifikasi (Android 13+)
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMate',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> tasks = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  String selectedCategory = 'Kuliah';
  DateTime selectedDeadline = DateTime.now();
  final List<String> categories = ['Kuliah', 'Pribadi', 'Kerja', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // ============ PENYIMPANAN DATA ============
  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> decoded = jsonDecode(tasksString);
      setState(() {
        tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(tasks));
  }

  // ============ NOTIFIKASI H-5 ============
  Future<void> scheduleDailyReminder(Map<String, dynamic> task) async {
    final DateTime deadline = DateTime.parse(task['deadline']);
    final DateTime now = DateTime.now();
    
    // Hitung H-5 (5 hari sebelum deadline)
    final DateTime startDate = deadline.subtract(const Duration(days: 5));
    
    // Jika deadline kurang dari 5 hari, mulai dari sekarang
    final DateTime actualStart = startDate.isBefore(now) ? now : startDate;
    
    // Batasi maksimal notifikasi sampai deadline
    if (actualStart.isAfter(deadline)) return;
    
    // Hitung berapa hari notifikasi akan berjalan
    int daysUntilDeadline = deadline.difference(actualStart).inDays + 1;
    if (daysUntilDeadline > 5) daysUntilDeadline = 5;
    
    // Jadwalkan notifikasi setiap hari pada jam 08:00
    for (int i = 0; i < daysUntilDeadline; i++) {
      final DateTime notificationDate = actualStart.add(Duration(days: i));
      
      // Jangan jadwalkan jika sudah lewat
      if (notificationDate.isBefore(now) && 
          notificationDate.day == now.day) continue;
      
      // Set waktu notifikasi jam 08:00 pagi
      final DateTime scheduledTime = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        8, 0, // Jam 08:00
      );
      
      // Hitung hari ke berapa (H-?)
      final int daysLeft = deadline.difference(notificationDate).inDays;
      String message;
      
      if (daysLeft == 0) {
        message = '⚠️ DEADLINE HARI INI! Selesaikan tugas "${task['title']}" sekarang!';
      } else if (daysLeft == 1) {
        message = '❗ Besok deadline! Tugas "${task['title']}" harus segera diselesaikan.';
      } else {
        message = '📢 Tugas "${task['title']}" akan berakhir dalam $daysLeft hari. Jangan lupa dikerjakan!';
      }
      
      // Kirim notifikasi
      await scheduleNotification(
        id: task['id'] + i,
        title: '⏰ Pengingat Tugas: ${task['title']}',
        body: message,
        scheduledDate: scheduledTime,
      );
    }
    
    print('DEBUG: Notifikasi H-5 dijadwalkan untuk tugas: ${task['title']}');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminder_channel',
      'Pengingat Tugas',
      channelDescription: 'Channel untuk pengingat deadline tugas',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );
    
    if (tzScheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTaskNotifications(int taskId) async {
    for (int i = 0; i < 6; i++) {
      await flutterLocalNotificationsPlugin.cancel(taskId + i);
    }
  }

  // ============ CRUD TUGAS ============
  
  // TAMBAH TUGAS
  void addTask() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong!')),
      );
      return;
    }

    final newTask = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': titleController.text,
      'description': descController.text,
      'category': selectedCategory,
      'deadline': selectedDeadline.toIso8601String(),
      'isCompleted': false,
    };

    setState(() {
      tasks.add(newTask);
    });
    saveTasks();
    
    // Jadwalkan notifikasi H-5 untuk tugas baru
    await scheduleDailyReminder(newTask);
    
    titleController.clear();
    descController.clear();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Tugas ditambahkan + Notifikasi H-5 aktif!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  // HAPUS TUGAS
  void deleteTask(int id) async {
    await cancelTaskNotifications(id);
    
    setState(() {
      tasks.removeWhere((task) => task['id'] == id);
    });
    saveTasks();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Tugas dan notifikasi dihapus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // TANDAI SELESAI
  void toggleComplete(int id) {
    setState(() {
      final index = tasks.indexWhere((task) => task['id'] == id);
      if (index != -1) {
        tasks[index]['isCompleted'] = !tasks[index]['isCompleted'];
      }
    });
    saveTasks();
  }

  // EDIT TUGAS
  void editTask(Map<String, dynamic> task) async {
    titleController.text = task['title'];
    descController.text = task['description'] ?? '';
    selectedCategory = task['category'];
    selectedDeadline = DateTime.parse(task['deadline']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Tugas'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDeadline),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDeadline = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Waktu Deadline',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year} ${selectedDeadline.hour}:${selectedDeadline.minute}',
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
              onPressed: () async {
                await cancelTaskNotifications(task['id']);
                
                task['title'] = titleController.text;
                task['description'] = descController.text;
                task['category'] = selectedCategory;
                task['deadline'] = selectedDeadline.toIso8601String();
                
                setState(() {});
                saveTasks();
                await scheduleDailyReminder(task);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tugas diupdate! Notifikasi disesuaikan')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // DIALOG TAMBAH TUGAS
  void showAddDialog() {
    titleController.clear();
    descController.clear();
    selectedCategory = 'Kuliah';
    selectedDeadline = DateTime.now().add(const Duration(days: 7));

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
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDeadline),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDeadline = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Deadline',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year} ${selectedDeadline.hour}:${selectedDeadline.minute}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🔔 Notifikasi akan dikirim setiap hari jam 08:00 pagi mulai H-5 hingga deadline!',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
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
              onPressed: addTask,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Simpan & Aktifkan Notifikasi'),
            ),
          ],
        );
      },
    );
  }

  // ============ UI ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMate - With Reminder H-5'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Belum ada tugas', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Tambah tugas untuk mengaktifkan reminder H-5',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final deadlineDate = DateTime.parse(task['deadline']);
                final daysLeft = deadlineDate.difference(DateTime.now()).inDays;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: task['isCompleted'] ?? false,
                          onChanged: (_) => toggleComplete(task['id']),
                          activeColor: Colors.teal,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => editTask(task),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['title'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: task['isCompleted'] == true
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (task['description'].toString().isNotEmpty)
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
                                      '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    if (daysLeft <= 5 && daysLeft >= 0 && task['isCompleted'] != true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'H-$daysLeft',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (task['isCompleted'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'SELESAI',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => deleteTask(task['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}