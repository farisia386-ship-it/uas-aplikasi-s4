import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi alarm service
  await Alarm.init();
  
  runApp(const TaskMateApp());
}

class TaskMateApp extends StatelessWidget {
  const TaskMateApp({super.key});

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
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Kuliah';
  DateTime _selectedDeadline = DateTime.now();
  bool _enableAlarm = true; // Enable/disable alarm
  final List<String> _categories = ['Kuliah', 'Pribadi', 'Kerja', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    
    // Listen to alarm ring stream
    Alarm.ringStream.stream.listen((_) {
      _showAlarmDialog();
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> decoded = jsonDecode(tasksString);
      setState(() {
        _tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(_tasks));
  }

  // Fungsi untuk menjadwalkan ALARM (bukan hanya notifikasi)
  Future<void> _scheduleAlarm(int id, String title, DateTime deadline) async {
    if (!_enableAlarm) return;
    
    // Cek apakah deadline masih di masa depan
    if (deadline.isBefore(DateTime.now())) return;
    
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: deadline,
      assetAudioPath: 'assets/audio/alarm_sound.mp3', // Ganti dengan file suara kamu
      loopAudio: true,        // Loop terus sampai dihentikan
      vibrate: true,          // Vibrasi terus sampai dihentikan
      // Alarm package version may not support 'volume' parameter
      // volume: 1.0,           // Volume maksimal
      fadeDuration: 3.0,     // Fade in selama 3 detik
      notificationTitle: '⏰ TaskMate Alarm',
      notificationBody: 'Waktunya mengerjakan: $title',
      enableNotificationOnKill: true,  // Tetap bunyi meski app ditutup
      androidFullScreenIntent: true,    // Muncul full screen di lock screen
    );
    
    await Alarm.set(alarmSettings: alarmSettings);
  }

  // Dialog yang muncul saat alarm berbunyi
  void _showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User harus klik tombol untuk menutup
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.alarm, color: Colors.red, size: 30),
              SizedBox(width: 8),
              Text('⏰ Waktunya Tugas!'),
            ],
          ),
          content: const Text(
            'Deadline tugas sudah tiba!\n\nSelesaikan tugas Anda sekarang.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Snooze 5 Menit'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Alarm.stopAll(); // Hentikan semua alarm yang berbunyi
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: const Text('OK, Saya Tahu'),
            ),
          ],
        );
      },
    );
  }

  void _addTask() async {
    if (_titleController.text.isEmpty) return;

    final newTask = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': _titleController.text,
      'description': _descController.text,
      'category': _selectedCategory,
      'deadline': _selectedDeadline.toIso8601String(),
      'isCompleted': false,
      'alarmEnabled': _enableAlarm,
    };

    setState(() {
      _tasks.add(newTask);
    });
    _saveTasks();
    
    // Jadwalkan ALARM (bukan hanya notifikasi)
    await _scheduleAlarm(
      newTask['id'] as int,
      newTask['title'] as String,
      _selectedDeadline,
    );
    
    _titleController.clear();
    _descController.clear();
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas "${newTask['title']}" ditambahkan${_enableAlarm ? ' dengan alarm' : ''}'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  void _deleteTask(int id) async {
    // Hentikan alarm jika ada
    await Alarm.stop(id);
    
    setState(() {
      _tasks.removeWhere((task) => task['id'] == id);
    });
    _saveTasks();
  }

  void _toggleComplete(int id) async {
    setState(() {
    final index = _tasks.indexWhere((task) => task['id'] == id);
      if (index != -1) {
        _tasks[index]['isCompleted'] = !(_tasks[index]['isCompleted'] as bool);

        
        // Jika tugas selesai, hentikan alarm
        if (_tasks[index]['isCompleted'] == true) {
          Alarm.stop(id);
        }
      }
    });
    _saveTasks();
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
    _titleController.clear();
    _descController.clear();
    _selectedCategory = 'Kuliah';
    _selectedDeadline = DateTime.now().add(const Duration(minutes: 2)); // Untuk testing
    _enableAlarm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                        setStateDialog(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        await _selectDeadline();
                        setStateDialog(() {});
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Waktu Alarm',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year} ${_selectedDeadline.hour.toString().padLeft(2, '0')}:${_selectedDeadline.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alarm, color: Colors.teal),
                          const SizedBox(width: 8),
                          const Text(
                            'Aktifkan Alarm Pengingat',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Switch(
                            value: _enableAlarm,
                            onChanged: (value) {
                              setStateDialog(() {
                                _enableAlarm = value;
                              });
                            },
                            activeColor: Colors.teal,
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
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan & Atur Alarm'),
                ),
              ],
            );
          },
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
        actions: [
          // Ikon indikator alarm aktif
          const Icon(Icons.alarm, size: 20),
          const SizedBox(width: 16),
        ],
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Belum ada tugas', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Tekan tombol + untuk menambah tugas dengan alarm',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks.reversed.toList()[index];
                final deadlineDate = DateTime.parse(task['deadline']);
                final hasAlarm = task['alarmEnabled'] == true;
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task['title'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        decoration: task['isCompleted']
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (hasAlarm && !task['isCompleted'])
                                    const Icon(Icons.alarm, color: Colors.teal, size: 16),
                                ],
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
                                    '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year} ${deadlineDate.hour.toString().padLeft(2, '0')}:${deadlineDate.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: deadlineDate.isBefore(DateTime.now()) && !task['isCompleted']
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